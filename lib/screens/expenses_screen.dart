import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('اختار الطلبات', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 420,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    decoration: _fieldDecoration('ابحث بالعميل أو الصنف...', Icons.search_rounded),
                    onChanged: (v) => setPickerState(() => query = v),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const _EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج')
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final o = filtered[index];
                              final checked = selectedOrderIds.contains(o.id);
                              return CheckboxListTile(
                                value: checked,
                                activeColor: AppColors.wood,
                                title: Text('${o.customerName} - ${o.itemType}', style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                subtitle: Text('${o.status} | المتبقي: ${o.remaining.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontSize: 11.5)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(expense == null ? 'إضافة مصروف' : 'تعديل المصروف', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 420,
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
                    const SizedBox(height: 14),
                    if (category == 'wages')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(controller: workerController, decoration: _fieldDecoration('اسم الصنايعي', Icons.engineering_outlined)),
                      ),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('المبلغ (ج.م)', Icons.payments_outlined),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: descriptionController, maxLines: 2, decoration: _fieldDecoration('الوصف (اختياري)', Icons.notes_rounded)),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: _fieldDecoration('اتخصم من (مصدر الدفع)', Icons.account_balance_wallet_outlined),
                      items: paymentMethods.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      validator: (v) => v == null ? 'اختر مصدر خروج المبلغ' : null,
                      onChanged: (v) => setDialogState(() => paymentMethod = v),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await _pickOrders(context, orders, selectedOrderIds);
                        setDialogState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.checklist_rounded, color: AppColors.wood, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('تحميل المصروف على طلبات (اختياري)', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                                  Text(
                                    selectedOrderIds.isEmpty
                                        ? 'مصروف عام - مش مقسّم على أي طلب'
                                        : '${selectedOrderIds.length} طلب مختار - هيتقسم المبلغ عليهم بالتساوي',
                                    style: GoogleFonts.cairo(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: selectedOrderIds.isEmpty ? Colors.grey.shade600 : AppColors.navy),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                    if (selectedOrderIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedOrderIds.map((id) {
                            final o = orders.firstWhereOrNull((o) => o.id == id);
                            return Chip(
                              label: Text(o != null ? '${o.customerName} - ${o.itemType}' : 'طلب محذوف', style: GoogleFonts.cairo(fontSize: 11.5)),
                              onDeleted: () => setDialogState(() => selectedOrderIds.remove(id)),
                              backgroundColor: AppColors.wood.withValues(alpha: 0.08),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _DatePickerRow(
                      label: 'التاريخ',
                      date: date,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: _PageHeader(
              title: 'المصروفات',
              subtitle: 'كل المصروفات المسجّلة على الورشة',
              icon: Icons.receipt_long_rounded,
              badge: expensesAsync.value != null ? '${expensesAsync.value!.length} مصروف' : null,
              actionLabel: 'إضافة مصروف',
              actionIcon: Icons.add_rounded,
              onAction: () => _showExpenseDialog(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'الكل', selected: _categoryFilter == null, onTap: () => setState(() => _categoryFilter = null)),
                  const SizedBox(width: 8),
                  ...expenseCategories.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _FilterChip(label: e.value, selected: _categoryFilter == e.key, onTap: () => setState(() => _categoryFilter = e.key)),
                      )),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
            child: _HoverCard(
              borderRadius: BorderRadius.circular(16),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'ابحث بالوصف أو اسم الصنايعي...',
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() => _query = ''),
              ),
            ),
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
                if (filtered.isEmpty) {
                  return const _EmptyState(icon: Icons.receipt_long_outlined, text: 'لا توجد مصروفات مسجلة');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final e = filtered[index];
                    final allocs = e.allocations;
                    final ordersLabel = allocs.isEmpty
                        ? null
                        : allocs.length == 1
                            ? 'محمّل على: ${allocs.first.customerName}'
                            : 'مقسّم على ${allocs.length} طلبات';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HoverCard(
                        onTap: () => _showExpenseDialog(context, ref, expense: e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long_rounded, color: AppColors.warning, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.description.isNotEmpty ? e.description : (expenseCategories[e.category] ?? e.category),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${expenseCategories[e.category] ?? e.category}${e.workerName != null ? ' - ${e.workerName}' : ''}'
                                      '${ordersLabel != null ? ' - $ordersLabel' : ''}'
                                      ' - ${paymentMethods[e.paymentMethod] ?? e.paymentMethod}'
                                      ' - ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${e.amount.toStringAsFixed(0)} ج.م',
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.danger, fontSize: 14)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300),
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

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerRow({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.wood, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                  Text('${date.year}/${date.month}/${date.day}', style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.wood : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.wood : Colors.grey.shade300),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey.shade700)),
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
