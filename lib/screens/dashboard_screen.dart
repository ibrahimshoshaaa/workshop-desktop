import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../core/theme.dart';
import 'revenues_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final lowStock = ref.watch(lowStockMaterialsProvider);
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RevenuesDetailScreen()),
                    );
                  },
                ),
                _StatCard(
                  title: 'إجمالي المديونيات',
                  value: formatter.format(stats.totalDebts),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
                _StatCard(
                  title: 'إجمالي المصروفات',
                  value: formatter.format(stats.totalExpenses),
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.warning,
                ),
                _StatCard(
                  title: 'صافي الربح',
                  value: formatter.format(stats.netProfit),
                  icon: Icons.account_balance_rounded,
                  color: stats.netProfit >= 0 ? AppColors.navy : AppColors.danger,
                ),
              ],
            ),
            if (lowStock.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                color: AppColors.danger.withValues(alpha: 0.08),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  title: const Text('خامات على وشك النفاد', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(lowStock.map((m) => m.name).join('، ')),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
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
      ),
    );
  }
}
