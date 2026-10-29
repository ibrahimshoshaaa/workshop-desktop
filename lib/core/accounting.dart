import '../data/database.dart';
import 'money.dart';
import 'order_calculations.dart';
import 'calendar_dates.dart';

class AccountingSnapshot {
  AccountingSnapshot({
    required List<Order> orders,
    required List<PaymentTransaction> transactions,
    required List<Expense> expenses,
    List<CashTransfer> transfers = const [],
    DateTime? from,
    DateTime? through,
  }) {
    final liveIds = orders.where((o) => !o.isDeleted).map((o) => o.id).toSet();
    bool inPeriod(int date) =>
        from == null ||
        through == null ||
        CalendarDates.contains(date, from, through);
    payments = transactions
        .where(
          (t) =>
              !t.isDeleted &&
              t.status == 'completed' &&
              liveIds.contains(t.orderId) &&
              inPeriod(t.paymentDate),
        )
        .toList();
    final validExpenses = expenses
        .where((e) => !e.isDeleted && inPeriod(e.date))
        .toList();
    final validTransfers = transfers
        .where((t) => !t.isDeleted && inPeriod(t.date))
        .toList();
    revenue = Money.sum(payments.map((t) => t.amountPaid));
    expense = Money.sum(validExpenses.map((e) => e.amount));
    net = Money.subtract(revenue, expense);
    double byMethod(String method) => Money.subtract(
      Money.sum(
        payments
            .where((t) => t.paymentMethod == method)
            .map((t) => t.amountPaid),
      ),
      Money.sum(
        validExpenses
            .where((e) => e.paymentMethod == method)
            .map((e) => e.amount),
      ),
    );
    final moved = Money.sum(validTransfers.map((t) => t.amount));
    cash = Money.sum([byMethod('cash'), moved]);
    instapay = Money.subtract(byMethod('instapay'), moved);
    debts = Money.sum(
      orders
          .where((o) => !o.isDeleted && o.remaining > 0)
          .map((o) => o.remaining),
    );
    for (final tx in payments) {
      paidByOrder[tx.orderId] = Money.sum([
        paidByOrder[tx.orderId] ?? 0,
        tx.amountPaid,
      ]);
    }
  }
  late final List<PaymentTransaction> payments;
  late final double revenue, expense, net, cash, instapay, debts;
  final Map<String, double> paidByOrder = {};
}
