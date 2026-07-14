import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../data/database.dart';
import '../core/theme.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('لا يوجد عملاء بعد', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final c = customers[index];
              return Card(
                child: ListTile(
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
    );
  }
}
