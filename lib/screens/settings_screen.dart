import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../providers/sync_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await ref.read(syncServiceProvider).syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  Future<void> _showSetPasswordDialog(BuildContext context, {required bool isChangingExisting, required String currentPassword}) async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isChangingExisting ? 'تغيير كلمة المرور' : 'تفعيل الحماية بكلمة مرور'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isChangingExisting) ...[
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                    validator: (v) => (v == null || v.length < 4) ? 'لازم تكون 4 حروف/أرقام على الأقل' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                    validator: (v) => (v != newController.text) ? 'مش متطابقة' : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (isChangingExisting && currentController.text != currentPassword) {
                  setDialogState(() => error = 'كلمة المرور الحالية غلط');
                  return;
                }
                await ref.read(authRepositoryProvider).setPassword(newController.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDisableProtection(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الحماية'),
        content: const Text('هل أنت متأكد من إلغاء طلب كلمة المرور عند فتح التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تعطيل الحماية'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authRepositoryProvider).disableProtection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionCard(
            title: 'الحماية بكلمة مرور',
            icon: Icons.lock_outline_rounded,
            child: authAsync.when(
              data: (settings) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.enabled,
                    activeColor: AppColors.wood,
                    title: const Text('طلب كلمة مرور عند فتح التطبيق'),
                    subtitle: const Text('لو مفعّلة، هتحتاج تدخل كلمة المرور كل مرة تفتح فيها التطبيق'),
                    onChanged: (v) async {
                      if (v) {
                        await _showSetPasswordDialog(context, isChangingExisting: false, currentPassword: settings.password);
                      } else {
                        await _confirmDisableProtection(context);
                      }
                    },
                  ),
                  if (settings.enabled) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showSetPasswordDialog(context, isChangingExisting: true, currentPassword: settings.password),
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('تغيير كلمة المرور'),
                    ),
                  ],
                ],
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
              error: (e, _) => Text('خطأ: $e'),
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'المزامنة مع السيرفر',
            icon: Icons.sync_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: ref.read(databaseProvider).getMeta('lastSyncAt'),
                  builder: (context, snapshot) {
                    final raw = snapshot.data;
                    final text = raw == null
                        ? 'لسه ما حصلتش مزامنة'
                        : 'آخر مزامنة: ${DateFormat('d/M/yyyy - hh:mm a', 'ar_EG').format(DateTime.fromMillisecondsSinceEpoch(int.parse(raw)))}';
                    return Text(text, style: const TextStyle(color: Colors.grey));
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSyncing ? null : () async {
                    await _syncNow();
                    setState(() {});
                  },
                  icon: _isSyncing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded),
                  label: Text(_isSyncing ? 'جاري المزامنة...' : 'مزامنة الآن'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionCard(
            title: 'عن التطبيق',
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ورشة التنجيد والأثاث - نسخة سطح المكتب', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('الإصدار 1.0.0', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.wood),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
