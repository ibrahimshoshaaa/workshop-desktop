import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/calendar_dates.dart';
import '../core/money.dart';

class FinancialReportData {
  FinancialReportData(
    this.orders,
    this.expenses,
    this.transactions,
    this.transfers,
  );
  final List<Order> orders;
  final List<Expense> expenses;
  final List<PaymentTransaction> transactions;
  final List<CashTransfer> transfers;
  static Future<FinancialReportData> load(
    AppDatabase db,
    DateTime from,
    DateTime through, {
    bool includeArchived = false,
  }) => db.transaction(() async {
    final txs = await (db.select(
      db.paymentTransactions,
    )..where((t) => t.isDeleted.equals(false))).get();
    final paid = <String, List<double>>{};
    for (final tx in txs.where((t) => t.status == 'completed')) {
      (paid[tx.orderId] ??= []).add(tx.amountPaid);
    }
    final rawOrders = await (db.select(
      db.orders,
    )..where((o) => o.isDeleted.equals(false))).get();
    final orders = rawOrders
        .where((o) => includeArchived || !o.isArchived)
        .map((o) => o.copyWith(totalPaid: Money.sum(paid[o.id] ?? [])))
        .toList();
    final orderIds = orders.map((o) => o.id).toSet();
    final expenses = await (db.select(
      db.expenses,
    )..where((e) => e.isDeleted.equals(false))).get();
    final transfers = await (db.select(
      db.cashTransfers,
    )..where((t) => t.isDeleted.equals(false))).get();
    return FinancialReportData(
      orders,
      expenses
          .where((e) => CalendarDates.contains(e.date, from, through))
          .toList(),
      txs
          .where((t) => orderIds.contains(t.orderId) &&
              CalendarDates.contains(t.paymentDate, from, through))
          .toList(),
      transfers
          .where((t) => CalendarDates.contains(t.date, from, through))
          .toList(),
    );
  });
}
