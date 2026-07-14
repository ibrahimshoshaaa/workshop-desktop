import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';

const _itemTypes = ['أنتريه', 'صالون', 'ركنة', 'ستائر', 'سرير', 'كنب', 'أخرى'];
const _statuses = ['جاري التجهيز', 'قيد التنفيذ', 'جاهز للتسليم', 'تم التسليم'];

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _statusFilter;

  Future<void> _showAddOrderDialog(BuildContext context, WidgetRef ref) async {
    final customers = ref.read(customersProvider).value ?? [];
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف عميل أولًا')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    String? customerId = customers.first.id;
    String itemType = _itemTypes.first;
    final detailsController = TextEditingController();
    final totalController = TextEditingController();
    final depositController = TextEditingController();
    DateTime deliveryDate = DateTime.now().add(const Duration(days: 7));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('طلب جديد'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: customerId,
                      decoration: const InputDecoration(labelText: 'العميل'),
                      items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} - ${c.phone}'))).toList(),
                      onChanged: (v) => setDialogState(() => customerId = v),
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
                final customer = customers.firstWhere((c) => c.id == customerId);
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

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلبات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddOrderDialog(context, ref))],
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
                ..._statuses.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(s), selected: _statusFilter == s, onSelected: (_) => setState(() => _statusFilter = s)),
                    )),
              ],
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filtered = _statusFilter == null ? orders : orders.where((o) => o.status == _statusFilter).toList();
                if (filtered.isEmpty) return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final o = filtered[index];
                    final remaining = o.totalAmount - o.totalPaid;
                    return Card(
                      child: ListTile(
                        title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))} | ${o.status}'),
                        trailing: Text(
                          remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                          style: TextStyle(color: remaining > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => showDialog(context: context, builder: (context) => _OrderDetailDialog(order: o)),
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

class _OrderDetailDialog extends ConsumerWidget {
  final Order order;
  const _OrderDetailDialog({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrder = (ordersAsync.value ?? []).firstWhereOrNull((o) => o.id == order.id) ?? order;
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final orderTransactions = (transactionsAsync.value ?? []).where((t) => t.orderId == order.id).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    final remaining = currentOrder.totalAmount - currentOrder.totalPaid;

    return AlertDialog(
      title: Text('${currentOrder.customerName} - ${currentOrder.itemType}'),
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
                items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) ref.read(repositoryProvider).updateOrderStatus(currentOrder.id, v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MoneyBox(label: 'الإجمالي', value: currentOrder.totalAmount),
                  _MoneyBox(label: 'المدفوع', value: currentOrder.totalPaid, color: AppColors.success),
                  _MoneyBox(label: 'المتبقي', value: remaining, color: remaining > 0 ? AppColors.danger : AppColors.success),
                ],
              ),
              if (remaining > 0) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(context, ref, currentOrder, remaining),
                  icon: const Icon(Icons.add_card_rounded),
                  label: const Text('تسجيل دفعة'),
                ),
              ],
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
}s
