import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';

const _salaryTypes = {'monthly': 'شهري', 'weekly': 'أسبوعي', 'daily': 'يومي'};
const _weekdays = {
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
  DateTime.monday: 'الاثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
};

class WorkersScreen extends ConsumerStatefulWidget {
  const WorkersScreen({super.key});
  @override
  ConsumerState<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends ConsumerState<WorkersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showWorkerDialog(BuildContext context, WidgetRef ref, {Worker? worker}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: worker?.name ?? '');
    final jobController = TextEditingController(text: worker?.jobTitle ?? '');
    final amountController = TextEditingController(text: worker != null ? worker.salaryAmount.toStringAsFixed(0) : '');
    final phoneController = TextEditingController(text: worker?.phone ?? '');
    final notesController = TextEditingController(text: worker?.notes ?? '');
    String salaryType = worker?.salaryType ?? 'monthly';
    int payWeekday = worker?.payWeekday ?? DateTime.thursday;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(worker == null ? 'إضافة عامل جديد' : 'تعديل بيانات العامل', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: _fieldDecoration('اسم العامل', Icons.person_outline_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: jobController,
                      decoration: _fieldDecoration('الوظيفة (صنايعي، محاسب، مدير سوشيال...)', Icons.badge_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الوظيفة مطلوبة' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: salaryType,
                      decoration: _fieldDecoration('نوع المرتب', Icons.calendar_view_week_rounded),
                      items: _salaryTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => salaryType = v!),
                    ),
                    const SizedBox(height: 14),
                    if (salaryType == 'weekly') ...[
                      DropdownButtonFormField<int>(
                        value: payWeekday,
                        decoration: _fieldDecoration('يوم القبض الأسبوعي', Icons.event_rounded),
                        items: _weekdays.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (v) => setDialogState(() => payWeekday = v!),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration(
                        salaryType == 'monthly'
                            ? 'المرتب الشهري (ج.م)'
                            : salaryType == 'weekly'
                                ? 'المرتب الأسبوعي (ج.م)'
                                : 'المرتب اليومي (ج.م)',
                        Icons.payments_outlined,
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(controller: phoneController, decoration: _fieldDecoration('رقم الهاتف (اختياري)', Icons.phone_outlined)),
                    const SizedBox(height: 14),
                    TextFormField(controller: notesController, maxLines: 2, decoration: _fieldDecoration('ملاحظات (اختياري)', Icons.notes_rounded)),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (worker != null)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('حذف العامل'),
                      content: Text('هل أنت متأكد من حذف "${worker.name}"؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(repositoryProvider).deleteWorker(worker.id);
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
                if (worker == null) {
                  await repo.addWorker(
                    name: nameController.text.trim(),
                    jobTitle: jobController.text.trim(),
                    salaryType: salaryType,
                    salaryAmount: double.parse(amountController.text.trim()),
                    payWeekday: payWeekday,
                    phone: phoneController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                } else {
                  await repo.updateWorker(
                    worker,
                    name: nameController.text.trim(),
                    jobTitle: jobController.text.trim(),
                    salaryType: salaryType,
                    salaryAmount: double.parse(amountController.text.trim()),
                    payWeekday: payWeekday,
                    phone: phoneController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(workersProvider);
    final dueToday = ref.watch(workersDueTodayProvider);

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: _PageHeader(
              title: 'العمال',
              subtitle: 'إدارة العمال ومرتباتهم ومواعيد القبض',
              icon: Icons.engineering_rounded,
              badge: workersAsync.value != null ? '${workersAsync.value!.length} عامل' : null,
              actionLabel: 'إضافة عامل',
              actionIcon: Icons.person_add_alt_1_rounded,
              onAction: () => _showWorkerDialog(context, ref),
            ),
          ),
          if (dueToday.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: _HoverCard(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(11)),
                            child: const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text('النهاردة يوم القبض الأسبوعي!', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...dueToday.map((w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${w.name} (${w.jobTitle}) - ${w.salaryAmount.toStringAsFixed(0)} ج.م',
                                      style: GoogleFonts.cairo(fontSize: 13)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _confirmPayment(context, ref, w),
                                  child: const Text('تأكيد الدفع'),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: _HoverCard(
              borderRadius: BorderRadius.circular(16),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'ابحث بالاسم أو الوظيفة...',
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() => _query = ''),
              ),
            ),
          ),
          Expanded(
            child: workersAsync.when(
              data: (workers) {
                if (workers.isEmpty) {
                  return const _EmptyState(icon: Icons.engineering_outlined, text: 'لا يوجد عمال بعد');
                }
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty
                    ? workers
                    : workers.where((w) {
                        return normalizeForSearch(w.name).contains(q) || normalizeForSearch(w.jobTitle).contains(q);
                      }).toList();
                if (filtered.isEmpty) {
                  return const _EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج مطابقة');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final w = filtered[index];
                    final isDue = dueToday.any((d) => d.id == w.id);
                    final accent = isDue ? AppColors.warning : AppColors.wood;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HoverCard(
                        onTap: () => showDialog(context: context, builder: (context) => _WorkerDetailDialog(worker: w)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: accent.withValues(alpha: 0.14),
                                child: Text(w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                                    style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(w.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${w.jobTitle} - ${_salaryTypes[w.salaryType]}${w.salaryType == 'weekly' ? ' (${_weekdays[w.payWeekday]})' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${w.salaryAmount.toStringAsFixed(0)} ج.م',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13.5, color: const Color(0xFF2A2320))),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.navy),
                                onPressed: () => _showWorkerDialog(context, ref, worker: w),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context, WidgetRef ref, Worker worker) async {
    final now = DateTime.now();
    final anchor = workerPeriodAnchor(worker, now);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الدفع'),
        content: Text('هل تم صرف ${worker.salaryAmount.toStringAsFixed(0)} ج.م لـ "${worker.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(repositoryProvider).confirmWorkerPayment(worker: worker, amount: worker.salaryAmount, periodStart: anchor);
    }
  }
}

/// ديالوج بيعرض تفاصيل العامل وسجل قبضه، وبيديك إمكانية تسجّل قبض
/// (يدوي، لأي نوع مرتب - يومي أو أسبوعي أو شهري) حتى لو مش النهاردة
/// موعده الأصلي
class _WorkerDetailDialog extends ConsumerWidget {
  final Worker worker;
  const _WorkerDetailDialog({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(workerPaymentsForWorkerProvider(worker.id));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(worker.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
      content: SizedBox(
        width: 420,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${worker.jobTitle} - ${_salaryTypes[worker.salaryType]}${worker.salaryType == 'weekly' ? ' (${_weekdays[worker.payWeekday]})' : ''}',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Text('المرتب: ${worker.salaryAmount.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14)),
              if (worker.phone.isNotEmpty) ...[const SizedBox(height: 6), Text('الهاتف: ${worker.phone}', style: GoogleFonts.cairo(fontSize: 13))],
              if (worker.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(worker.notes, style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12.5)),
              ],
              const SizedBox(height: 18),
              _FieldLabel('سجل القبض'),
              const SizedBox(height: 10),
              paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return const _EmptyState(icon: Icons.history_toggle_off_rounded, text: 'لسه ماتسجّلش أي قبض لهذا العامل');
                  }
                  return Column(
                    children: payments
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MiniRow(
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: AppColors.success,
                                title: '${p.amount.toStringAsFixed(0)} ج.م',
                                subtitle: DateFormat('d/M/yyyy - hh:mm a', 'ar_EG').format(DateTime.fromMillisecondsSinceEpoch(p.paymentDate)),
                              ),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
                error: (e, _) => Text('خطأ: $e'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ElevatedButton.icon(
          icon: const Icon(Icons.payments_rounded, size: 18),
          label: const Text('تسجيل قبض'),
          onPressed: () async {
            final now = DateTime.now();
            final anchor = workerPeriodAnchor(worker, now);
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('تأكيد الدفع'),
                content: Text('هل تم صرف ${worker.salaryAmount.toStringAsFixed(0)} ج.م لـ "${worker.name}"؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(repositoryProvider).confirmWorkerPayment(worker: worker, amount: worker.salaryAmount, periodStart: anchor);
              if (context.mounted) Navigator.pop(context);
            }
          },
        ),
      ],
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

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  const _MiniRow({required this.icon, required this.title, required this.subtitle, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (iconColor ?? AppColors.wood).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor ?? AppColors.wood),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2A2320))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
