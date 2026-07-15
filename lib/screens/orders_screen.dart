import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/search_bar.dart';
import '../core/whatsapp.dart';
import '../core/order_calculations.dart';

const _itemTypes = ['أنتريه', 'صالون', 'ركنة', 'ستائر', 'سرير', 'كنب', 'أخرى'];

/// بيبني نص الرسالة اللي هتتبعت على واتساب - بيشمل المواصفات اللي
/// اتكتبت وقت إضافة الطلب، مع أهم بيانات الطلب (النوع، تاريخ التسليم،
/// الإجمالي والمتبقي) عشان العميل ياخد صورة كاملة من رسالة واحدة
String _buildOrderShareText(Order order) {
  final remaining = order.remaining;
  final buffer = StringBuffer()
    ..writeln('طلب: ${order.itemType}')
    ..writeln('العميل: ${order.customerName}');
  if (order.details.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('المواصفات:')
      ..writeln(order.details.trim())
      ..writeln();
  }
  buffer
    ..writeln('تاريخ التسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(order.deliveryDate))}')
    ..writeln('الإجمالي: ${order.effectiveTotal.toStringAsFixed(0)} ج.م');
  if (remaining > 0) buffer.writeln('المتبقي: ${remaining.toStringAsFixed(0)} ج.م');
  return buffer.toString();
}

Future<void> _shareOrderOnWhatsApp(BuildContext context, WidgetRef ref, Order order) async {
  final customers = ref.read(customersProvider).value ?? [];
  final customer = customers.firstWhereOrNull((c) => c.id == order.customerId);
  final ok = await shareTextOnWhatsApp(_buildOrderShareText(order), phone: customer?.phone);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مقدرش أفتح واتساب - تأكد إنه متثبت على الجهاز')));
  }
}

/// ديالوج إضافة طلب جديد - قابل لإعادة الاستخدام من أي صفحة. لو اتبعتله
/// [presetCustomer] (زي لما بيتفتح من ديالوج طلبات عميل معيّن في صفحة
/// العملاء) بيثبّت العميل ده تلقائيًا من غير ما يوريلك قايمة الاختيار
Future<void> showAddOrderDialog(BuildContext context, WidgetRef ref, {Customer? presetCustomer}) async {
  final customers = ref.read(customersProvider).value ?? [];
  if (presetCustomer == null && customers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف عميل أولًا')));
    return;
  }
  final formKey = GlobalKey<FormState>();
  String? customerId = presetCustomer?.id ?? customers.first.id;
  String itemType = _itemTypes.first;
  final detailsController = TextEditingController();
  final totalController = TextEditingController();
  final depositController = TextEditingController();
  DateTime deliveryDate = DateTime.now().add(const Duration(days: 7));

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(presetCustomer == null ? 'طلب جديد' : 'طلب جديد لـ ${presetCustomer.name}'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (presetCustomer == null)
                    DropdownButtonFormField<String>(
                      value: customerId,
                      decoration: const InputDecoration(labelText: 'العميل'),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.phone}'))).toList(),
                      onChanged: (v) => setDialogState(() => customerId = v),
                    )
                  else
                    TextFormField(
                      initialValue: '${presetCustomer.name} - ${presetCustomer.phone}',
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'العميل'),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: itemType,
                    decoration: const InputDecoration(labelText: 'نوع الصنف'),
                    items: _itemTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => itemType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: detailsController, maxLines: 2, decoration: const InputDecoration(labelText: 'المواصفات')),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تاريخ التسليم'),
                    subtitle: Text('${deliveryDate.year}/${deliveryDate.month}/${deliveryDate.day}'),
                    trailing: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deliveryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => deliveryDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'إجمالي الاتفاق (ج.م)'),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'أدخل مبلغ صحيح' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: depositController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'العربون المدفوع الآن (اختياري)'),
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
              if (!formKey.currentState!.validate() || customerId == null) return;
              final customer = presetCustomer ?? customers.firstWhere((c) => c.id == customerId);
              final repo = ref.read(repositoryProvider);
              final orderId = await repo.addOrder(
                customerId: customer.id,
                customerName: customer.name,
                itemType: itemType,
                details: detailsController.text.trim(),
                totalAmount: double.parse(totalController.text.trim()),
                deliveryDate: deliveryDate,
              );
              final deposit = double.tryParse(depositController.text.trim()) ?? 0;
              if (deposit > 0) {
                await repo.addPayment(orderId: orderId, customerId: customer.id, amount: deposit, paymentType: 'deposit');
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

Color _statusColor(String status) {
  switch (status) {
    case 'جاري التجهيز':
      return AppColors.warning;
    case 'قيد التنفيذ':
      return AppColors.navy;
    case 'جاهز للتسليم':
      return AppColors.success;
    case 'تم التسليم':
      return Colors.grey.shade600;
    default:
      return Colors.grey;
  }
}

/// شارة حالة الطلب - ملوّنة حسب الحالة وقابلة للضغط عليها مباشرة لتغيير
/// الحالة من غير ما تحتاج تدخل على تفاصيل الطلب
class _StatusChip extends ConsumerWidget {
  final Order order;
  const _StatusChip({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(order.status);
    return PopupMenuButton<String>(
      tooltip: 'تغيير حالة الطلب',
      onSelected: (v) => ref.read(repositoryProvider).updateOrderStatus(order.id, v),
      itemBuilder: (context) => orderStatuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(order.status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _statusFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => showAddOrderDialog(context, ref))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                ChoiceChip(label: const Text('الكل'), selected: _statusFilter == null, onSelected: (_) => setState(() => _statusFilter = null)),
                const SizedBox(width: 8),
                ...orderStatuses.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(s), selected: _statusFilter == s, onSelected: (_) => setState(() => _statusFilter = s)),
                    )),
              ],
            ),
          ),
          AppSearchBar(
            controller: _searchController,
            hintText: 'ابحث باسم العميل أو نوع الصنف...',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                var filtered = _statusFilter == null ? orders : orders.where((o) => o.status == _statusFilter).toList();
                final q = normalizeForSearch(_query);
                if (q.isNotEmpty) {
                  filtered = filtered.where((o) {
                    return normalizeForSearch(o.customerName).contains(q) ||
                        normalizeForSearch(o.itemType).contains(q) ||
                        normalizeForSearch(o.details).contains(q);
                  }).toList();
                }
                if (filtered.isEmpty) return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final o = filtered[index];
                    final remaining = o.remaining;
                    return Card(
                      child: ListTile(
                        title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}'),
                              const SizedBox(width: 8),
                              _StatusChip(order: o),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                              style: TextStyle(color: remaining > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              tooltip: 'مشاركة على واتساب',
                              icon: const Icon(Icons.share_rounded, color: AppColors.success),
                              onPressed: () => _shareOrderOnWhatsApp(context, ref, o),
                            ),
                          ],
                        ),
                        onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
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

