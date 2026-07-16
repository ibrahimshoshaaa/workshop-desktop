import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/other_dropdown.dart';
import '../core/constants.dart';
import '../core/order_calculations.dart';

/// فئات المصروفات المتاحة للإضافة اليدوية من هنا - بنستبعد "سداد مديونية
/// ورشة" لأنها بتتسجل أوتوماتيك بس من شاشة "مديونيات الورشة"
final _categories = Map.fromEntries(expenseCategories.entries.where((e) => e.key != 'workshop_debt'));

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _categoryFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ديالوج فرعي لاختيار أكتر من طلب لتقسيم المصروف عليهم - بيعدّل
  /// [selectedOrderIds] في مكانه (in place) فور ما المستخدم يضغط تم
  Future<void> _pickOrders(BuildContext context, List<Order> orders, Set<String> selectedOrderIds) async {
    String query = '';
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          final q = normalizeForSearch(query);
          final filtered = q.isEmpty
              ? orders
              : orders.where((o) => normalizeForSearch(o.customerName).contains(q) || normalizeForSearch(o.itemType).contains(q)).toList();
          return AlertDialog(
            title: const Text('اختار الطلبات'),
            content: SizedBox(
              width: 420,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(hintText: 'ابحث بالعميل أو الصنف...', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setPickerState(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final o = filtered[index];
                              final checked = selectedOrderIds.contains(o.id);
                              return CheckboxListTile(
                                value: checked,
                                title: Text('${o.customerName} - ${o.itemType}'),
                                subtitle: Text('${o.status} | المتبقي: ${o.remaining.toStringAsFixed(0)} ج.م'),
                                onChanged: (v) => setPickerState(() {
                                  if (v == true) {
                                    selectedOrderIds.add(o.id);
                                  } else {
                                    selectedOrderIds.remove(o.id);
                                  }
                                }),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showExpenseDialog(BuildContext context, WidgetRef ref, {Expense? expense}) async {
    if (expense != null && expense.category == 'workshop_debt') {
      // مصروفات سداد مديونية الورشة بتتسجل وبتتعدّل من شاشة "مديونيات
      // الورشة" بس، عشان تفضل مرتبطة صح بإجمالي المديونية المسدد
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ده مصروف سداد مديونية ورشة - عدّله من شاشة "مديونيات الورشة"')),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    String category = expense?.category ?? _categories.keys.first;
    final amountController = TextEditingController(text: expense?.amount.toStringAsFixed(0) ?? '');
    final descriptionController = TextEditingController(text: expense?.description ?? '');
    final workerController = TextEditingController(text: expense?.workerName ?? '');
    DateTime date = expense != null ? DateTime.fromMillisecondsSinceEpoch(expense.date) : DateTime.now();
    final orders = ref.read(ordersProvider).value ?? [];
    // الطلبات اللي المصروف مقسّم عليها - بيتحسب نصيب كل طلب بالتساوي
    // وقت الحفظ (إجمالي المصروف ÷ عدد الطلبات المختارة)
    final selectedOrderIds = expense?.allocations.map((a) => a.orderId).toSet() ?? <String>{};
    // مصدر خروج المبلغ من الخزينة (نقدي/إنستاباي) - حقل إجباري
    String? paymentMethod = expense?.paymentMethod ?? 'cash';

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
                    OtherCapableDropdown(
                      options: _categories.entries.where((e) => e.key != 'other').map((e) => e.value).toList(),
                      label: 'الفئة',
                      value: _categories[category] ?? category,
                      onChanged: (v) => setDialogState(
                        () => category = _categories.entries.firstWhereOrNull((e) => e.value == v)?.key ?? v,
                      ),
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
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: const InputDecoration(labelText: 'اتخصم من (مصدر الدفع)'),
                      items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      validator: (v) => v == null ? 'اختر مصدر خروج المبلغ' : null,
                      onChanged: (v) => setDialogState(() => paymentMethod = v),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تحميل المصروف على طلبات (اختياري)'),
                      subtitle: Text(
                        selectedOrderIds.isEmpty
                            ? 'مصروف عام - مش مقسّم على أي طلب'
                            : '${selectedOrderIds.length} طلب مختار - هيتقسم المبلغ عليهم بالتساوي',
                        style: TextStyle(color: selectedOrderIds.isEmpty ? Colors.grey : AppColors.navy),
                      ),
                      trailing: const Icon(Icons.checklist_rounded),
                      onTap: () async {
                        await _pickOrders(context, orders, selectedOrderIds);
                        setDialogState(() {});
                      },
                    ),
                    if (selectedOrderIds.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedOrderIds.map((id) {
                          final o = orders.firstWhereOrNull((o) => o.id == id);
                          return Chip(
                            label: Text(o != null ? '${o.customerName} - ${o.itemType}' : 'طلب محذوف'),
                            onDeleted: () => setDialogState(() => selectedOrderIds.remove(id)),
                          );
                        }).toList(),
                      ),
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
            if (expense != null)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('حذف المصروف'),
                      content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(repositoryProvider).deleteExpense(expense.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (category.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب فئة المصروف')));
                  return;
                }
                final repo = ref.read(repositoryProvider);
                final workerName = category == 'wages' && workerController.text.trim().isNotEmpty ? workerController.text.trim() : null;
                final totalAmount = double.parse(amountController.text.trim());
                final chosenOrders = selectedOrderIds.map((id) => orders.firstWhereOrNull((o) => o.id == id)).whereType<Order>().toList();
                final shareAmount = chosenOrders.isEmpty ? 0.0 : totalAmount / chosenOrders.length;
                final orderAllocations = chosenOrders
                    .map((o) => ExpenseOrderAllocation(orderId: o.id, customerId: o.customerId, customerName: o.customerName, amount: shareAmount))
                    .toList();
                if (expense == null) {
                  await repo.addExpense(
                    amount: totalAmount,
                    category: category,
                    description: descriptionController.text.trim(),
                    workerName: workerName,
                    date: date,
                    paymentMethod: paymentMethod!,
                    orderAllocations: orderAllocations,
                  );
                } else {
                  await repo.updateExpense(
                    expense,
                    amount: totalAmount,
                    category: category,
                    description: descriptionController.text.trim(),
                    workerName: workerName,
                    date: date,
                    paymentMethod: paymentMethod!,
                    orderAllocations: orderAllocations,
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
                ...expenseCategories.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(e.value), selected: _categoryFilter == e.key, onSelected: (_) => setState(() => _categoryFilter = e.key)),
                    )),
              ],
            ),
          ),
          AppSearchBar(
            controller: _searchController,
            hintText: 'ابحث بالوصف أو اسم الصنايعي...',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                var filtered = _categoryFilter == null ? expenses : expenses.where((e) => e.category == _categoryFilter).toList();
                final q = normalizeForSearch(_query);
                if (q.isNotEmpty) {
                  filtered = filtered.where((e) {
                    return normalizeForSearch(e.description).contains(q) ||
                        normalizeForSearch(e.workerName ?? '').contains(q) ||
                        normalizeForSearch(expenseCategories[e.category] ?? e.category).contains(q);
                  }).toList();
                }
                if (filtered.isEmpty) return const Center(child: Text('لا توجد مصروفات مسجلة', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final e = filtered[index];
                    final allocs = e.allocations;
                    final ordersLabel = allocs.isEmpty
                        ? null
                        : allocs.length == 1
                            ? 'محمّل على: ${allocs.first.customerName}'
                            : 'مقسّم على ${allocs.length} طلبات';
                    return Card(
                      child: ListTile(
                        onTap: () => _showExpenseDialog(context, ref, expense: e),
                        title: Text(e.description.isNotEmpty ? e.description : (expenseCategories[e.category] ?? e.category)),
                        subtitle: Text(
                          '${expenseCategories[e.category] ?? e.category}${e.workerName != null ? ' - ${e.workerName}' : ''}'
                          '${ordersLabel != null ? ' | $ordersLabel' : ''}'
                          ' | ${paymentMethods[e.paymentMethod] ?? e.paymentMethod}'
                          ' | ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))}',
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
