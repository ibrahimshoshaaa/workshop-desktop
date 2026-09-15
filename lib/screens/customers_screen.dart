import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/order_calculations.dart';
import '../core/search_bar.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../providers/data_providers.dart';
import '../services/customer_archive_service.dart';
import '../providers/database_provider.dart';
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
    final name = TextEditingController(text: customer?.name ?? '');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final address = TextEditingController(text: customer?.address ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _PremiumField(controller: name, label: 'اسم العميل', icon: Icons.person_outline_rounded, validator: (v) => v == null || v.trim().isEmpty ? 'الاسم مطلوب' : null),
              const SizedBox(height: 14),
              _PremiumField(controller: phone, label: 'رقم الهاتف', icon: Icons.phone_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'رقم الهاتف مطلوب' : null),
              const SizedBox(height: 14),
              _PremiumField(controller: address, label: 'العنوان', icon: Icons.location_on_outlined),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final repo = ref.read(repositoryProvider);
              if (customer == null) {
                await repo.addCustomer(name: name.text.trim(), phone: phone.text.trim(), address: address.text.trim());
              } else {
                await repo.updateCustomer(customer, name: name.text.trim(), phone: phone.text.trim(), address: address.text.trim());
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _archive(Customer customer) async {
    final db = ref.read(databaseProvider);
    final reason = await CustomerArchiveService(db).getArchiveBlockReason(customer.id);
    if (!mounted) return;
    if (reason != null) {
      await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('لا يمكن أرشفة العميل'), content: Text(reason), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))]));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('أرشفة العميل'),
        content: Text('سيتم نقل "${customer.name}" وكل طلباته المكتملة إلى الأرشيف. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton.icon(icon: const Icon(Icons.archive_rounded), label: const Text('أرشفة'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final count = await CustomerArchiveService(db).archiveCustomer(customer.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت أرشفة العميل مع $count طلب.')));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: LayoutBuilder(builder: (context, c) => Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('العملاء', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
              const SizedBox(height: 4),
              Text('إدارة بيانات العملاء وسجل طلباتهم', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
            ])),
            ElevatedButton.icon(onPressed: () => _showCustomerDialog(context, ref), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('إضافة عميل')),
          ])),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: AppSearchBar(controller: _searchController, hintText: 'ابحث بالاسم أو رقم الهاتف...', onChanged: (v) => setState(() => _query = v), onClear: () => setState(() => _query = '')),
        ),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.wood)),
            error: (e, _) => Center(child: Text('خطأ: $e')),
            data: (customers) {
              final q = normalizeForSearch(_query);
              final filtered = q.isEmpty ? customers : customers.where((c) => normalizeForSearch(c.name).contains(q) || normalizeForSearch(c.phone).contains(q) || normalizeForSearch(c.address).contains(q)).toList();
              if (filtered.isEmpty) return const _EmptyState(icon: Icons.people_outline_rounded, text: 'لا توجد نتائج مطابقة');
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => showDialog(context: context, builder: (_) => CustomerOrdersDialog(customer: c)),
                        leading: CircleAvatar(backgroundColor: AppColors.wood.withValues(alpha: 0.1), child: Text(c.name.isNotEmpty ? c.name[0] : '?', style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold))),
                        title: Row(children: [Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.w800))), const SizedBox(width: 8), Text('#${c.serialNumber}', style: const TextStyle(fontSize: 11, color: AppColors.wood, fontWeight: FontWeight.bold))]),
                        subtitle: Text('${c.phone}${c.address.isNotEmpty ? ' • ${c.address}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Wrap(children: [
                          IconButton(tooltip: 'تعديل', icon: const Icon(Icons.edit_outlined, color: AppColors.navy), onPressed: () => _showCustomerDialog(context, ref, customer: c)),
                          IconButton(tooltip: 'أرشفة', icon: const Icon(Icons.archive_outlined, color: AppColors.danger), onPressed: () => _archive(c)),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class CustomerOrdersDialog extends ConsumerWidget {
  final Customer customer;
  final bool includeArchived;
  const CustomerOrdersDialog({super.key, required this.customer, this.includeArchived = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(ordersProvider).value ?? [];
    final archived = includeArchived ? (ref.watch(archivedOrdersProvider).value ?? []) : const <Order>[];
    final customerOrders = [...active, ...archived].where((o) => o.customerId == customer.id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('طلبات ${customer.name} (#${customer.serialNumber})', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
      content: SizedBox(
        width: 460,
        height: 440,
        child: customerOrders.isEmpty
            ? const _EmptyState(icon: Icons.checkroom_outlined, text: 'لا توجد طلبات لهذا العميل')
            : ListView.builder(
                itemCount: customerOrders.length,
                itemBuilder: (context, index) {
                  final o = customerOrders[index];
                  final archivedOrder = o.isDeleted;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: () => showDialog(context: context, builder: (_) => OrderDetailDialog(order: o)),
                        title: Row(children: [Expanded(child: Text(o.itemType, style: GoogleFonts.cairo(fontWeight: FontWeight.w700))), if (archivedOrder) const Chip(label: Text('أرشيف', style: TextStyle(fontSize: 10))) ]),
                        subtitle: Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))} • ${o.status}'),
                        trailing: Text(o.remaining > 0 ? 'متبقي ${o.remaining.toStringAsFixed(0)}' : 'مكتمل', style: TextStyle(color: o.remaining > 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        if (!includeArchived) ElevatedButton.icon(icon: const Icon(Icons.add_rounded, size: 18), label: const Text('إضافة طلب'), onPressed: () => showAddOrderDialog(context, ref, presetCustomer: customer)),
      ],
    );
  }
}

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  const _PremiumField({required this.controller, required this.label, required this.icon, this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(controller: controller, validator: validator, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.wood), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42, color: Colors.grey.shade300), const SizedBox(height: 12), Text(text, style: GoogleFonts.cairo(color: Colors.grey.shade400))]));
}