class OrderDetailDialog extends ConsumerWidget {
  final Order order;
  const OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = (ordersAsync.value ?? []).firstWhereOrNull((o) => o.id == order.id) ?? order;
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final orderTransactions = (transactionsAsync.value ?? []).where((t) => t.orderId == order.id).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final remaining = currentOrder.remaining;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('${currentOrder.customerName} - ${currentOrder.itemType}')),
          IconButton(
            tooltip: 'مشاركة على واتساب',
            icon: const Icon(Icons.share_rounded, color: AppColors.success),
            onPressed: () => _shareOrderOnWhatsApp(context, ref, currentOrder),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentOrder.details.isNotEmpty) Text(currentOrder.details, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: currentOrder.status,
                decoration: const InputDecoration(labelText: 'حالة الطلب'),
                items: orderStatuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(repositoryProvider).updateOrderStatus(currentOrder.id, v);
                },
              ),
              if (currentOrder.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'الاتفاق الأصلي: ${currentOrder.totalAmount.toStringAsFixed(0)} ج.م - خصم ${currentOrder.discountAmount.toStringAsFixed(0)} ج.م'
                    '${currentOrder.discountReason.isNotEmpty ? ' (${currentOrder.discountReason})' : ''}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MoneyBox(label: 'الإجمالي', value: currentOrder.effectiveTotal),
                  _MoneyBox(label: 'المدفوع', value: currentOrder.totalPaid, color: AppColors.success),
                  _MoneyBox(label: 'المتبقي', value: remaining, color: remaining > 0 ? AppColors.danger : AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (remaining > 0)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddPaymentDialog(context, ref, currentOrder, remaining),
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('تسجيل دفعة'),
                      ),
                    ),
                  if (remaining > 0) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddExpenseDialog(context, ref, currentOrder),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('تسجيل مصروف'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning, side: const BorderSide(color: AppColors.warning)),
                  onPressed: () => _showDiscountDialog(context, ref, currentOrder),
                  icon: const Icon(Icons.percent_rounded),
                  label: Text(currentOrder.discountAmount > 0 ? 'تعديل الخصم' : 'عمل خصم'),
                ),
              ),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('سجل الدفعات', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              if (orderTransactions.isEmpty)
                const Text('لا توجد دفعات مسجلة بعد', style: TextStyle(color: Colors.grey))
              else
                ...orderTransactions.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(t.paymentType == 'deposit' ? Icons.savings_rounded : Icons.payments_rounded, color: AppColors.wood),
                      title: Text('${t.amountPaid.toStringAsFixed(0)} ج.م'),
                      subtitle: Text(t.paymentType == 'deposit' ? 'عربون' : 'قسط/دفعة'),
                      trailing: Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(t.paymentDate))),
                    )),
              const SizedBox(height: 16),
              const Align(alignment: Alignment.centerRight, child: Text('سجل المصروفات', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              _OrderExpensesList(orderId: order.id),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('حذف الطلب'),
                content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(repositoryProvider).deleteOrder(currentOrder.id);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('حذف الطلب', style: TextStyle(color: AppColors.danger)),
        ),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref, Order order) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: order.discountAmount > 0 ? order.discountAmount.toStringAsFixed(0) : '',
    );
    final reasonController = TextEditingController(text: order.discountReason);
    final maxDiscount = order.totalAmount - order.totalPaid;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خصم على الطلب'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الخصم مبلغ ثابت (مش نسبة) - بيتشال من الاتفاق الأصلي (${order.totalAmount.toStringAsFixed(0)} ج.م)، '
                    'ومش بيتحسب مديونية عليه ولا إيراد للورشة',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مبلغ الخصم (ج.م)'),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    if (amount == null || amount < 0) return 'أدخل مبلغ صحيح';
                    if (amount > maxDiscount) return 'الخصم أكبر من المتبقي (${maxDiscount.toStringAsFixed(0)} ج.م)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: reasonController, decoration: const InputDecoration(labelText: 'السبب (اختياري)')),
              ],
            ),
          ),
        ),
        actions: [
          if (order.discountAmount > 0)
            TextButton(
              onPressed: () async {
                await ref.read(repositoryProvider).setOrderDiscount(order, discountAmount: 0, reason: '');
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('إلغاء الخصم', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final amount = double.parse(amountController.text.trim());
              await ref.read(repositoryProvider).setOrderDiscount(order, discountAmount: amount, reason: reasonController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, WidgetRef ref, Order order, double maxAmount) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'المبلغ (المتبقي ${maxAmount.toStringAsFixed(0)} ج.م)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount == null || amount <= 0) return;
              await ref.read(repositoryProvider).addPayment(orderId: order.id, customerId: order.customerId, amount: amount, paymentType: 'installment');
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, WidgetRef ref, Order order) {
    final formKey = GlobalKey<FormState>();
    String category = expenseCategories.keys.first;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final workerController = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تسجيل مصروف على الطلب'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'الفئة'),
                      items: expenseCategories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
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
                final workerName = category == 'wages' && workerController.text.trim().isNotEmpty ? workerController.text.trim() : null;
                await ref.read(repositoryProvider).addExpense(
                      amount: double.parse(amountController.text.trim()),
                      category: category,
                      description: descriptionController.text.trim(),
                      workerName: workerName,
                      date: date,
                      orderId: order.id,
                      customerId: order.customerId,
                      customerName: order.customerName,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة المصروفات المرتبطة بطلب معيّن - بتتحدث تلقائيًا لما نضيف مصروف جديد
class _OrderExpensesList extends ConsumerWidget {
  final String orderId;
  const _OrderExpensesList({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(orderExpensesProvider(orderId));
    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Text('لا توجد مصروفات مسجلة على الطلب ده بعد', style: TextStyle(color: Colors.grey));
        }
        final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
        return Column(
          children: sorted
              .map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long_rounded, color: AppColors.warning),
                    title: Text('${e.amount.toStringAsFixed(0)} ج.م - ${expenseCategories[e.category] ?? e.category}'),
                    subtitle: Text(
                      e.description.isNotEmpty
                          ? e.description
                          : (e.workerName != null ? 'الصنايعي: ${e.workerName}' : ''),
                    ),
                    trailing: Text(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: AppColors.danger)),
    );
  }
}

class _MoneyBox extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  const _MoneyBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}
