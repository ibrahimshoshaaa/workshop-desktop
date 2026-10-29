import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_desktop/core/accounting.dart';
import 'package:workshop_desktop/core/calendar_dates.dart';
import 'package:workshop_desktop/core/money.dart';
import 'package:workshop_desktop/core/order_calculations.dart';
import 'package:workshop_desktop/data/database.dart';
import 'package:workshop_desktop/data/local_repository.dart';
import 'package:workshop_desktop/providers/data_providers.dart';
import 'package:workshop_desktop/services/customer_archive_service.dart';
import 'package:workshop_desktop/services/data_integrity_service.dart';
import 'package:workshop_desktop/services/financial_report_data.dart';
import 'package:workshop_desktop/services/backup_service.dart';
import 'package:workshop_desktop/services/local_paths.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LocalRepository repo;
  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repo = LocalRepository(db);
  });
  tearDown(() async {
    await db.close();
  });
  Future<Order> order({double total = 1000, double deposit = 0}) async {
    await repo.addCustomer(name: 'عميل', phone: '01000000000', address: '');
    final customer = (await db.select(db.customers).get()).last;
    final id = await repo.addOrder(
      customerId: customer.id,
      customerName: customer.name,
      itemType: 'كنبة',
      details: '',
      totalAmount: total,
      initialDeposit: deposit,
      deliveryDate: DateTime(2030, 1, 10),
    );
    return (db.select(db.orders)..where((o) => o.id.equals(id))).getSingle();
  }

  Future<Order> fresh(String id) =>
      (db.select(db.orders)..where((o) => o.id.equals(id))).getSingle();
  Future<String> pay(
    Order o,
    double amount, {
    String status = 'completed',
    String method = 'cash',
    String type = 'installment',
  }) => repo.addPayment(
    orderId: o.id,
    customerId: o.customerId,
    amount: amount,
    paymentType: type,
    status: status,
    paymentMethod: method,
  );
  Future<AccountingSnapshot> totals() async => AccountingSnapshot(
    orders: await db.watchOrders(includeArchived: true).first,
    transactions: await db.select(db.paymentTransactions).get(),
    expenses: await db.select(db.expenses).get(),
    transfers: await db.select(db.cashTransfers).get(),
  );
  Future<Worker> worker() async {
    await repo.addWorker(
      name: 'عامل',
      jobTitle: 'تنجيد',
      salaryType: 'weekly',
      salaryAmount: 100,
    );
    return (await db.select(db.workers).get()).single;
  }

  Future<WorkshopDebt> debt() async {
    await repo.addWorkshopDebt(creditorName: 'مورد', totalAmount: 1000);
    return (await db.select(db.workshopDebts).get()).single;
  }

  test('money keeps fractional EGP and splits every piastre exactly', () {
    expect(Money.sum([0.1, 0.2]), 0.3);
    expect(Money.subtract(0.3, Money.sum([0.1, 0.2])), 0);
    expect(Money.split(1, 3), [0.34, 0.33, 0.33]);
    expect(Money.sum(Money.split(0.01, 3)), 0.01);
    expect(Money.parse('١٬٢٣٤٫٥٦'), 1234.56);
    expect(Money.parse('١٢,٥٠'), 12.5);
    for (final text in ['NaN', 'Infinity', '1e6', '1.001', 'abc']) {
      expect(Money.tryParse(text), isNull);
    }
    expect(() => Money.require(0.0000001), throwsStateError);
  });
  test(
    'pending money is excluded until settlement and recognition uses settlement time',
    () async {
      final o = await order();
      final tx = await pay(o, 200, status: 'pending');
      await db.updateTransactionFields(
        PaymentTransactionsCompanion(
          id: Value(tx),
          paymentDate: Value(DateTime(2020).millisecondsSinceEpoch),
        ),
      );
      expect((await fresh(o.id)).totalPaid, 0);
      expect((await totals()).cash, 0);
      final before = DateTime.now().millisecondsSinceEpoch;
      await repo.updatePaymentStatus(tx, 'completed');
      expect((await fresh(o.id)).totalPaid, 200);
      expect((await totals()).cash, 200);
      final settled = (await db.select(db.paymentTransactions).get()).single;
      expect(settled.paymentDate, greaterThanOrEqualTo(before));
      await repo.updatePaymentStatus(tx, 'pending');
      expect((await totals()).revenue, 0);
      expect((await fresh(o.id)).remaining, 1000);
    },
  );
  test('archive and restore never alter revenue or either wallet', () async {
    final o = await order(total: 100);
    await pay(o, 100, method: 'instapay');
    await repo.updateOrderStatus(o.id, 'تم التسليم');
    final before = await totals();
    await CustomerArchiveService(db).archiveCustomer(o.customerId);
    expect(await db.watchOrders().first, isEmpty);
    final after = await totals();
    expect(after.revenue, before.revenue);
    expect(after.instapay, before.instapay);
    await CustomerArchiveService(db).reactivateCustomer(o.customerId);
    expect((await totals()).instapay, 100);
  });
  test(
    'archive rejects a pending payment and money still owed to the customer',
    () async {
      final o = await order(total: 0);
      await pay(o, 5, status: 'pending');
      await repo.updateOrderStatus(o.id, 'تم التسليم');
      await expectLater(
        CustomerArchiveService(db).archiveCustomer(o.customerId),
        throwsStateError,
      );
      final tx = (await db.select(db.paymentTransactions).get()).single;
      await repo.updatePaymentStatus(tx.id, 'completed');
      await expectLater(
        CustomerArchiveService(db).archiveCustomer(o.customerId),
        throwsStateError,
      );
    },
  );
  test('payments in piastres settle exactly with no phantom debt', () async {
    final o = await order(total: 0.3);
    await pay(o, 0.1);
    await pay(o, 0.2);
    expect((await fresh(o.id)).remaining, 0);
    await repo.updateOrderStatus(o.id, 'تم التسليم');
    await CustomerArchiveService(db).archiveCustomer(o.customerId);
    expect((await totals()).revenue, 0.3);
  });
  test(
    'a stale order snapshot cannot erase a payment when changing the price or discount',
    () async {
      final stale = await order(total: 100);
      await pay(stale, 120);
      await repo.setOrderDiscount(stale, discountAmount: 10);
      expect((await fresh(stale.id)).totalPaid, 120);
      var liability = (await (db.select(
        db.workshopDebts,
      )..where((d) => d.isDeleted.equals(false))).get()).single;
      expect(liability.remaining, 30);
      await repo.updateOrder(
        stale,
        itemType: 'كنبة',
        details: 'تعديل',
        totalAmount: 110,
        deliveryDate: DateTime(2030),
      );
      liability = (await (db.select(
        db.workshopDebts,
      )..where((d) => d.isDeleted.equals(false))).get()).single;
      expect(liability.remaining, 20);
    },
  );
  test(
    'refund reduces revenue once and settles the linked liability without a second expense',
    () async {
      final o = await order(total: 100);
      await pay(o, 130);
      final liability = (await db.select(db.workshopDebts).get()).single;
      await repo.payWorkshopDebt(
        debt: liability,
        amount: 20,
        paymentMethod: 'cash',
      );
      expect((await totals()).cash, 110);
      expect((await db.select(db.expenses).get()), isEmpty);
      expect((await fresh(o.id)).totalPaid, 110);
      final live = (await (db.select(
        db.workshopDebts,
      )..where((d) => d.isDeleted.equals(false))).get()).single;
      expect(live.remaining, 10);
      await expectLater(
        repo.payWorkshopDebt(
          debt: liability,
          amount: 20,
          paymentMethod: 'cash',
        ),
        throwsStateError,
      );
      expect((await totals()).cash, 110);
    },
  );
  test(
    'debt installments accumulate from current state despite a stale dialog snapshot',
    () async {
      final original = await debt();
      await repo.payWorkshopDebt(
        debt: original,
        amount: 200,
        paymentMethod: 'cash',
      );
      await repo.payWorkshopDebt(
        debt: original,
        amount: 300,
        paymentMethod: 'cash',
      );
      expect((await db.select(db.workshopDebts).get()).single.paidAmount, 500);
      expect(
        Money.sum((await db.select(db.expenses).get()).map((e) => e.amount)),
        500,
      );
      await expectLater(
        repo.payWorkshopDebt(
          debt: original,
          amount: 600,
          paymentMethod: 'cash',
        ),
        throwsStateError,
      );
      expect((await db.select(db.expenses).get()).length, 2);
    },
  );
  test(
    'editing or deleting a debt expense keeps the paid debt consistent',
    () async {
      final d = await debt();
      await repo.payWorkshopDebt(debt: d, amount: 200, paymentMethod: 'cash');
      final e = (await db.select(db.expenses).get()).single;
      await repo.updateExpense(
        e,
        amount: 150,
        category: e.category,
        description: '',
        date: DateTime.now(),
        paymentMethod: 'cash',
      );
      expect((await db.select(db.workshopDebts).get()).single.paidAmount, 150);
      await repo.deleteExpense(e.id);
      expect((await db.select(db.workshopDebts).get()).single.paidAmount, 0);
    },
  );
  test(
    'a salary period can be paid only once even with concurrent confirmations',
    () async {
      final w = await worker();
      final period = CalendarDates.day(DateTime.now());
      final outcomes = await Future.wait(
        List.generate(
          2,
          (_) => repo
              .confirmWorkerPayment(worker: w, amount: 100, periodStart: period)
              .then<Object>((_) => true, onError: (Object e) => e),
        ),
      );
      expect(outcomes.where((v) => v == true).length, 1);
      expect(outcomes.whereType<StateError>().length, 1);
      expect((await db.select(db.expenses).get()).length, 1);
      expect((await db.select(db.workerPayments).get()).length, 1);
    },
  );
  test(
    'salary expense correction and removal update the linked wage record',
    () async {
      final w = await worker();
      await repo.confirmWorkerPayment(
        worker: w,
        amount: 100,
        periodStart: DateTime.now(),
      );
      final e = (await db.select(db.expenses).get()).single;
      await repo.updateExpense(
        e,
        amount: 120,
        category: 'wages',
        description: '',
        date: DateTime.now(),
        paymentMethod: 'cash',
      );
      expect((await db.select(db.workerPayments).get()).single.amount, 120);
      await repo.deleteExpense(e.id);
      expect(
        (await (db.select(
          db.workerPayments,
        )..where((p) => p.isDeleted.equals(false))).get()),
        isEmpty,
      );
    },
  );
  test(
    'paid orders and paid debts cannot be deleted to remove their cash movements',
    () async {
      final o = await order();
      await pay(o, 100);
      await expectLater(repo.deleteOrder(o.id), throwsStateError);
      final d = await debt();
      await repo.payWorkshopDebt(debt: d, amount: 50, paymentMethod: 'cash');
      await expectLater(repo.deleteWorkshopDebt(d.id), throwsStateError);
      expect((await totals()).revenue, 100);
    },
  );
  test(
    'payment edits cannot target another order and the last payment can be corrected by deletion',
    () async {
      final a = await order();
      final b = await order();
      final tx = await pay(a, 50);
      await expectLater(
        repo.updatePayment(b.id, tx, newAmount: 100),
        throwsStateError,
      );
      await expectLater(repo.deletePayment(b.id, tx), throwsStateError);
      expect((await fresh(a.id)).totalPaid, 50);
      await repo.deletePayment(a.id, tx);
      expect((await fresh(a.id)).totalPaid, 0);
    },
  );
  test(
    'a received payment cannot be unconfirmed below money already refunded',
    () async {
      final o = await order(total: 100);
      final tx = await pay(o, 120);
      await pay(o, -20, type: 'refund');
      await expectLater(
        repo.updatePaymentStatus(tx, 'pending'),
        throwsStateError,
      );
      await expectLater(repo.deletePayment(o.id, tx), throwsStateError);
      expect((await totals()).revenue, 100);
    },
  );
  test(
    'rejects negative agreements, excessive discounts, invalid money and archived writes',
    () async {
      final o = await order();
      for (final amount in [double.nan, double.infinity, 0.001, -2.0]) {
        await expectLater(pay(o, amount), throwsStateError);
      }
      await expectLater(
        repo.setOrderDiscount(o, discountAmount: 1001),
        throwsStateError,
      );
      await repo.setOrderDiscount(o, discountAmount: 1000);
      await expectLater(
        repo.updateOrder(
          o,
          itemType: 'كنبة',
          details: '',
          totalAmount: -1,
          deliveryDate: DateTime.now(),
        ),
        throwsStateError,
      );
      await repo.updateOrderStatus(o.id, 'تم التسليم');
      await CustomerArchiveService(db).archiveCustomer(o.customerId);
      await expectLater(pay(o, 1), throwsStateError);
      await expectLater(
        repo.updateCustomer(
          (await db.select(db.customers).get()).first,
          name: 'اسم',
          phone: '1',
          address: '',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'old stale image snapshots neither resurrect removed images nor erase added ones',
    () async {
      final o = await order();
      await repo.addImagesToOrder(o, ['a', 'b']);
      await repo.removeImageFromOrder(o, 'a');
      await repo.addImagesToOrder(o, ['c']);
      expect((await fresh(o.id)).imagesJson, '["b","c"]');
      await repo.updateOrder(
        o,
        itemType: 'كنبة',
        details: '',
        totalAmount: 1000,
        deliveryDate: DateTime.now(),
        removedImages: ['b'],
        addedImages: ['d'],
      );
      expect((await fresh(o.id)).imagesJson, '["c","d"]');
    },
  );
  test(
    'expense allocations account for every piastre and reject missing or mismatched orders',
    () async {
      final a = await order();
      final b = await order();
      final c = await order();
      final orders = [a, b, c];
      final shares = Money.split(1, 3);
      final allocations = List.generate(
        3,
        (i) => ExpenseOrderAllocation(
          orderId: orders[i].id,
          customerId: orders[i].customerId,
          customerName: '',
          amount: shares[i],
        ),
      );
      await repo.addExpense(
        amount: 1,
        category: 'fabric',
        description: '',
        date: DateTime.now(),
        paymentMethod: 'cash',
        orderAllocations: allocations,
      );
      expect(
        Money.sum(
          (await db.select(db.expenses).get()).single.allocations.map(
            (a) => a.amount,
          ),
        ),
        1,
      );
      await expectLater(
        repo.addExpense(
          amount: 2,
          category: 'fabric',
          description: '',
          date: DateTime.now(),
          paymentMethod: 'cash',
          orderAllocations: allocations,
        ),
        throwsStateError,
      );
      expect((await db.select(db.expenses).get()).length, 1);
    },
  );
  test(
    'cash transfers move wallets once, preserve net flow, and reject overdrawing current instapay',
    () async {
      final o = await order(total: 100);
      await pay(o, 100, method: 'instapay');
      await repo.addCashTransfer(amount: 30);
      final t = await totals();
      expect(t.cash, 30);
      expect(t.instapay, 70);
      expect(t.revenue, 100);
      expect(t.expense, 0);
      await expectLater(repo.addCashTransfer(amount: 80), throwsStateError);
      expect((await db.select(db.cashTransfers).get()).length, 1);
    },
  );
  test(
    'calendar reports include midnight and late-day payments on orders created in an earlier period',
    () async {
      final o = await order(total: 100);
      await db.updateOrderFields(
        OrdersCompanion(
          id: Value(o.id),
          createdAt: Value(DateTime(2020).millisecondsSinceEpoch),
        ),
      );
      final from = DateTime(2026, 10, 29, 15);
      final first = await pay(o, 10);
      final last = await pay(o, 20);
      final next = await pay(o, 30);
      for (final entry in {
        first: DateTime(2026, 10, 29),
        last: DateTime(2026, 10, 29, 23, 59, 59, 999),
        next: DateTime(2026, 10, 30),
      }.entries) {
        await db.updateTransactionFields(
          PaymentTransactionsCompanion(
            id: Value(entry.key),
            paymentDate: Value(entry.value.millisecondsSinceEpoch),
          ),
        );
      }
      final data = await FinancialReportData.load(db, from, from);
      final report = AccountingSnapshot(
        orders: data.orders,
        transactions: data.transactions,
        expenses: data.expenses,
        transfers: data.transfers,
      );
      expect(report.revenue, 30);
      expect(data.transactions.length, 2);
      expect(data.orders.single.totalPaid, 60);
      expect(data.orders.single.remaining, 40);
    },
  );
  test(
    'payroll calendar anchors stay at local midnight across the Egypt DST boundary',
    () async {
      final w = (await worker()).copyWith(payWeekday: DateTime.tuesday);
      final anchor = workerPeriodAnchor(w, DateTime(2026, 11, 2));
      expect(anchor, DateTime(2026, 10, 27));
      expect(anchor.hour, 0);
      final old = WorkerPayment(
        id: 'p',
        workerId: w.id,
        workerName: w.name,
        amount: 100,
        paymentDate: anchor.millisecondsSinceEpoch,
        periodStart: DateTime(2026, 10, 27, 1).millisecondsSinceEpoch,
        expenseId: null,
        updatedAt: 0,
        isDeleted: false,
        dirty: false,
      );
      expect(
        isWorkerPaidForCurrentPeriod(w, [old], DateTime(2026, 11, 2)),
        isTrue,
      );
    },
  );
  test(
    'material adjustments read current quantity and reject negative resulting stock',
    () async {
      await repo.addMaterial(
        name: 'قماش',
        unit: 'متر',
        quantity: 10,
        minThreshold: 1,
      );
      final m = (await db.select(db.materialItems).get()).single;
      await repo.adjustMaterialQuantity(m, -2);
      await repo.adjustMaterialQuantity(m, -3);
      expect((await db.select(db.materialItems).get()).single.quantity, 5);
      await expectLater(repo.adjustMaterialQuantity(m, -6), throwsStateError);
    },
  );
  test(
    'integrity scan preserves unexplained legacy paid amounts instead of inventing payments',
    () async {
      final o = await order();
      await db.updateOrderFields(
        OrdersCompanion(id: Value(o.id), totalPaid: const Value(500)),
      );
      final issues = await DataIntegrityService(db).scan();
      expect(issues.any((i) => i.message.contains('بدون دفتر')), isTrue);
      await expectLater(repo.repairDerivedOrder(o.id), throwsStateError);
      expect((await fresh(o.id)).totalPaid, 500);
      expect(await db.select(db.paymentTransactions).get(), isEmpty);
    },
  );
  test(
    'derived totals repair uses the settled ledger without altering original payments',
    () async {
      final o = await order();
      await pay(o, 100);
      await pay(o, 200, status: 'pending');
      await db.updateOrderFields(
        OrdersCompanion(id: Value(o.id), totalPaid: const Value(300)),
      );
      final service = DataIntegrityService(db);
      final issues = await service.scan();
      expect(issues.any((i) => i.repairOrderId == o.id), isTrue);
      await service.repairDerivedOrders([o.id]);
      expect((await fresh(o.id)).totalPaid, 100);
      expect((await db.select(db.paymentTransactions).get()).length, 2);
      expect((await db.watchOrders().first).single.totalPaid, 100);
    },
  );
  test(
    'tampered staged restore is rejected before the active database is moved',
    () async {
      final temp = await Directory.systemTemp.createTemp('restore-audit-');
      final paths = LocalPaths(temp);
      final backup = BackupService(db, paths);
      try {
        await order();
        final copy = await backup.createBackup();
        await backup.stageRestore(copy);
        await File(
          '${paths.pendingRestore.path}/database.sqlite',
        ).writeAsBytes([0, 1, 2], flush: true);
        await expectLater(
          BackupService.applyPendingRestore(paths),
          throwsA(anything),
        );
        expect((await db.select(db.customers).get()).length, 1);
      } finally {
        backup.dispose();
        await temp.delete(recursive: true);
      }
    },
  );
  test(
    'correcting and deleting a refund updates the credit without double counting',
    () async {
      final o = await order(total: 100);
      await pay(o, 130);
      final refund = await pay(o, -20, type: 'refund');
      await repo.updatePayment(o.id, refund, newAmount: -10);
      expect((await totals()).cash, 120);
      expect(
        (await (db.select(
          db.workshopDebts,
        )..where((d) => d.isDeleted.equals(false))).get()).single.remaining,
        20,
      );
      await repo.deletePayment(o.id, refund);
      expect((await totals()).cash, 130);
      expect(
        (await (db.select(
          db.workshopDebts,
        )..where((d) => d.isDeleted.equals(false))).get()).single.remaining,
        30,
      );
    },
  );
  test(
    'write activity is balanced after successful nested writes and rejected writes',
    () async {
      var active = 0;
      final guarded = LocalRepository(
        db,
        onMutation: (entering) {
          active += entering ? 1 : -1;
          expect(active, greaterThanOrEqualTo(0));
        },
      );
      await guarded.addCustomer(name: 'عميل', phone: '1', address: '');
      final c = (await db.select(db.customers).get()).single;
      final id = await guarded.addOrder(
        customerId: c.id,
        customerName: c.name,
        itemType: 'كنبة',
        details: '',
        totalAmount: 100,
        initialDeposit: 120,
        deliveryDate: DateTime.now(),
      );
      expect(active, 0);
      await expectLater(
        guarded.addPayment(
          orderId: id,
          customerId: c.id,
          amount: -999,
          paymentType: 'refund',
        ),
        throwsStateError,
      );
      expect(active, 0);
    },
  );
}
