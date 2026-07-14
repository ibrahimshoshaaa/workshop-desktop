import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';

const _categories = {'materials': 'خامات', 'rent': 'إيجار وتشغيل', 'wages': 'أجور الصنايعية', 'other': 'أخرى'};

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _categoryFilter;

  Future<void> _showExpenseDialog(BuildContext context, WidgetRef ref, {Expense? expense}) async {
    final formKey = GlobalKey<FormState>();
    String category = expense?.category ?? _categories.keys.first;
    final amountController = TextEditingController(text: expense?.amount.toStringAsFixed(0) ?? '');
    final descriptionController = TextEditingController(text: expense?.description ?? '');
    final workerController = TextEditingController(text: expense?.workerName ?? '');
    DateTime date = expense != null ? DateTime.fromMillisecondsSinceEpoch(expense.date) : DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expense == null ? 'إضافة مصروف' : 'تعديل المصروف'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'الفئة'),
                      items: _categories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    if (category == 'wages')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(controller: workerController, decoration: const InputDecoration(labelText: 'اسم الصنايعي')),
                      ),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: descriptionController, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف (اختياري)')),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('التاريخ'),
                      subtitle: Text('${date.year}/${date.month}/${date.day}'),
                      trailing: const Icon(Icons.calendar_month_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => date = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final repo = ref.read(repositoryProvider);
                final workerName = category == 'wages' && workerController.text.trim().isNotEmpty ? workerController.text.trim() : null;
                if (expense == null) {
                  await repo.addExpense(amount: double.parse(amountController.text.trim()), category: category, description: descriptionController.text.trim(), workerName: workerName, date: date);
                } else {
                  await repo.updateExpense(expense, amount: double.parse(amountController.text.trim()), category: category, description: descriptionController.text.trim(), workerName: workerName, date: date);
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
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showExpenseDialog(context, ref))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                ChoiceChip(label: const Text('الكل'), selected: _categoryFilter == null, onSelected: (_) => setState(() => _categoryFilter = null)),
                const SizedBox(width: 8),
                ..._categories.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(e.value), selected: _categoryFilter == e.key, onSelected: (_) => setState(() => _categoryFilter = e.key)),
                    )),
              ],
            ),
          ),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filtered = _categoryFilter == null ? expenses : expenses.where((e) => e.category == _categoryFilter).toList();
                if (filtered.isEmpty) return const Center(child: Text('لا توجد مصروفات مسجلة', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final e = filtered[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _showExpenseDialog(context, ref, expense: e),
                        title: Text(e.description.isNotEmpty ? e.description : (_categories[e.category] ?? 'مصروف')),
                        subtitle: Text(
                          '${_categories[e.category] ?? ''}${e.workerName != null ? ' - ${e.workerName}' : ''} | ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))}',
                        ),
                        trailing: Text('${e.amount.toStringAsFixed(0)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
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
}
