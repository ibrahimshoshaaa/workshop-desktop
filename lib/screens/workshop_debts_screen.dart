import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: Text(debt == null ? 'تسجيل مديونية جديدة' : 'تعديل المديونية'),
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
                    decoration: const InputDecoration(labelText: 'اسم المورد / الصنايعي'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'اكتب الاسم' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'إجمالي المديونية (ج.م)'),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
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
          title: Text('سداد دفعة - ${debt.creditorName}'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('المتبقي حاليًا: ${debt.remaining.toStringAsFixed(0)} ج.م', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'المبلغ المسدد (ج.م)'),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'أدخل مبلغ صحيح';
                      if (val > debt.remaining) return 'المبلغ أكبر من المتبقي';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(labelText: 'اتخصم من (مصدر الدفع)'),
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
    final filteredDebts = q.isEmpty
        ? debts
        : debts.where((d) => normalizeForSearch(d.creditorName).contains(q)).toList();
    // إجمالي المديونيات المستحقة على الورشة دايمًا بيتحسب من كل السجلات،
    // مش من نتيجة البحث، عشان الرقم يفضل يعكس الموقف الحقيقي
    final totalOutstanding = debts.fold<double>(0, (s, d) => s + d.remaining);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مديونيات الورشة'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showDebtDialog(context, ref))],
      ),
      body: debts.isEmpty
          ? const Center(child: Text('لا توجد مديونيات على الورشة حاليًا 🎉', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('إجمالي مديونيات الورشة المستحقة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('${totalOutstanding.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ],
                  ),
                ),
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'ابحث باسم المورد أو الصنايعي...',
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () => setState(() => _query = ''),
                ),
                Expanded(
                  child: filteredDebts.isEmpty
                      ? const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredDebts.length,
                          itemBuilder: (context, index) {
                            final d = filteredDebts[index];
                            final remaining = d.remaining;
                            final isSettled = remaining <= 0;
                            return Card(
                              child: ListTile(
                                onTap: () => _showDebtDialog(context, ref, debt: d),
                                leading: CircleAvatar(
                                  backgroundColor: (isSettled ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                                  child: Icon(isSettled ? Icons.check_circle_rounded : Icons.store_rounded, color: isSettled ? AppColors.success : AppColors.danger),
                                ),
                                title: Text(d.creditorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  'الإجمالي: ${d.totalAmount.toStringAsFixed(0)} ج.م — المسدد: ${d.paidAmount.toStringAsFixed(0)} ج.م'
                                  '${d.notes.isNotEmpty ? '\n${d.notes}' : ''}',
                                ),
                                isThreeLine: d.notes.isNotEmpty,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isSettled ? 'مسدد بالكامل' : '${remaining.toStringAsFixed(0)} ج.م',
                                      style: TextStyle(color: isSettled ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (!isSettled) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'سداد دفعة',
                                        icon: const Icon(Icons.payments_rounded, color: AppColors.navy),
                                        onPressed: () => _showPayDialog(context, ref, d),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
