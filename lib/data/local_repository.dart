import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import 'database.dart';
import '../core/order_calculations.dart';

/// طبقة وسيطة بين الواجهات وقاعدة البيانات المحلية - كل عملية كتابة هنا
/// بتحط dirty=true تلقائيًا عشان خدمة المزامنة تعرف تبعتها لـ Firebase
class LocalRepository {
  LocalRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---------------- Customers ----------------

  Future<void> addCustomer({required String name, required String phone, required String address}) async {
    final now = _now;
    final serialNumber = await _db.getNextCustomerSerialNumber();
    return _db.upsertCustomer(CustomersCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      phone: Value(phone),
      address: Value(address),
      serialNumber: Value(serialNumber),
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
    List<String> imageUrls = const [],
  }) async {
    final id = _uuid.v4();
    final now = _now;
    await _db.upsertOrder(OrdersCompanion(
      id: Value(id),
      customerId: Value(customerId),
      customerName: Value(customerName),
      itemType: Value(itemType),
      details: Value(details),
      imagesJson: Value(jsonEncode(imageUrls)),
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

  /// بيضيف روابط صور جديدة (بعد رفعها على Cloudinary) لطلب موجود، من غير
  /// ما يمسح الصور القديمة اللي كانت متسجلة عليه
  Future<void> addImagesToOrder(Order order, List<String> newImageUrls) {
    final existing = (jsonDecode(order.imagesJson) as List).map((e) => e.toString()).toList();
    final merged = [...existing, ...newImageUrls];
    return _db.updateOrderFields(OrdersCompanion(
      id: Value(order.id),
      imagesJson: Value(jsonEncode(merged)),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  /// بيمسح صورة واحدة بس من قائمة صور الطلب (بالرابط)
  Future<void> removeImageFromOrder(Order order, String imageUrl) {
    final existing = (jsonDecode(order.imagesJson) as List).map((e) => e.toString()).toList();
    existing.remove(imageUrl);
    return _db.updateOrderFields(OrdersCompanion(
      id: Value(order.id),
      imagesJson: Value(jsonEncode(existing)),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> updateOrder(
    Order order, {
    required String itemType,
    required String details,
    required double totalAmount,
    required DateTime deliveryDate,
  }) {
    return _db.updateOrderFields(OrdersCompanion(
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
    return _db.updateOrderFields(OrdersCompanion(
      id: Value(orderId),
      status: Value(status),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  /// حذف الطلب بيمسح (soft delete) كل الدفعات المسجلة عليه كمان، عشان
  /// مبلغها متفضلش محسوبة ضمن "المتاح" في الخزينة وهي مرتبطة بطلب محذوف
  Future<void> deleteOrder(String id) async {
    await _db.softDeleteTransactionsForOrder(id);
    await _db.softDeleteOrder(id);
  }

  /// بتسجّل (أو تعدّل) خصم بمبلغ ثابت على طلب معيّن - المبلغ ده بيتشال
  /// نهائيًا من حساب المديونية والإيراد المستحق على الطلب، مش بس بيظهر
  /// "متبقي صفر" عن طريق تعديل يدوي في المبلغ الإجمالي
  Future<void> setOrderDiscount(Order order, {required double discountAmount, String reason = ''}) {
    return _db.updateOrderFields(OrdersCompanion(
      id: Value(order.id),
      discountAmount: Value(discountAmount),
      discountReason: Value(reason),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  // ---------------- Payments ----------------

  Future<String> addPayment({
    required String orderId,
    required String customerId,
    required double amount,
    required String paymentType,
    String paymentMethod = 'cash',
    String status = 'completed',
  }) async {
    final now = _now;
    final id = _uuid.v4();
    await _db.upsertTransaction(PaymentTransactionsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      customerId: Value(customerId),
      amountPaid: Value(amount),
      paymentDate: Value(now),
      paymentType: Value(paymentType),
      paymentMethod: Value(paymentMethod),
      status: Value(status),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));

    // بنعيد حساب المدفوع بالكامل من سجل الدفعات (SUM) بدل "اقرأ ثم اجمع"
    // - الطريقة القديمة كانت بتعمل race مع خدمة المزامنة (اللي كانت بتزوّد
    // نفس المبلغ تاني وقت الرفع لـ Firebase) فيحصل تراكم أخطاء أو ضياع
    // تحديثات لو حصل تعارض توقيت
    await _db.recomputeOrderTotalPaid(orderId);
    return id;
  }

  /// تحديث حالة دفعة سابقة (مثلاً من "معلقة" لـ "مكتملة")
  Future<void> updatePaymentStatus(String transactionId, String status) {
    return _db.updatePaymentStatus(transactionId, status);
  }

  // ---------------- Expenses ----------------

  Future<void> addExpense({
    required double amount,
    required String category,
    required String description,
    String? workerName,
    required DateTime date,
    required String paymentMethod,
    List<ExpenseOrderAllocation> orderAllocations = const [],
    String? workshopDebtId,
  }) {
    final now = _now;
    // لو طلب واحد بس متاختار، بنفضل نحتفظ بيه في الأعمدة القديمة كمان
    // (orderId/customerId/customerName) عشان أي كود قديم لسه بيقرا منها
    final single = orderAllocations.length == 1 ? orderAllocations.first : null;
    return _db.upsertExpense(ExpensesCompanion(
      id: Value(_uuid.v4()),
      amount: Value(amount),
      category: Value(category),
      description: Value(description),
      workerName: Value(workerName),
      orderId: Value(single?.orderId),
      customerId: Value(single?.customerId),
      customerName: Value(single?.customerName),
      paymentMethod: Value(paymentMethod),
      workshopDebtId: Value(workshopDebtId),
      orderAllocationsJson: Value(ExpenseOrderAllocation.encodeList(orderAllocations)),
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
    required String paymentMethod,
    List<ExpenseOrderAllocation> orderAllocations = const [],
  }) {
    final single = orderAllocations.length == 1 ? orderAllocations.first : null;
    return _db.updateExpenseFields(ExpensesCompanion(
      id: Value(expense.id),
      amount: Value(amount),
      category: Value(category),
      description: Value(description),
      workerName: Value(workerName),
      date: Value(date.millisecondsSinceEpoch),
      orderId: Value(single?.orderId),
      customerId: Value(single?.customerId),
      customerName: Value(single?.customerName),
      paymentMethod: Value(paymentMethod),
      orderAllocationsJson: Value(ExpenseOrderAllocation.encodeList(orderAllocations)),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteExpense(String id) => _db.softDeleteExpense(id);

  // ---------------- Workers ----------------

  Future<void> addWorker({
    required String name,
    required String jobTitle,
    required String salaryType,
    required double salaryAmount,
    int payWeekday = DateTime.thursday,
    String phone = '',
    String notes = '',
  }) {
    final now = _now;
    return _db.upsertWorker(WorkersCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      jobTitle: Value(jobTitle),
      salaryType: Value(salaryType),
      salaryAmount: Value(salaryAmount),
      payWeekday: Value(payWeekday),
      phone: Value(phone),
      notes: Value(notes),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> updateWorker(
    Worker worker, {
    required String name,
    required String jobTitle,
    required String salaryType,
    required double salaryAmount,
    int payWeekday = DateTime.thursday,
    String phone = '',
    String notes = '',
  }) {
    return _db.updateWorkerFields(WorkersCompanion(
      id: Value(worker.id),
      name: Value(name),
      jobTitle: Value(jobTitle),
      salaryType: Value(salaryType),
      salaryAmount: Value(salaryAmount),
      payWeekday: Value(payWeekday),
      phone: Value(phone),
      notes: Value(notes),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteWorker(String id) => _db.softDeleteWorker(id);

  /// بتسجّل قبض العامل لمرتبه (أي نوع: يومي/أسبوعي/شهري) - بتعمل صف في
  /// سجل القبض وبتضيف مصروف "أجور" مرتبط بيه تلقائيًا عشان يدخل في
  /// حسابات الأرباح والتقارير من غير ما تتسجل مرتين يدوي
  Future<void> confirmWorkerPayment({
    required Worker worker,
    required double amount,
    required DateTime periodStart,
    String? note,
    String paymentMethod = 'cash',
  }) async {
    final now = _now;
    final expenseId = _uuid.v4();
    await _db.upsertExpense(ExpensesCompanion(
      id: Value(expenseId),
      amount: Value(amount),
      category: const Value('wages'),
      description: Value(note?.trim().isNotEmpty == true ? note!.trim() : 'قبض ${worker.jobTitle} - ${worker.name}'),
      workerName: Value(worker.name),
      paymentMethod: Value(paymentMethod),
      date: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
    await _db.insertWorkerPayment(WorkerPaymentsCompanion.insert(
      id: _uuid.v4(),
      workerId: worker.id,
      workerName: worker.name,
      amount: amount,
      paymentDate: now,
      periodStart: periodStart.millisecondsSinceEpoch,
      expenseId: Value(expenseId),
      updatedAt: now,
    ));
  }

  // ---------------- Workshop Debts ----------------

  /// تسجيل مديونية جديدة مستحقة على الورشة لصالح مورد أو صنايعي
  Future<void> addWorkshopDebt({
    required String creditorName,
    required double totalAmount,
    String notes = '',
  }) {
    final now = _now;
    return _db.upsertWorkshopDebt(WorkshopDebtsCompanion(
      id: Value(_uuid.v4()),
      creditorName: Value(creditorName),
      totalAmount: Value(totalAmount),
      paidAmount: const Value(0),
      notes: Value(notes),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> updateWorkshopDebt(
    WorkshopDebt debt, {
    required String creditorName,
    required double totalAmount,
    String notes = '',
  }) {
    return _db.updateWorkshopDebtFields(WorkshopDebtsCompanion(
      id: Value(debt.id),
      creditorName: Value(creditorName),
      totalAmount: Value(totalAmount),
      notes: Value(notes),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteWorkshopDebt(String id) => _db.softDeleteWorkshopDebt(id);

  // ---------------- Cash Transfers (سحب إنستاباي كاش) ----------------

  /// تسجيل عملية سحب رصيد إنستاباي من الصراف الآلي وتحويله لكاش. مش
  /// مصروف ومش إيراد - بس نقل بين مصدرين، فمش بيدخل في "إجمالي
  /// المصروفات/الإيرادات"
  Future<void> addCashTransfer({required double amount, String note = ''}) {
    final now = _now;
    return _db.upsertCashTransfer(CashTransfersCompanion(
      id: Value(_uuid.v4()),
      amount: Value(amount),
      note: Value(note),
      date: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteCashTransfer(String id) => _db.softDeleteCashTransfer(id);

  /// سداد دفعة من مديونية الورشة - بيسجّلها تلقائيًا كمصروف جديد (فئة
  /// "سداد مديونية ورشة") بمصدر الدفع المحدد (نقدي/إنستاباي)، وده اللي
  /// بيخصمها فعليًا من "المبلغ المتاح" في الإيرادات (لأن الإيراد المتاح =
  /// الإيرادات - المصروفات)، وبيحدّث إجمالي المسدد من المديونية نفسها
  Future<void> payWorkshopDebt({
    required WorkshopDebt debt,
    required double amount,
    required String paymentMethod,
    String? note,
  }) async {
    final now = _now;
    await _db.upsertExpense(ExpensesCompanion(
      id: Value(_uuid.v4()),
      amount: Value(amount),
      category: const Value('workshop_debt'),
      description: Value(note?.trim().isNotEmpty == true ? note!.trim() : 'سداد مديونية - ${debt.creditorName}'),
      workshopDebtId: Value(debt.id),
      paymentMethod: Value(paymentMethod),
      date: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
      dirty: const Value(true),
    ));
    final newPaid = debt.paidAmount + amount;
    await _db.updateWorkshopDebtFields(WorkshopDebtsCompanion(
      id: Value(debt.id),
      paidAmount: Value(newPaid),
      updatedAt: Value(now),
      dirty: const Value(true),
    ));
  }

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
    return _db.updateMaterialFields(MaterialItemsCompanion(
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
    return _db.updateMaterialFields(MaterialItemsCompanion(
      id: Value(material.id),
      quantity: Value(newQuantity),
      updatedAt: Value(_now),
      dirty: const Value(true),
    ));
  }

  Future<void> deleteMaterial(String id) => _db.softDeleteMaterial(id);
}
