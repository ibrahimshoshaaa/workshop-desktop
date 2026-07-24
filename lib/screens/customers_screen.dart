import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/order_calculations.dart';
import '../core/search_bar.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../providers/data_providers.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PremiumField(controller: nameController, label: 'اسم العميل', icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
                const SizedBox(height: 14),
                _PremiumField(controller: phoneController, label: 'رقم الهاتف', icon: Icons.phone_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null),
                const SizedBox(height: 14),
                _PremiumField(controller: addressController, label: 'العنوان', icon: Icons.location_on_outlined),
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

    return Container(
      color: const Color(0xFFFAF6F0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: _PageHeader(
              title: 'العملاء',
              subtitle: 'إدارة بيانات العملاء وسجل طلباتهم',
              icon: Icons.people_alt_rounded,
              badge: customersAsync.value != null ? '${customersAsync.value!.length} عميل' : null,
              actionLabel: 'إضافة عميل',
              actionIcon: Icons.person_add_alt_1_rounded,
              onAction: () => _showCustomerDialog(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: _HoverCard(
              borderRadius: BorderRadius.circular(16),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'ابحث بالاسم أو رقم الهاتف...',
                onChanged: (v) => setState(() => _query = v),
                onClear: () => setState(() => _query = ''),
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const _EmptyState(icon: Icons.people_outline_rounded, text: 'لا يوجد عملاء بعد');
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
                  return const _EmptyState(icon: Icons.search_off_rounded, text: 'لا توجد نتائج مطابقة');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CustomerRow(
                        customer: c,
                        onTap: () => showDialog(context: context, builder: (context) => CustomerOrdersDialog(customer: c)),
                        onEdit: () => _showCustomerDialog(context, ref, customer: c),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

class _CustomerRow extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CustomerRow({required this.customer, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return _HoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.wood.withValues(alpha: 0.12),
              child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.wood, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(c.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text('#${c.serialNumber}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.wood, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.phone}${c.address.isNotEmpty ? ' • ${c.address}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.navy),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
              onPressed: onDelete,
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

/// ديالوج بيعرض كل طلبات عميل معيّن - بيتفتح لما تدوس على العميل من
/// صفحة العملاء، وبيديك تفاصيل سريعة (الحالة والمتبقي) لكل طلب، ولو
/// دوست على طلب بيفتحلك نفس ديالوج تفاصيل الطلب اللي في صفحة الطلبات
/// (بكل إمكانياته: تغيير الحالة، تسجيل دفعة، تسجيل مصروف... إلخ)
class CustomerOrdersDialog extends ConsumerWidget {
  final Customer customer;
  const CustomerOrdersDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final customerOrders = (ordersAsync.value ?? []).where((o) => o.customerId == customer.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('طلبات ${customer.name} (#${customer.serialNumber})',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
      content: SizedBox(
        width: 440,
        height: 440,
        child: customerOrders.isEmpty
            ? const _EmptyState(icon: Icons.checkroom_outlined, text: 'لا توجد طلبات لهذا العميل بعد')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: customerOrders.length,
                itemBuilder: (context, index) {
                  final o = customerOrders[index];
                  final remaining = o.remaining;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HoverCard(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.itemType, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))} • ${o.status}',
                                    style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              remaining > 0 ? 'متبقي ${remaining.toStringAsFixed(0)}' : 'مكتمل',
                              style: TextStyle(
                                color: remaining > 0 ? AppColors.danger : AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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

// ==================== الويدجت المشتركة (نفس أسلوب الداشبورد) ====================

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

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  const _PremiumField({required this.controller, required this.label, required this.icon, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.wood),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.wood, width: 1.5)),
      ),
    );
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
          Icon(icon, size: 42, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.cairo(fontSize: 13.5, color: Colors.grey.shade400)),
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
