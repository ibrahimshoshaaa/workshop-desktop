import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
          title: Text(worker == null ? 'إضافة عامل جديد' : 'تعديل بيانات العامل'),
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
                      decoration: const InputDecoration(labelText: 'اسم العامل'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: jobController,
                      decoration: const InputDecoration(labelText: 'الوظيفة (صنايعي، محاسب، مدير سوشيال...)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'الوظيفة مطلوبة' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: salaryType,
                      decoration: const InputDecoration(labelText: 'نوع المرتب'),
                      items: _salaryTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => salaryType = v!),
                    ),
                    const SizedBox(height: 12),
                    if (salaryType == 'weekly') ...[
                      DropdownButtonFormField<int>(
                        value: payWeekday,
                        decoration: const InputDecoration(labelText: 'يوم القبض الأسبوعي'),
                        items: _weekdays.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                        onChanged: (v) => setDialogState(() => payWeekday = v!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: salaryType == 'monthly'
                            ? 'المرتب الشهري (ج.م)'
                            : salaryType == 'weekly'
                                ? 'المرتب الأسبوعي (ج.م)'
                                : 'المرتب اليومي (ج.م)',
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)')),
                    const SizedBox(height: 12),
                    TextFormField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('العمال'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () => _showWorkerDialog(context, ref))],
      ),
      body: Column(
        children: [
          if (dueToday.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('النهاردة يوم القبض الأسبوعي!', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dueToday.map((w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${w.name} (${w.jobTitle}) - ${w.salaryAmount.toStringAsFixed(0)} ج.م')),
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
          AppSearchBar(
            controller: _searchController,
            hintText: 'ابحث بالاسم أو الوظيفة...',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          Expanded(
            child: workersAsync.when(
              data: (workers) {
                if (workers.isEmpty) {
                  return const Center(child: Text('لا يوجد عمال بعد', style: TextStyle(color: Colors.grey)));
                }
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty
                    ? workers
                    : workers.where((w) {
                        return normalizeForSearch(w.name).contains(q) || normalizeForSearch(w.jobTitle).contains(q);
                      }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final w = filtered[index];
                    final isDue = dueToday.any((d) => d.id == w.id);
                    return Card(
                      child: ListTile(
                        onTap: () => showDialog(context: context, builder: (context) => _WorkerDetailDialog(worker: w)),
                        leading: CircleAvatar(
                          backgroundColor: (isDue ? AppColors.warning : AppColors.wood).withValues(alpha: 0.15),
                          child: Text(w.name.isNotEmpty ? w.name[0] : '?',
                              style: TextStyle(color: isDue ? AppColors.warning : AppColors.wood, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(w.name),
                        subtitle: Text(
                          '${w.jobTitle} - ${_salaryTypes[w.salaryType]}${w.salaryType == 'weekly' ? ' (${_weekdays[w.payWeekday]})' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${w.salaryAmount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showWorkerDialog(context, ref, worker: w)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
      title: Text(worker.name),
      content: SizedBox(
        width: 420,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${worker.jobTitle} - ${_salaryTypes[worker.salaryType]}${worker.salaryType == 'weekly' ? ' (${_weekdays[worker.payWeekday]})' : ''}'),
              const SizedBox(height: 4),
              Text('المرتب: ${worker.salaryAmount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (worker.phone.isNotEmpty) ...[const SizedBox(height: 4), Text('الهاتف: ${worker.phone}')],
              if (worker.notes.isNotEmpty) ...[const SizedBox(height: 4), Text(worker.notes, style: const TextStyle(color: Colors.grey))],
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('سجل القبض', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('لسه ماتسجّلش أي قبض لهذا العامل', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(
                    children: payments
                        .map((p) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                              title: Text('${p.amount.toStringAsFixed(0)} ج.م'),
                              subtitle: Text(DateFormat('d/M/yyyy - hh:mm a', 'ar_EG').format(DateTime.fromMillisecondsSinceEpoch(p.paymentDate))),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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
