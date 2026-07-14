import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/app_user_model.dart';
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

  Future<void> _showAddUserDialog(BuildContext context, List<String> existingUsernames) async {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حساب جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'اليوزر'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'اكتب اليوزر';
                    if (value == 'admin') return 'الاسم ده محجوز للحساب الرئيسي';
                    if (existingUsernames.contains(value)) return 'اليوزر ده موجود بالفعل';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'الباسورد'),
                  validator: (v) => (v == null || v.length < 4) ? 'الباسورد لازم يكون 4 حروف/أرقام على الأقل' : null,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'هيتضاف بكل الصلاحيات مفعّلة، وتقدر تقيّدها بعد كده من زرار التعديل',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await ref.read(userAccountServiceProvider).addUser(
                              usernameController.text.trim(),
                              passwordController.text,
                            );
                        ref.invalidate(appUsersProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                        }
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, AppUserModel user) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;
    final permissions = <String, bool>{
      for (final s in AppUserModel.permissionScreens) s.key: user.canAccess(s.key),
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('تعديل حساب "${user.username}"'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الشاشات المسموح بيها', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...AppUserModel.permissionScreens.map((s) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(s.value),
                          value: permissions[s.key],
                          activeColor: AppColors.wood,
                          onChanged: (v) => setDialogState(() => permissions[s.key] = v ?? true),
                        )),
                    const Divider(height: 24),
                    const Text('تغيير كلمة المرور (اختياري - سيبها فاضية لو مش عايز تغيّرها)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'كلمة مرور جديدة'),
                      validator: (v) =>
                          (v != null && v.isNotEmpty && v.length < 4) ? 'لازم 4 حروف/أرقام على الأقل' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmController,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                      validator: (v) => (passwordController.text.isNotEmpty && v != passwordController.text)
                          ? 'مش متطابقة'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);
                      final service = ref.read(userAccountServiceProvider);
                      try {
                        await service.updateUserPermissions(user.id, permissions);
                        if (passwordController.text.isNotEmpty) {
                          await service.updateUserPassword(user.id, passwordController.text);
                        }
                        ref.invalidate(appUsersProvider);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                        }
                        setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final usersAsync = ref.watch(appUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionCard(
            title: 'الحساب الحالي',
            icon: Icons.verified_user_rounded,
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: AppColors.wood),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مسجّل دخول كـ: ${session?.username ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        session?.isAdmin == true ? 'حساب أدمن - كل الصلاحيات متاحة' : 'حساب عامل - صلاحيات محدّدة',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (session?.isAdmin == true) ...[
            const SizedBox(height: 20),
            _SectionCard(
              title: 'حسابات العمال والصلاحيات',
              icon: Icons.groups_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: usersAsync.when(
                      data: (users) => TextButton.icon(
                        onPressed: () => _showAddUserDialog(context, users.map((u) => u.username).toList()),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('إضافة حساب'),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  usersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text('لا توجد حسابات إضافية بعد', style: TextStyle(color: Colors.grey))),
                        );
                      }
                      return Column(
                        children: users.map((u) {
                          final allowedScreens = AppUserModel.permissionScreens
                              .where((s) => u.canAccess(s.key))
                              .map((s) => s.value)
                              .toList();
                          final subtitle = allowedScreens.length == AppUserModel.permissionScreens.length
                              ? 'كل الصلاحيات متاحة'
                              : allowedScreens.isEmpty
                                  ? 'من غير أي صلاحية شاشات'
                                  : 'مسموح: ${allowedScreens.join('، ')}';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.wood.withValues(alpha: 0.15),
                                child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(u.username, textDirection: TextDirection.ltr),
                              subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    tooltip: 'تعديل الصلاحيات/الباسورد',
                                    onPressed: () => _showEditUserDialog(context, u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                    tooltip: 'حذف الحساب',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('حذف الحساب'),
                                          content: Text('هل أنت متأكد من حذف حساب "${u.username}"؟'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(userAccountServiceProvider).deleteUser(u.id);
                                        ref.invalidate(appUsersProvider);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ: $e'),
                  ),
                ],
              ),
            ),
          ],
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
                  onPressed: _isSyncing
                      ? null
                      : () async {
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
