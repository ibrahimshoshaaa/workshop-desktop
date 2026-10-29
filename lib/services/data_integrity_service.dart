import 'package:drift/drift.dart';
import '../data/database.dart';
import '../data/local_repository.dart';
import '../core/money.dart';
import '../core/order_calculations.dart';
import '../core/calendar_dates.dart';

class IntegrityIssue {
  IntegrityIssue(this.message, {this.repairOrderId});
  final String message;
  final String? repairOrderId;
}

class DataIntegrityService {
  DataIntegrityService(this.db);
  final AppDatabase db;
  Future<List<IntegrityIssue>> scan() => db.transaction(() async {
    final result = <IntegrityIssue>[];
    void issue(String text, {String? repair}) =>
        result.add(IntegrityIssue(text, repairOrderId: repair));
    final customers = {
      for (final c in await db.select(db.customers).get()) c.id: c,
    };
    final orders = {for (final o in await db.select(db.orders).get()) o.id: o};
    final txs = await (db.select(
      db.paymentTransactions,
    )..where((t) => t.isDeleted.equals(false))).get();
    final expenses = await (db.select(
      db.expenses,
    )..where((e) => e.isDeleted.equals(false))).get();
    final debts = await (db.select(
      db.workshopDebts,
    )..where((d) => d.isDeleted.equals(false))).get();
    final wages = await (db.select(
      db.workerPayments,
    )..where((w) => w.isDeleted.equals(false))).get();
    final expenseById = {for (final e in expenses) e.id: e};
    bool valid(double value) => value.isFinite && value.abs() <= Money.maxValue;
    for (final tx in txs) {
      if (orders[tx.orderId] == null ||
          orders[tx.orderId]!.isDeleted ||
          orders[tx.orderId]!.customerId != tx.customerId)
        issue('دفعة ${tx.id}: الطلب أو العميل غير متوافق.');
      if (!valid(tx.amountPaid) ||
          tx.amountPaid == 0 ||
          ((tx.paymentType == 'refund') != (tx.amountPaid < 0)))
        issue('دفعة ${tx.id}: مبلغ أو إشارة غير صحيحة.');
      if (valid(tx.amountPaid) &&
          (tx.amountPaid - Money.amount(Money.cents(tx.amountPaid))).abs() >
              0.000001)
        issue('دفعة ${tx.id}: كسور قرش تحتاج مراجعة.');
      if (!const ['completed', 'pending'].contains(tx.status))
        issue('دفعة ${tx.id}: حالة غير معروفة.');
    }
    for (final order in orders.values.where((o) => !o.isDeleted)) {
      if (customers[order.customerId] == null ||
          customers[order.customerId]!.isDeleted)
        issue(
          'طلب ${order.id} (${order.customerName}): العميل غير موجود أو محذوف.',
        );
      if (![
            order.totalAmount,
            order.discountAmount,
            order.totalPaid,
          ].every(valid) ||
          order.totalAmount < 0 ||
          order.discountAmount < 0 ||
          order.discountAmount > order.totalAmount) {
        issue('طلب ${order.id}: مبالغ الاتفاق أو الخصم غير صالحة.');
        continue;
      }
      final payments = txs.where((t) => t.orderId == order.id).toList();
      if (payments.any((t) => !valid(t.amountPaid))) continue;
      final paid = Money.sum(
        payments.where((t) => t.status == 'completed').map((t) => t.amountPaid),
      );
      if (paid < 0) issue('طلب ${order.id}: مجموع المقبوض أقل من رد الأموال.');
      if (payments.isEmpty && Money.cents(order.totalPaid) != 0)
        issue(
          'طلب ${order.id}: مدفوع محفوظ بدون دفتر دفعات؛ يلزم مراجعة المصدر.',
        );
      else if (Money.cents(order.totalPaid) != Money.cents(paid))
        issue(
          'طلب ${order.id}: الإجمالي المخزن يختلف عن الدفعات المكتملة. العرض محسوب من الدفعات.',
          repair: order.id,
        );
      final overpaid = Money.subtract(paid, order.effectiveTotal);
      final linked = debts.where((d) => d.orderId == order.id).toList();
      if (linked.length > 1 || linked.any((d) => d.paidAmount != 0))
        issue('طلب ${order.id}: مديونية عميل قديمة أو مكررة تحتاج مراجعة.');
      else if ((overpaid > 0 &&
              (linked.isEmpty ||
                  Money.cents(linked.single.totalAmount) !=
                      Money.cents(overpaid))) ||
          (overpaid <= 0 && linked.isNotEmpty)) {
        issue(
          'طلب ${order.id}: مديونية الزيادة المدفوعة تحتاج تحديثًا من السجل.',
          repair: payments.isNotEmpty && paid >= 0 ? order.id : null,
        );
      }
      if (order.isArchived &&
          (Money.cents(Money.subtract(order.effectiveTotal, paid)) != 0 ||
              payments.any((t) => t.status == 'pending')))
        issue('طلب مؤرشف ${order.id}: عليه رصيد أو دفعة معلقة.');
      if (order.deliveryDate <= 0)
        issue('طلب ${order.id}: موعد تسليم غير محدد.');
    }
    for (final expense in expenses) {
      if (!valid(expense.amount) || expense.amount <= 0) {
        issue('مصروف ${expense.id}: مبلغ غير صالح.');
        continue;
      }
      final allocations = expense.allocations;
      if (allocations.isNotEmpty &&
          (allocations.any((a) => !valid(a.amount) || a.amount < 0) ||
              Money.cents(Money.sum(allocations.map((a) => a.amount))) !=
                  Money.cents(expense.amount)))
        issue('مصروف ${expense.id}: تقسيم المبلغ لا يساوي الإجمالي.');
      for (final allocation in allocations) {
        if (orders[allocation.orderId] == null ||
            orders[allocation.orderId]!.customerId != allocation.customerId)
          issue('مصروف ${expense.id}: طلب أو عميل التقسيم غير صحيح.');
      }
      if (expense.workshopDebtId != null &&
          !debts.any((d) => d.id == expense.workshopDebtId))
        issue('مصروف ${expense.id}: المديونية المرتبطة غير موجودة.');
    }
    final periods = <String>{};
    for (final wage in wages) {
      if (wage.periodStart.abs() > 8640000000000000) {
        issue('صرف عامل ${wage.id}: تاريخ غير صالح.');
        continue;
      }
      final day = CalendarDates.day(
        DateTime.fromMillisecondsSinceEpoch(wage.periodStart),
      );
      final key = '${wage.workerId}/${day.toIso8601String()}';
      if (!periods.add(key))
        issue(
          'عامل ${wage.workerName}: صرف مكرر لنفس فترة ${day.year}/${day.month}/${day.day}.',
        );
      final expense = expenseById[wage.expenseId];
      if (expense == null ||
          !valid(wage.amount) ||
          !valid(expense.amount) ||
          Money.cents(wage.amount) != Money.cents(expense.amount))
        issue('صرف عامل ${wage.id}: المصروف المرتبط ناقص أو مختلف.');
    }
    for (final debt in debts) {
      if (![debt.totalAmount, debt.paidAmount].every(valid) ||
          debt.totalAmount < 0 ||
          debt.paidAmount < 0 ||
          debt.remaining < 0) {
        issue('مديونية ${debt.id}: الإجمالي أو المسدد غير صحيح.');
        continue;
      }
      if (debt.orderId.isEmpty) {
        final paidExpenses = expenses.where(
          (e) => e.workshopDebtId == debt.id && valid(e.amount),
        );
        if (Money.cents(Money.sum(paidExpenses.map((e) => e.amount))) !=
            Money.cents(debt.paidAmount))
          issue(
            'مديونية ${debt.id}: المسدد لا يطابق مصروفات السداد؛ راجع المصدر قبل أي تصحيح.',
          );
      }
    }
    return result;
  });

  /// Only derived caches are rebuilt. Never invent/delete a payment to match a
  /// cached number, and keep ambiguous legacy histories for explicit review.
  Future<int> repairDerivedOrders(List<String> ids) => db.transaction(() async {
    final repo = LocalRepository(db);
    for (final id in ids.toSet()) {
      await repo.repairDerivedOrder(id);
    }
    return ids.toSet().length;
  });
}
