import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database.dart';
import '../data/local_repository.dart';
import '../core/order_calculations.dart';
import '../core/money.dart';
import '../core/calendar_dates.dart';
import '../core/accounting.dart';
import 'database_provider.dart';

final repositoryProvider = Provider<LocalRepository>((ref) {
  return LocalRepository(ref.watch(databaseProvider));
});

final allCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.customers,
  )..where((c) => c.isDeleted.equals(false))).watch();
});
final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).watchCustomers();
});

/// العملاء المؤرشفون - منفصلين عن قائمة العملاء الحالية.
final archivedCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.customers)
        ..where((c) => c.isArchived.equals(true) & c.isDeleted.equals(false))
        ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
      .watch();
});

/// كل الطلبات المؤرشفة، لاستخدامها داخل أرشيف العميل.
final archivedOrdersProvider = StreamProvider<List<Order>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchOrders(archivedOnly: true);
});

final ordersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(databaseProvider).watchOrders();
});

/// Financial history includes archived orders; archive is not a money movement.
final accountingOrdersProvider = StreamProvider<List<Order>>(
  (ref) => ref.watch(databaseProvider).watchOrders(includeArchived: true),
);
final rawOrdersProvider = StreamProvider<List<Order>>(
  (ref) =>
      (ref.watch(databaseProvider).select(ref.watch(databaseProvider).orders)
            ..where((o) => o.isDeleted.equals(false)))
          .watch(),
);
final calendarClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final allTransactionsProvider = StreamProvider<List<PaymentTransaction>>((ref) {
  return ref.watch(databaseProvider).watchAllTransactions();
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(databaseProvider).watchExpenses();
});

class OrderExpenseShare {
  final Expense expense;
  final double shareAmount;
  final int totalOrdersCount;
  const OrderExpenseShare({
    required this.expense,
    required this.shareAmount,
    required this.totalOrdersCount,
  });
}

final orderExpensesProvider = Provider.family<List<OrderExpenseShare>, String>((
  ref,
  orderId,
) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final result = <OrderExpenseShare>[];
  for (final e in expenses) {
    final allocs = e.allocations;
    final match = allocs.where((a) => a.orderId == orderId).toList();
    if (match.isEmpty) continue;
    final shareAmount = match.fold<double>(0, (s, a) => s + a.amount);
    result.add(
      OrderExpenseShare(
        expense: e,
        shareAmount: shareAmount,
        totalOrdersCount: allocs.length,
      ),
    );
  }
  return result;
});

final materialsProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(databaseProvider).watchMaterials();
});

final workersProvider = StreamProvider<List<Worker>>((ref) {
  return ref.watch(databaseProvider).watchWorkers();
});

final workerPaymentsProvider = StreamProvider<List<WorkerPayment>>((ref) {
  return ref.watch(databaseProvider).watchWorkerPayments();
});

final workerPaymentsForWorkerProvider =
    StreamProvider.family<List<WorkerPayment>, String>((ref, workerId) {
      return ref.watch(databaseProvider).watchPaymentsForWorker(workerId);
    });

DateTime workerPeriodAnchor(Worker worker, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (worker.salaryType) {
    case 'weekly':
      final diff = (now.weekday - worker.payWeekday + 7) % 7;
      return CalendarDates.addDays(today, -diff);
    case 'monthly':
      return DateTime(now.year, now.month, 1);
    default:
      return today;
  }
}

bool isWorkerPaidForCurrentPeriod(
  Worker worker,
  List<WorkerPayment> payments,
  DateTime now,
) {
  final anchor = workerPeriodAnchor(worker, now);
  return payments.any(
    (p) =>
        p.workerId == worker.id &&
        CalendarDates.day(
          DateTime.fromMillisecondsSinceEpoch(p.periodStart),
        ).isAtSameMomentAs(anchor),
  );
}

final workersDueTodayProvider = Provider<List<Worker>>((ref) {
  final workers = ref.watch(workersProvider).value ?? [];
  final payments = ref.watch(workerPaymentsProvider).value ?? [];
  final now = ref.watch(calendarClockProvider).value ?? DateTime.now();
  return workers
      .where((w) => !isWorkerPaidForCurrentPeriod(w, payments, now))
      .toList();
});

final debtorOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(accountingOrdersProvider).value ?? [];
  return orders.where((o) => o.remaining > 0).toList()
    ..sort((a, b) => b.remaining.compareTo(a.remaining));
});

final workshopDebtsProvider = StreamProvider<List<WorkshopDebt>>((ref) {
  return ref.watch(databaseProvider).watchWorkshopDebts();
});

final outstandingWorkshopDebtsProvider = Provider<List<WorkshopDebt>>((ref) {
  final debts = ref.watch(workshopDebtsProvider).value ?? [];
  return debts.where((d) => d.remaining > 0).toList()
    ..sort((a, b) => b.remaining.compareTo(a.remaining));
});

final cashTransfersProvider = StreamProvider<List<CashTransfer>>((ref) {
  return ref.watch(databaseProvider).watchCashTransfers();
});

final lowStockMaterialsProvider = Provider<List<MaterialItem>>((ref) {
  final materials = ref.watch(materialsProvider).value ?? [];
  return materials.where((m) => m.quantity <= m.minThreshold).toList();
});

final upcomingDeliveriesProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final now = ref.watch(calendarClockProvider).value ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAhead = CalendarDates.addDays(today, 7);
  return orders.where((o) {
    if (o.status == 'تم التسليم') return false;
    final delivery = DateTime.fromMillisecondsSinceEpoch(o.deliveryDate);
    return !delivery.isBefore(today) && delivery.isBefore(weekAhead);
  }).toList()..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
});

class DashboardStats {
  final double totalRevenue;
  final double totalDebts;
  final double totalExpenses;
  final double netProfit;
  final double cashAvailable;
  final double instapayAvailable;
  final double totalWorkshopDebts;
  DashboardStats({
    required this.totalRevenue,
    required this.totalDebts,
    required this.totalExpenses,
    required this.netProfit,
    required this.cashAvailable,
    required this.instapayAvailable,
    required this.totalWorkshopDebts,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final orders = ref.watch(accountingOrdersProvider).value ?? [];
  final expenses = ref.watch(expensesProvider).value ?? [];
  final transactions = ref.watch(allTransactionsProvider).value ?? [];
  final debts = ref.watch(workshopDebtsProvider).value ?? [];
  final transfers = ref.watch(cashTransfersProvider).value ?? [];
  final totals = AccountingSnapshot(
    orders: orders,
    transactions: transactions,
    expenses: expenses,
    transfers: transfers,
  );
  return DashboardStats(
    totalRevenue: totals.revenue,
    totalDebts: totals.debts,
    totalExpenses: totals.expense,
    netProfit: totals.net,
    cashAvailable: totals.cash,
    instapayAvailable: totals.instapay,
    totalWorkshopDebts: Money.sum(
      debts.where((d) => d.remaining > 0).map((d) => d.remaining),
    ),
  );
});
