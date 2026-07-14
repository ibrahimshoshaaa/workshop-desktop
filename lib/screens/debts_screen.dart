import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../core/theme.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtors = ref.watch(debtorOrdersProvider);
    final totalDebt = debtors.fold<double>(0, (s, o) => s + (o.totalAmount - o.totalPaid));

    return Scaffold(
      appBar: AppBar(title: const Text('المديونيات'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: debtors.isEmpty
          ? const Center(child: Text('لا توجد مديونيات حاليًا 🎉', style: TextStyle(color: Colors.grey, fontSize: 16)))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('إجمالي المديونيات المستحقة', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('${totalDebt.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: debtors.length,
                    itemBuilder: (context, index) {
                      final o = debtors[index];
                      final remaining = o.totalAmount - o.totalPaid;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0x1AB3261E), child: Icon(Icons.priority_high_rounded, color: AppColors.danger)),
                          title: Text('${o.customerName} - ${o.itemType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('تسليم: ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}'),
                          trailing: Text('${remaining.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
