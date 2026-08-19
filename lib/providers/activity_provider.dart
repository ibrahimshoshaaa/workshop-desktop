import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../core/theme.dart';
import 'data_providers.dart';

enum ActivityKind {
  newOrder,
  orderPayment,
  customerRefund,
  expense,
  newCustomer,
  workerPayment,
  cashTransfer,
  workshopDebt,
}

class ActivityItem {
  final DateTime time;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const ActivityItem({
    required this.time,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

final activityLogProvider = Provider<List<ActivityItem>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final transactions = ref.watch(allTransactionsProvider).value ?? [];
  final expenses = ref.watch(expensesProvider).value ?? [];
  final customers = ref.watch(customersProvider).value ?? [];
  final workerPayments = ref.watch(workerPaymentsProvider).value ?? [];
  final cashTransfers = ref.watch(cashTransfersProvider).value ?? [];
  final workshopDebts = ref.watch(workshopDebtsProvider).value ?? [];

  final items = <ActivityItem>[];

  for (final o in orders) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(o.createdAt),
      kind: ActivityKind.newOrder,
      title: 'تم تسجيل طلب جديد',
      subtitle: '${o.customerName} - ${o.itemType}',
      icon: Icons.checkroom_rounded,
      color: AppColors.navy,
    ));
  }

  for (final t in transactions) {
    // ⚠️ لو refund type عندك اسم مختلف من 'refund'، عدل السطر ده
    if (t.paymentType == 'refund') {
      final order = orders.firstWhereOrNull((o) => o.id == t.orderId);
      items.add(ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(t.paymentDate),
        kind: ActivityKind.customerRefund,
        title: 'تم استرجاع فلوس لعميل',
        subtitle: '${order?.customerName ?? 'عميل'} - ${t.amountPaid.abs().toStringAsFixed(0)} ج.م',
        icon: Icons.undo_rounded,
        color: AppColors.wood,
      ));
    } else {
      items.add(ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(t.paymentDate),
        kind: ActivityKind.orderPayment,
        title: 'تم تسجيل دفعة من عميل',
        subtitle: '+${t.amountPaid.toStringAsFixed(0)} ج.م',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ));
    }
  }

  for (final e in expenses) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(e.date),
      kind: ActivityKind.expense,
      title: 'تم تسجيل مصروف',
      subtitle: '-${e.amount.toStringAsFixed(0)} ج.م'
          '${e.description.isNotEmpty ? ' - ${e.description}' : ''}',
      icon: Icons.receipt_long_rounded,
      color: AppColors.danger,
    ));
  }

  for (final c in customers) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
      kind: ActivityKind.newCustomer,
      title: 'تم إضافة عميل جديد',
      subtitle: c.name,
      icon: Icons.person_add_alt_1_rounded,
      color: AppColors.amber,
    ));
  }

  for (final p in workerPayments) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(p.paymentDate),
      kind: ActivityKind.workerPayment,
      title: 'تم صرف مرتب/سلفة',
      subtitle: '${p.workerName} - ${p.amount.toStringAsFixed(0)} ج.م',
      icon: Icons.engineering_rounded,
      color: AppColors.warning,
    ));
  }

  for (final ct in cashTransfers) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(ct.date),
      kind: ActivityKind.cashTransfer,
      title: 'تحويل بين الكاش والإنستاباي',
      subtitle: '${ct.amount.toStringAsFixed(0)} ج.م'
          '${ct.note.isNotEmpty ? ' - ${ct.note}' : ''}',
      icon: Icons.swap_horiz_rounded,
      color: AppColors.wood,
    ));
  }

  for (final d in workshopDebts) {
    items.add(ActivityItem(
      time: DateTime.fromMillisecondsSinceEpoch(d.createdAt),
      kind: ActivityKind.workshopDebt,
      title: 'تم تسجيل دين على الورشة',
      subtitle: '${d.creditorName} - ${d.totalAmount.toStringAsFixed(0)} ج.م',
      icon: Icons.store_rounded,
      color: AppColors.danger,
    ));
  }

  items.sort((a, b) => b.time.compareTo(a.time));
  return items;
});
