import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
    final permissions = <String, bool>{
      for (final s in AppUserModel.permissionScreens) s.key: true,
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('إضافة حساب جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      textDirection: TextDirection.ltr,
                      decoration: _fieldDecoration('اليوزر', Icons.person_outline_rounded),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'اكتب اليوزر';
                        if (value == 'admin') return 'الاسم ده محجوز للحساب الرئيسي';
                        if (existingUsernames.contains(value)) return 'اليوزر ده موجود بالفعل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      textDirection: TextDirection.ltr,
                      decoration: _fieldDecoration('الباسورد', Icons.lock_outline_rounded),
                      validator: (v) => (v == null || v.length < 4) ? 'الباسورد لازم يكون 4 حروف/أرقام على الأقل' : null,
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('الشاشات المسموح بيها'),
                    const SizedBox(height: 6),
                    ...AppUserModel.permissionScreens.map((s) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(s.value, style: GoogleFonts.cairo(fontSize: 13.5)),
                          value: permissions[s.key],
                          activeColor: AppColors.wood,
                          onChanged: (v) => setDialogState(() => permissions[s.key] = v ?? true),
                        )),
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
                      try {
                        await ref.read(userAccountServiceProvider).addUser(
                              usernameController.text.trim(),
                              passwordController.text,
                              permissions: permissions,
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
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, AppUserModel user) async {
    bool isSaving = false;
    final permissions = <String, bool>{
      for (final s in AppUserModel.permissionScreens) s.key: user.canAccess(s.key),
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تعديل حساب "${user.username}"', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('الشاشات المسموح بيها'),
                  const SizedBox(height: 6),
                  ...AppUserModel.permissionScreens.map((s) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(s.value, style: GoogleFonts.cairo(fontSize: 13.5)),
                        value: permissions[s.key],
                        activeColor: AppColors.wood,
                        onChanged: (v) => setDialogState(() => permissions[s.key] = v ?? true),
                      )),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.wood, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'مش ممكن نغيّر باسورد حساب عامل مباشرة (قيد أماني حقيقي في '
                            'Firebase نفسه). لو عايز تغيّره، احذف الحساب وضيفه تاني '
                            'بباسورد جديد.',
                            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final service = ref.read(userAccountServiceProvider);
                      try {
                        await service.updateUserPermissions(user.id, permissions);
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
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

    return Container(
      color: const Color(0xFFFAF6F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.settings_rounded, color: AppColors.wood, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الإعدادات', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                    const SizedBox(height: 4),
                    Text('الحساب، حسابات العمال، المزامنة', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'الحساب الحالي',
              icon: Icons.verified_user_rounded,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.wood.withValues(alpha: 0.14),
                    child: const Icon(Icons.person_rounded, color: AppColors.wood),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مسجّل دخول كـ: ${session?.username ?? '-'}',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          session?.isAdmin == true ? 'حساب أدمن - كل الصلاحيات متاحة' : 'حساب عامل - صلاحيات محدّدة',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (session?.isAdmin == true ? AppColors.wood : AppColors.navy).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session?.isAdmin == true ? 'أدمن' : 'عامل',
                      style: GoogleFonts.cairo(
                          fontSize: 11.5, fontWeight: FontWeight.w800, color: session?.isAdmin == true ? AppColors.wood : AppColors.navy),
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
                trailing: usersAsync.when(
                  data: (users) => _SmallActionButton(
                    label: 'إضافة حساب',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: () => _showAddUserDialog(context, users.map((u) => u.username).toList()),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                child: usersAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return const _EmptyState(icon: Icons.groups_outlined, text: 'لا توجد حسابات إضافية بعد');
                    }
                    return Column(
                      children: users.map((u) {
                        final allowedScreens = AppUserModel.permissionScreens.where((s) => u.canAccess(s.key)).map((s) => s.value).toList();
                        final subtitle = allowedScreens.length == AppUserModel.permissionScreens.length
                            ? 'كل الصلاحيات متاحة'
                            : allowedScreens.isEmpty
                                ? 'من غير أي صلاحية شاشات'
                                : 'مسموح: ${allowedScreens.join('، ')}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _HoverCard(
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.wood.withValues(alpha: 0.15),
                                    child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                        style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.username,
                                            textDirection: TextDirection.ltr,
                                            style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppColors.navy, size: 20),
                                    tooltip: 'تعديل الصلاحيات/الباسورد',
                                    onPressed: () => _showEditUserDialog(context, u),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                    tooltip: 'حذف الحساب',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
                  error: (e, _) => Text('خطأ: $e'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _SectionCard(
              title: 'المزامنة مع السيرفر',
              icon: Icons.sync_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<String?>(
                      future: ref.read(databaseProvider).getMeta('lastSyncAt'),
                      builder: (context, snapshot) {
                        final raw = snapshot.data;
                        final text = raw == null
                            ? 'لسه ما حصلتش مزامنة'
                            : 'آخر مزامنة: ${DateFormat('d/M/yyyy - hh:mm a', 'ar_EG').format(DateTime.fromMillisecondsSinceEpoch(int.parse(raw)))}';
                        return Text(text, style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12.5));
                      },
                    ),
                  ),
                  _SmallActionButton(
                    label: _isSyncing ? 'جاري المزامنة...' : 'مزامنة الآن',
                    icon: Icons.sync_rounded,
                    loading: _isSyncing,
                    onTap: _isSyncing
                        ? null
                        : () async {
                            await _syncNow();
                            setState(() {});
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'عن التطبيق',
              icon: Icons.info_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tahoun Royal Home - نسخة سطح المكتب', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 4),
                  Text('الإصدار 1.0.0', style: GoogleFonts.cairo(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label, [IconData? icon]) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.wood) : null,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.wood, width: 1.5)),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(text, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  const _SmallActionButton({required this.label, required this.icon, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wood))
                : Icon(icon, size: 17, color: AppColors.wood),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.wood)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(text, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppColors.wood, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// كارت بأثر hover ناعم (رفعة خفيفة + ظل أكبر) - نفس فكرة اللي في
/// dashboard_screen.dart بالظبط، بس متكرر هنا لأن الويدجتس الخاصة
/// (بادئة _) ملهاش مشاركة بين الملفات في دارت
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const _HoverCard({required this.child, this.onTap, this.borderRadius = const BorderRadius.all(Radius.circular(20))});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.wood.withValues(alpha: _hovering ? 0.14 : 0.06),
              blurRadius: _hovering ? 26 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: widget.onTap, borderRadius: widget.borderRadius, child: widget.child),
        ),
      ),
    );
  }
}
