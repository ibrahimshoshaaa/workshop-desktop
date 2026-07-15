import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';
import '../core/order_calculations.dart';
import 'orders_screen.dart' show OrderDetailDialog, showAddOrderDialog;

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});
  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCustomerDialog(BuildContext context, WidgetRef ref, {Customer? customer}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم العميل'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(repositoryProvider);
              if (customer == null) {
                await repo.addCustomer(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
                );
              } else {
                await repo.updateCustomer(
                  customer,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  address: addressController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_rounded), onPressed: () => _showCustomerDialog(context, ref)),
        ],
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'ابحث بالاسم أو رقم الهاتف...',
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(child: Text('لا يوجد عملاء بعد', style: TextStyle(color: Colors.grey)));
                }
                final q = normalizeForSearch(_query);
                final filtered = q.isEmpty
                    ? customers
                    : customers.where((c) {
                        return normalizeForSearch(c.name).contains(q) ||
                            normalizeForSearch(c.phone).contains(q) ||
                            normalizeForSearch(c.address).contains(q);
                      }).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Card(
                      child: ListTile(
                        onTap: () => showDialog(context: context, builder: (context) => _CustomerOrdersDialog(customer: c)),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.wood.withValues(alpha: 0.15),
                          child: Text(c.name.isNotEmpty ? c.name[0] : '?',
                              style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(c.name),
                        subtitle: Text('${c.phone}${c.address.isNotEmpty ? ' - ${c.address}' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showCustomerDialog(context, ref, customer: c)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('حذف العميل'),
                                    content: Text('هل أنت متأكد من حذف "${c.name}"؟'),
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
                                if (confirm == true) await ref.read(repositoryProvider).deleteCustomer(c.id);
                              },
                            ),
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
}

/// ديالوج بيعرض كل طلبات عميل معيّن - بيتفتح لما تدوس على العميل من
/// صفحة العملاء، وبيديك تفاصيل سريعة (الحالة والمتبقي) لكل طلب، ولو
/// دوست على طلب بيفتحلك نفس ديالوج تفاصيل الطلب اللي في صفحة الطلبات
/// (بكل إمكانياته: تغيير الحالة، تسجيل دفعة، تسجيل مصروف... إلخ)
class _CustomerOrdersDialog extends ConsumerWidget {
  final Customer customer;
  const _CustomerOrdersDialog({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final customerOrders = (ordersAsync.value ?? []).where((o) => o.customerId == customer.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AlertDialog(
      title: Text('طلبات ${customer.name}'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: customerOrders.isEmpty
            ? const Center(child: Text('لا توجد طلبات لهذا العميل بعد', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: customerOrders.length,
                itemBuilder: (context, index) {
                  final o = customerOrders[index];
                  final remaining = o.remaining;
                  return Card(
                    child: ListTile(
                      title: Text(o.itemType, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))} | ${o.status}'),
                      trailing: Text(
                        remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                        style: TextStyle(color: remaining > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold),
                      ),
                      onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('إضافة طلب'),
          onPressed: () => showAddOrderDialog(context, ref, presetCustomer: customer),
        ),
      ],
    );
  }
}
