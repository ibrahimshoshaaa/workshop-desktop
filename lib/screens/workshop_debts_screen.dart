import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/order_calculations.dart';
import '../core/constants.dart';

/// شاشة "مديونيات الورشة" - الديون المستحقة على الورشة لصالح الموردين
/// أو الصنايعية (عكس شاشة "المديونيات" اللي بتعرض فلوس لينا عند العملاء)
class WorkshopDebtsScreen extends ConsumerStatefulWidget {
  const WorkshopDebtsScreen({super.key});
  @override
  ConsumerState<WorkshopDebtsScreen> createState() => _WorkshopDebtsScreenState();
}

class _WorkshopDebtsScreenState extends ConsumerState<WorkshopDebtsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDebtDialog(BuildContext context, WidgetRef ref, {WorkshopDebt? debt}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: debt?.creditorName ?? '');
    final amountController = TextEditingController(text: debt != null ? debt.totalAmount.toStringAsFixed(0) : '');
    final notesController = TextEditingController(text: debt?.notes ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(debt == null ? 'تسجيل مديونية جديدة' : 'تعديل المديونية', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: _fieldDecoration('اسم المورد / الصنايعي', Icons.storefront_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب الاسم' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('إجمالي المديونية (ج.م)', Icons.request_quote_outlined),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(controller: notesController, maxLines: 2, decoration: _fieldDecoration('ملاحظات (اختياري)', Icons.notes_rounded)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (debt != null)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('حذف المديونية'),
                    content: const Text('هل أنت متأكد من حذف هذه المديونية؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(repositoryProvider).deleteWorkshopDebt(debt.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(repositoryProvider);
              if (debt == null) {
                await repo.addWorkshopDebt(
                  creditorName: nameController.text.trim(),
                  totalAmount: double.parse(amountController.text.trim()),
                  notes: notesController.text.trim(),
                );
              } else {
                await repo.updateWorkshopDebt(
                  debt,
                  creditorName: nameController.text.trim(),
                  totalAmount: double.parse(amountController.text.trim()),
                  notes: notesController.text.trim(),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayDialog(BuildContext context, WidgetRef ref, WorkshopDebt debt) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: debt.remaining.toStringAsFixed(0));
    String paymentMethod = 'cash';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('سداد دفعة - ${debt.creditorName}', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15)),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('المتبقي حاليًا: ${debt.remaining.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12.5)),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('المبلغ المسدد (ج.م)', Icons.payments_outlined),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'أدخل مبلغ صحيح';
                      if (val > debt.remaining) return 'المبلغ أكبر من المتبقي';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: _fieldDecoration('اتخصم من (مصدر الدفع)', Icons.account_balance_wallet_outlined),
                    items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (v) => setDialogState(() => paymentMethod = v ?? paymentMethod),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref.read(repositoryProvider).payWorkshopDebt(
                      debt: debt,
                      amount: double.parse(amountController.text.trim()),
                      paymentMethod: paymentMethod,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('تأكيد السداد'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(workshopDebtsProvider).value ?? [];
    final q = normalizeForSearch(_query);
    final filteredDebts = q.isEmpty ? debts : debts.where((d) => normalizeForSearch(d.creditorName).contains(q)).toList();
    // إجمالي المديونيات المستحقة على الورشة دايمًا بيتحسب من كل السجلات،
    // مش من نتيجة البحث، عشان الرقم يفضل يعكس الموقف الحقيقي
    final totalOutstanding = debts.fold<double>(0, (s, d) => s + d.remaining);

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: _PageHeader(
              title: 'مديونيات الورشة',
              subtitle: 'ديون مستحقة علينا للموردين والصنايعية',
              icon: Icons.storefront_rounded,
              badge: '${debts.length} مديونية',
              actionLabel: 'تسجيل مديونية',
              actionIcon: Icons.add_rounded,
              onAction: () => _showDebtDialog(context, ref),
            ),
          ),
          const SizedBox(height: 22),
          if (debts.isEmpty)
            const Expanded(child: _EmptyState(icon: Icons.celebration_rounded, text: 'لا توجد مديونيات على الورشة حاليًا 🎉'))
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _HeroStatCard(
                label: 'إجمالي مديونيات الورشة المستحقة',
                value: '${totalOutstanding.toStringAsFixed(0)} ج.م',
                caption: '${debts.where((d) => d.remaining > 0).length} مديونية لسه مستحقة',
                icon: Icons.storefront_rounded,
                color: AppColors.danger,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
              child: _HoverCard(
                borderRadius: BorderRadius.circular(16),
                child: AppSearchBar(
                  controller: _searchController,
                  hintText: 'ابحث باسم المورد أو الصنايعي...',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () => setState(() => _query = ''),
                ),
              ),
            ),
            Expanded(
              child: filteredDebts.isEmpty
                  ? const _EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج مطابقة')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                      itemCount: filteredDebts.length,
                      itemBuilder: (context, index) {
                        final d = filteredDebts[index];
                        final remaining = d.remaining;
                        final isSettled = remaining <= 0;
                        final color = isSettled ? AppColors.success : AppColors.danger;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _HoverCard(
                            onTap: () => _showDebtDialog(context, ref, debt: d),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: Icon(isSettled ? Icons.check_circle_rounded : Icons.store_rounded, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d.creditorName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                                        const SizedBox(height: 4),
                                        Text(
                                          'الإجمالي: ${d.totalAmount.toStringAsFixed(0)} ج.م - المسدد: ${d.paidAmount.toStringAsFixed(0)} ج.م'
                                          '${d.notes.isNotEmpty ? ' - ${d.notes}' : ''}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    isSettled ? 'مسدد بالكامل' : '${remaining.toStringAsFixed(0)} ج.م',
                                    style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                  if (!isSettled) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: 'سداد دفعة',
                                      icon: const Icon(Icons.payments_rounded, color: AppColors.navy, size: 20),
                                      onPressed: () => _showPayDialog(context, ref, d),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
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

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 620;
      final title0 = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.wood, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                  if (badge != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(badge!, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.wood)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ],
      );

      final action = _HoverCard(
        onTap: onAction,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.wood, AppColors.woodDark]), borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actionIcon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(actionLabel, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      );

      if (narrow) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title0, const SizedBox(height: 16), action]);
      }
      return Row(children: [Expanded(child: title0), action]);
    });
  }
}

class _HeroStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  const _HeroStatCard({required this.label, required this.value, required this.caption, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.03)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Text(value, style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 4),
                Text(caption, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(text, style: GoogleFonts.cairo(fontSize: 14.5, color: Colors.grey.shade500)),
        ],
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
  const _HoverCard({required this.child, this.onTap, this.borderRadius = const BorderRadius.all(Radius.circular(18))});

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
