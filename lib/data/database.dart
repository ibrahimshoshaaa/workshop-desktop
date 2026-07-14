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
  IntColumn get date => integer()();
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

@DriftDatabase(tables: [Customers, Orders, PaymentTransactions, Expenses, MaterialItems, SyncMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
      },
    );
  }

  // ---------------- Customers ----------------

  Stream<List<Customer>> watchCustomers() {
    return (select(customers)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertCustomer(CustomersCompanion entry) => into(customers).insertOnConflictUpdate(entry);

  Future<void> softDeleteCustomer(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(customers)..where((t) => t.id.equals(id))).write(
      CustomersCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Orders ----------------

  Stream<List<Order>> watchOrders() {
    return (select(orders)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertOrder(OrdersCompanion entry) => into(orders).insertOnConflictUpdate(entry);

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
      await upsertOrder(OrdersCompanion(
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

  Future<void> softDeleteExpense(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

  // ---------------- Materials ----------------

  Stream<List<MaterialItem>> watchMaterials() {
    return (select(materialItems)..where((t) => t.isDeleted.equals(false))).watch();
  }

  Future<void> upsertMaterial(MaterialItemsCompanion entry) => into(materialItems).insertOnConflictUpdate(entry);

  Future<void> softDeleteMaterial(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(materialItems)..where((t) => t.id.equals(id))).write(
      MaterialItemsCompanion(isDeleted: const Value(true), dirty: const Value(true), updatedAt: Value(now)),
    );
  }

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
