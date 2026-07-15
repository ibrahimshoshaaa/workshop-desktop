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
                  title: ' إجمالي المديونيات المستحقه',
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
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 5,
                ),
                _StatCard(
                  title: 'المبلغ المتاح في الخزنة',
                  value: formatter.format(stats.netProfit),
                  icon: Icons.account_balance_rounded,
                  color: stats.netProfit >= 0 ? AppColors.navy : AppColors.danger,
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
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
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
