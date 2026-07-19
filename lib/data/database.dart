import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// جدول العملاء
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().withDefault(const Constant(''))();
  /// رقم تسلسلي فريد وثابت للعميل - بيتحدد مرة واحدة وقت الإضافة
  /// ومبيتغيرش بعد كده، ومش بيتكرر أبدًا حتى لو اتحذف عميل تاني قبله
  IntColumn get serialNumber => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الطلبات
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get customerName => text()();
  TextColumn get itemType => text()();
  TextColumn get details => text().withDefault(const Constant(''))();
  /// روابط الصور متخزّنة كنص JSON (["url1", "url2"]) عشان درفت مالوش
  /// نوع عمود List مباشر
  TextColumn get imagesJson => text().withDefault(const Constant('[]'))();
  TextColumn get status => text()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get totalPaid => real().withDefault(const Constant(0))();
  /// خصم بمبلغ ثابت (مش نسبة) بيتشال من الإجمالي - مثلاً اتفقنا على
  /// 15000 والعميل دفع 14000 وعملنا خصم 1000، فالـ 1000 دي مش من
  /// حقنا أصلاً: مش بتتحسب مديونية عليه ولا إيراد للورشة
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  TextColumn get discountReason => text().withDefault(const Constant(''))();
  IntColumn get deliveryDate => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الدفعات (سُمّي PaymentTransactions بدل Transactions تجنبًا لأي
/// تعارض تسمية مع مفاهيم "Transaction" الداخلية في قواعد البيانات)
class PaymentTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get customerId => text()();
  RealColumn get amountPaid => real()();
  IntColumn get paymentDate => integer()();
  TextColumn get paymentType => text()();
  /// طريقة استلام المبلغ: cash (نقدي) / instapay (إنستاباي) - أو أي قيمة
  /// حرة تانية لو المستخدم اختار "أخرى" وكتب طريقة مخصوصة
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  /// حالة الدفعة: pending (معلقة) / completed (مكتملة)
  TextColumn get status => text().withDefault(const Constant('completed'))();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول المصروفات
class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get workerName => text().nullable()();
  /// لو المصروف ده مرتبط بطلب/عميل معيّن (زي مصروف بيتسجل من جوه تفاصيل
  /// الطلب) - بيفضلوا null للمصروفات العامة (إيجار، أجور... إلخ)
  TextColumn get orderId => text().nullable()();
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  /// مصدر خروج المبلغ من الخزينة: cash (نقدي) / instapay (إنستاباي) -
  /// بيحدد أي "خزنة" اتخصم منها المصروف ده عشان تفنيط "المبلغ المتاح"
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  /// لو المصروف ده سداد لمديونية ورشة (مورد/صنايعي) - بيربطه بسجل
  /// المديونية في جدول WorkshopDebts، وبيفضل null لباقي المصروفات العادية
  TextColumn get workshopDebtId => text().nullable()();
  /// تقسيم المصروف على أكتر من طلب - متخزّن كنص JSON:
  /// [{"orderId":"..","customerId":"..","customerName":"..","amount":123}, ...]
  /// نفس فكرة imagesJson في جدول الطلبات؛ لو المصروف عام (مش مقسّم على
  /// طلبات) بتفضل '[]'. الحقول القديمة orderId/customerId/customerName
  /// فوق بتفضل متسجلة كمان لو طلب واحد بس اتاختار (توافقًا مع الكود القديم)
  TextColumn get orderAllocationsJson => text().withDefault(const Constant('[]'))();
  IntColumn get date => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول مديونيات الورشة - الديون اللي على الورشة لصالح الموردين أو
/// الصنايعية (عكس مديونيات العملاء اللي هي فلوس لينا عندهم)
class WorkshopDebts extends Table {
  TextColumn get id => text()();
  /// اسم المورد/الصنايعي المستحق له المديونية
  TextColumn get creditorName => text()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  /// إجمالي اللي اتسدد لحد دلوقتي من المديونية دي
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول العمال (صنايعية، محاسبين، مديرين، سوشيال ميديا... أي وظيفة
/// تتضاف وقت إضافة العامل نفسه - مفيش قايمة وظايف ثابتة)
class Workers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get jobTitle => text()();
  /// نوع المرتب: monthly / weekly / daily
  TextColumn get salaryType => text()();
  RealColumn get salaryAmount => real().withDefault(const Constant(0))();
  /// يوم القبض الأسبوعي (1=الاثنين ... 7=الأحد، زي DateTime.weekday) -
  /// مستخدم بس لو salaryType == weekly، افتراضيًا الخميس (4)
  IntColumn get payWeekday => integer().withDefault(const Constant(4))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// سجل تأكيد قبض العمال - كل مرة تتأكد فيها إن العامل قبض مرتبه (يومي/
/// أسبوعي/شهري) بيتسجل هنا صف، وبيترتبط أوتوماتيك بمصروف من نوع "أجور"
/// عشان يدخل في حساب الأرباح والتقارير زي أي مصروف تاني
class WorkerPayments extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text()();
  TextColumn get workerName => text()();
  RealColumn get amount => real()();
  IntColumn get paymentDate => integer()();
  /// بداية دورة الاستحقاق (منتصف الليل) - بنستخدمها نتأكد إن العامل
  /// اتقبض مرة واحدة بس في نفس الدورة (الأسبوع/اليوم/الشهر)
  IntColumn get periodStart => integer()();
  TextColumn get expenseId => text().nullable()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول الخامات
class MaterialItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get minThreshold => real().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// جدول صغير لتخزين بيانات المزامنة العامة (زي وقت آخر مزامنة ناجحة)
/// هنستخدمه في المرحلة الجاية (خدمة المزامنة)
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// سجل عمليات "سحب إنستاباي كاش" - مبلغ اتسحب من رصيد إنستاباي عن طريق
/// ماكينة صراف آلي (ATM) وتحوّل لسيولة نقدية (كاش) في الخزينة. العملية
/// دي مش مصروف حقيقي ومش إيراد جديد - هي بس نقل نفس الفلوس من مصدر
/// لمصدر تاني، فبتتخزن في جدول منفصل عشان متأثرش على "إجمالي
/// المصروفات" أو "إجمالي الإيرادات" في التقارير
class CashTransfers extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get date => integer()();
  IntColumn get updatedAt => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Customers,
  Orders,
  PaymentTransactions,
  Expenses,
  MaterialItems,
  Workers,
  WorkerPayments,
  WorkshopDebts,
  CashTransfers,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // إضافة أعمدة ربط المصروف بالطلب/العميل (نسخة 2)
          await m.addColumn(expenses, expenses.orderId);
          await m.addColumn(expenses, expenses.customerId);
          await m.addColumn(expenses, expenses.customerName);
        }
        if (from < 3) {
          // إضافة جدولي العمال وسجل قبضهم (نسخة 3)
          await m.createTable(workers);
          await m.createTable(workerPayments);
        }
        if (from < 4) {
          // إضافة أعمدة الخصم على الطلبات (نسخة 4)
          await m.addColumn(orders, orders.discountAmount);
          await m.addColumn(orders, orders.discountReason);
        }
        if (from < 5) {
          // إضافة الرقم التسلسلي للعميل (نسخة 5) - وترقيم العملاء
          // الموجودين بالفعل حسب ترتيب تاريخ إضافتهم عشان محدش يفضل صفر
          await m.addColumn(customers, customers.serialNumber);
          final existing = await (select(customers)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
          for (var i = 0; i < existing.length; i++) {
            await (update(customers)..where((t) => t.id.equals(existing[i].id)))
                .write(CustomersCompanion(serialNumber: Value(i + 1)));
          }
        }
        if (from < 6) {
          // إضافة طريقة الاستلام (نقدي/إنستاباي) وحالة الدفعة على الدفعات (نسخة 6)
          await m.addColumn(paymentTransactions, paymentTransactions.paymentMethod);
          await m.addColumn(paymentTransactions, paymentTransactions.status);
        }
        if (from < 7) {
          // إضافة مصدر خروج المصروف (نقدي/إنستاباي) وربطه بمديونية الورشة
          // لو موجودة، وإنشاء جدول مديونيات الورشة (نسخة 7)
          await m.addColumn(expenses, expenses.paymentMethod);
          await m.addColumn(expenses, expenses.workshopDebtId);
          await m.createTable(workshopDebts);
        }
        if (from < 8) {
          // إمكانية تقسيم مصروف واحد على أكتر من طلب في نفس الوقت (نسخة 8)
          await m.addColumn(expenses, expenses.orderAllocationsJson);
        }
        if (from < 9) {
          // جدول سحب إنستاباي كاش (نسخة 9)
          await m.createTable(cashTransfers);
        }
      },
    );
  }

  // ---------------- Customers ----------------

  Stream<List<Customer>> watchCustomers() {
    return (select(customers)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertCustomer(CustomersCompanion entry) => into(customers).insertOnConflictUpdate(entry);

  /// تحديث جزئي لعميل موجود بالفعل - عكس [upsertCustomer]، الميثود دي
  /// بتستخدم UPDATE حقيقي (مش INSERT ... ON CONFLICT) عشان تقدر تبعت
  /// أي عدد من الأعمدة من غير ما تحتاج تبعت كل الأعمدة الإجبارية، لأن
  /// UPSERT في SQLite بيتطلب قيم لكل الأعمدة NOT NULL حتى لو السجل
  /// موجود بالفعل وهدفك تعدّل عمود واحد بس
  Future<void> updateCustomerFields(CustomersCompanion entry) =>
      (update(customers)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteCustomer(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  /// بيرجع أول رقم تسلسلي متاح للعميل الجديد = أكبر رقم مستخدم + 1.
  /// بنحسبها من كل العملاء حتى المحذوفين عشان الرقم يفضل مخصوص للعميل
  /// اللي اتحذف ومحدش تاني ياخده بالغلط
  Future<int> getNextCustomerSerialNumber() async {
    final maxExp = customers.serialNumber.max();
    final query = selectOnly(customers)..addColumns([maxExp]);
    final row = await query.getSingleOrNull();
    final currentMax = row?.read(maxExp) ?? 0;
    return currentMax + 1;
  }

  // ---------------- Orders ----------------

  Stream<List<Order>> watchOrders() {
    return (select(orders)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertOrder(OrdersCompanion entry) => into(orders).insertOnConflictUpdate(entry);

  /// تحديث جزئي لطلب موجود بالفعل (زي تغيير الحالة بس، أو المبلغ
  /// المدفوع بس) - نفس فكرة [updateCustomerFields]، UPDATE حقيقي
  Future<void> updateOrderFields(OrdersCompanion entry) =>
      (update(orders)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteOrder(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(orders)..where((t) => t.id.equals(id))).write(
      OrdersCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Payment Transactions ----------------

  Stream<List<PaymentTransaction>> watchTransactionsForOrder(String orderId) {
    return (select(paymentTransactions)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false)))
        .watch();
  }

  Stream<List<PaymentTransaction>> watchAllTransactions() {
    return (select(paymentTransactions)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertTransaction(PaymentTransactionsCompanion entry) =>
      into(paymentTransactions).insertOnConflictUpdate(entry);

  Future<void> updateTransactionFields(PaymentTransactionsCompanion entry) =>
      (update(paymentTransactions)..where((t) => t.id.equals(entry.id.value))).write(entry);

  /// تحديث حالة دفعة معيّنة بس (معلقة/مكتملة) من غير ما نلمس باقي الأعمدة
  Future<void> updatePaymentStatus(String id, String status) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(paymentTransactions)..where((t) => t.id.equals(id))).write(
      PaymentTransactionsCompanion(status: Value(status), updatedAt: Value(now), dirty: const Value(true)),
    );
  }

  /// بيحذف (soft delete) كل الدفعات المرتبطة بطلب معيّن دفعة واحدة - بننادي
  /// عليها لما الطلب نفسه بيتحذف، عشان الفلوس المسجلة عليه متفضلش "عالقة"
  /// في حسابات الخزينة (كاش/إنستاباي) وهي مرتبطة بطلب ملوش وجود أصلًا
  Future<void> softDeleteTransactionsForOrder(String orderId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(paymentTransactions)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))).write(
      PaymentTransactionsCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  /// بيحسب إجمالي المدفوع لطلب معيّن من واقع سجل الدفعات نفسه (مش من رقم
  /// متراكم متخزّن) - ده اللي بيضمن إن الرقم صح دايمًا مهما حصل تعارض
  /// أو تكرار مزامنة، لأن SUM() عملية "idempotent" ومفيهاش تراكم أخطاء
  Future<double> sumPaymentsForOrder(String orderId) async {
    final sumExp = paymentTransactions.amountPaid.sum();
    final query = selectOnly(paymentTransactions)
      ..addColumns([sumExp])
      ..where(paymentTransactions.orderId.equals(orderId) & paymentTransactions.isDeleted.equals(false));
    final row = await query.getSingleOrNull();
    return row?.read(sumExp) ?? 0;
  }

  /// بيعيد حساب totalPaid لطلب معيّن من الصفر بناءً على سجل الدفعات
  /// الفعلي، وبيحدّثه في جدول الطلبات لو مختلف عن القيمة الحالية
  Future<void> recomputeOrderTotalPaid(String orderId) async {
    final order = await (select(orders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
    if (order == null) return;
    final correctTotal = await sumPaymentsForOrder(orderId);
    if (correctTotal != order.totalPaid) {
      await updateOrderFields(OrdersCompanion(
        id: Value(orderId),
        totalPaid: Value(correctTotal),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        dirty: const Value(true),
      ));
    }
  }

  // ---------------- Expenses ----------------

  Stream<List<Expense>> watchExpenses() {
    return (select(expenses)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Stream<List<Expense>> watchExpensesForOrder(String orderId) {
    return (select(expenses)..where((t) => t.orderId.equals(orderId) & t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertExpense(ExpensesCompanion entry) => into(expenses).insertOnConflictUpdate(entry);

  Future<void> updateExpenseFields(ExpensesCompanion entry) =>
      (update(expenses)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteExpense(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Workshop Debts ----------------

  Stream<List<WorkshopDebt>> watchWorkshopDebts() {
    return (select(workshopDebts)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertWorkshopDebt(WorkshopDebtsCompanion entry) =>
      into(workshopDebts).insertOnConflictUpdate(entry);

  Future<void> updateWorkshopDebtFields(WorkshopDebtsCompanion entry) =>
      (update(workshopDebts)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteWorkshopDebt(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(workshopDebts)..where((t) => t.id.equals(id))).write(
      WorkshopDebtsCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Cash Transfers (سحب إنستاباي كاش) ----------------

  Stream<List<CashTransfer>> watchCashTransfers() {
    return (select(cashTransfers)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertCashTransfer(CashTransfersCompanion entry) =>
      into(cashTransfers).insertOnConflictUpdate(entry);

  Future<void> updateCashTransferFields(CashTransfersCompanion entry) =>
      (update(cashTransfers)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteCashTransfer(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(cashTransfers)..where((t) => t.id.equals(id))).write(
      CashTransfersCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Materials ----------------

  Stream<List<MaterialItem>> watchMaterials() {
    return (select(materialItems)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertMaterial(MaterialItemsCompanion entry) => into(materialItems).insertOnConflictUpdate(entry);

  Future<void> updateMaterialFields(MaterialItemsCompanion entry) =>
      (update(materialItems)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteMaterial(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(materialItems)..where((t) => t.id.equals(id))).write(
      MaterialItemsCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Workers ----------------

  Stream<List<Worker>> watchWorkers() {
    return (select(workers)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertWorker(WorkersCompanion entry) => into(workers).insertOnConflictUpdate(entry);

  Future<void> updateWorkerFields(WorkersCompanion entry) =>
      (update(workers)..where((t) => t.id.equals(entry.id.value))).write(entry);

  Future<void> softDeleteWorker(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(workers)..where((t) => t.id.equals(id))).write(
      WorkersCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Worker Payments ----------------

  Stream<List<WorkerPayment>> watchWorkerPayments() {
    return (select(workerPayments)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Stream<List<WorkerPayment>> watchPaymentsForWorker(String workerId) {
    return (select(workerPayments)
          ..where((t) => t.workerId.equals(workerId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.paymentDate)]))
        .watch();
  }

  Future<void> insertWorkerPayment(WorkerPaymentsCompanion entry) => into(workerPayments).insert(entry);

  Future<void> upsertWorkerPayment(WorkerPaymentsCompanion entry) =>
      into(workerPayments).insertOnConflictUpdate(entry);

  Future<void> updateWorkerPaymentFields(WorkerPaymentsCompanion entry) =>
      (update(workerPayments)..where((t) => t.id.equals(entry.id.value))).write(entry);

  // ---------------- Sync Meta ----------------

  Future<String?> getMeta(String key) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) {
    return into(syncMeta).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'workshop_desktop.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
