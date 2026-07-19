import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../providers/navigation_provider.dart';
import '../core/theme.dart';
import 'revenues_detail_screen.dart';
import 'orders_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final dueWorkers = ref.watch(workersDueTodayProvider);
    final upcomingDeliveries = ref.watch(upcomingDeliveriesProvider);
    final formatter = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'إجمالي الإيرادات',
                  value: formatter.format(stats.totalRevenue),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenuesDetailScreen())),
                ),
                _StatCard(
                  title: 'المديونيات المستحقة',
                  value: formatter.format(stats.totalDebts),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                ),
                _StatCard(
                  title: 'إجمالي المصروفات',
                  value: formatter.format(stats.totalExpenses),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.warning,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 6,
                ),
                _StatCard(
                  title: 'المتاح نقدي (كاش)',
                  value: formatter.format(stats.cashAvailable),
                  icon: Icons.payments_rounded,
                  color: stats.cashAvailable >= 0 ? AppColors.success : AppColors.danger,
                ),
                _StatCard(
                  title: 'المتاح إنستاباي',
                  value: formatter.format(stats.instapayAvailable),
                  icon: Icons.phone_iphone_rounded,
                  color: stats.instapayAvailable >= 0 ? AppColors.navy : AppColors.danger,
                  onTap: () => _showCashTransferDialog(context, ref, stats.instapayAvailable),
                ),
                _StatCard(
                  title: 'مديونيات الورشة (علينا)',
                  value: formatter.format(stats.totalWorkshopDebts),
                  icon: Icons.store_rounded,
                  color: AppColors.danger,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                ),
              ],
            ),
            if (dueWorkers.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.warning.withValues(alpha: 0.1),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: AppColors.warning),
                  title: const Text('النهاردة يوم القبض الأسبوعي', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('مستني تأكيد الدفع: ${dueWorkers.map((w) => w.name).join('، ')}'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 5,
                ),
              ),
            ],
            if (upcomingDeliveries.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: AppColors.navy),
                          const SizedBox(width: 8),
                          const Text('التسليمات القادمة خلال أسبوع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...upcomingDeliveries.map((o) {
                        final delivery = DateTime.fromMillisecondsSinceEpoch(o.deliveryDate);
                        final today = DateTime.now();
                        final daysLeft = DateTime(delivery.year, delivery.month, delivery.day)
                            .difference(DateTime(today.year, today.month, today.day))
                            .inDays;
                        final label = daysLeft == 0 ? 'النهاردة' : (daysLeft == 1 ? 'بكرة' : 'بعد $daysLeft أيام');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: (daysLeft == 0 ? AppColors.danger : AppColors.navy).withValues(alpha: 0.1),
                            child: Icon(Icons.checkroom_rounded, color: daysLeft == 0 ? AppColors.danger : AppColors.navy),
                          ),
                          title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${DateFormat('d/M/yyyy').format(delivery)} • $label'),
                          trailing: const Icon(Icons.chevron_left_rounded),
                          onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(radius: 26, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// سحب رصيد إنستاباي عن طريق الصراف الآلي وتحويله لكاش - بينقل المبلغ
/// من "المتاح إنستاباي" لـ "المتاح نقدي" في الداشبورد. تحت الفورم فيه
/// سجل بآخر العمليات يقدر يحذف منه أي عملية غلط. نفس تصميم تطبيق
/// الموبايل بالظبط
void _showCashTransferDialog(BuildContext context, WidgetRef ref, double availableInstapay) {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  bool isSaving = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('سحب إنستاباي كاش'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتاح حاليًا في إنستاباي: ${availableInstapay.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'المبلغ اللي اتسحب (ج.م)'),
                        validator: (v) {
                          final amount = double.tryParse(v ?? '');
                          if (amount == null || amount <= 0) return 'أدخل مبلغ صحيح';
                          if (amount > availableInstapay) {
                            return 'المبلغ أكبر من المتاح في إنستاباي (${availableInstapay.toStringAsFixed(0)} ج.م)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                const Text('آخر العمليات', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final transfers = ref.watch(cashTransfersProvider).value ?? [];
                    if (transfers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد عمليات سحب مسجّلة بعد', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    }
                    final sorted = [...transfers]..sort((a, b) => b.date.compareTo(a.date));
                    return Column(
                      children: sorted.take(5).map((t) {
                        final date = DateTime.fromMillisecondsSinceEpoch(t.date);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('${t.amount.toStringAsFixed(0)} ج.م'),
                          subtitle: Text(
                            [
                              '${date.day}/${date.month}/${date.year}',
                              if (t.note.isNotEmpty) t.note,
                            ].join(' - '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                            onPressed: () => ref.read(repositoryProvider).deleteCashTransfer(t.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      await ref.read(repositoryProvider).addCashTransfer(
                            amount: double.parse(amountController.text.trim()),
                            note: noteController.text.trim(),
                          );
                      amountController.clear();
                      noteController.clear();
                      setDialogState(() => isSaving = false);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                      }
                      setDialogState(() => isSaving = false);
                    }
                  },
            child: isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('تسجيل السحب'),
          ),
        ],
      ),
    ),
  );
}
