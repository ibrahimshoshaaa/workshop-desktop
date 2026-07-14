import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'database.dart';

/// طبقة وسيطة بين الواجهات وقاعدة البيانات المحلية - كل عملية كتابة هنا
/// بتحط dirty=true تلقائيًا عشان خدمة المزامنة تعرف تبعتها لـ Firebase
class LocalRepository {
  LocalRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---------------- Customers ----------------

  Future<void> addCustomer({required String name, required String phone, required String address}) {
    final now = _now;
    return _db.upsertCustomer(CustomersCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> updateCustomer(Customer customer, {required String name, required String phone, required String address}) {
    return _db.upsertCustomer(CustomersCompanion(
      id: Value(customer.id),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      createdAt: Value(customer.createdAt),
      updatedAt: Value(_now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteCustomer(String id) => _db.softDeleteCustomer(id);

  // ---------------- Orders ----------------

  Future<String> addOrder({
    required String customerId,
    required String customerName,
    required String itemType,
    required String details,
    required double totalAmount,
    required DateTime deliveryDate,
  }) async {
    final id = _uuid.v4();
    final now = _now;
    await _db.upsertOrder(OrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      customerName: Value(customerName),
      itemType: Value(itemType),
      details: Value(details),
      imagesJson: const Value('[]'),
      status: const Value('جاري التجهيز'),
      totalAmount: Value(totalAmount),
      totalPaid: const Value(0),
      deliveryDate: Value(deliveryDate.millisecondsSinceEpoch),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
    return id;
  }

  Future<void> updateOrder(
    Order order, {
    required String itemType,
    required String details,
    required double totalAmount,
    required DateTime deliveryDate,
  }) {
    return _db.upsertOrder(OrdersCompanion(
      id: Value(order.id),
      itemType: Value(itemType),
      details: Value(details),
      totalAmount: Value(totalAmount),
      deliveryDate: Value(deliveryDate.millisecondsSinceEpoch),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return _db.upsertOrder(OrdersCompanion(
      id: Value(orderId),
      status: Value(status),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteOrder(String id) => _db.softDeleteOrder(id);

  // ---------------- Payments ----------------

  Future<void> addPayment({
    required String orderId,
    required String customerId,
    required double amount,
    required String paymentType,
  }) async {
    final now = _now;
    await _db.upsertTransaction(PaymentTransactionsCompanion(
      id: Value(_uuid.v4()),
      orderId: Value(orderId),
      customerId: Value(customerId),
      amountPaid: Value(amount),
      paymentDate: Value(now),
      paymentType: Value(paymentType),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));

    final order = await (_db.select(_db.orders)..where((t) => t.id.equals(orderId))).getSingleOrNull();
    if (order != null) {
      await _db.upsertOrder(OrdersCompanion(
        id: Value(orderId),
        totalPaid: Value(order.totalPaid + amount),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ));
    }
  }

  // ---------------- Expenses ----------------

  Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
    String? workerName,
    required DateTime date,
  }) {
    final now = _now;
    return _db.upsertExpense(ExpensesCompanion(
      id: Value(_uuid.v4()),
      amount: Value(amount),
      category: Value(category),
      description: Value(description),
      workerName: Value(workerName),
      date: Value(date.millisecondsSinceEpoch),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> updateExpense(
    Expense expense, {
    required double amount,
    required String category,
    required String description,
    String? workerName,
    required DateTime date,
  }) {
    return _db.upsertExpense(ExpensesCompanion(
      id: Value(expense.id),
      amount: Value(amount),
      category: Value(category),
      description: Value(description),
      workerName: Value(workerName),
      date: Value(date.millisecondsSinceEpoch),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteExpense(String id) => _db.softDeleteExpense(id);

  // ---------------- Materials ----------------

  Future<void> addMaterial({
    required String name,
    required String unit,
    required double quantity,
    required double minThreshold,
  }) {
    return _db.upsertMaterial(MaterialItemsCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      unit: Value(unit),
      quantity: Value(quantity),
      minThreshold: Value(minThreshold),
      updatedAt: Value(_now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> updateMaterial(
    MaterialItem material, {
    required String name,
    required String unit,
    required double quantity,
    required double minThreshold,
  }) {
    return _db.upsertMaterial(MaterialItemsCompanion(
      id: Value(material.id),
      name: Value(name),
      unit: Value(unit),
      quantity: Value(quantity),
      minThreshold: Value(minThreshold),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> adjustMaterialQuantity(MaterialItem material, double delta) {
    final newQuantity = (material.quantity + delta) < 0 ? 0.0 : material.quantity + delta;
    return _db.upsertMaterial(MaterialItemsCompanion(
      id: Value(material.id),
      quantity: Value(newQuantity),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteMaterial(String id) => _db.softDeleteMaterial(id);
}
