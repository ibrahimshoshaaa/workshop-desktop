import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'database.dart';
import '../core/order_calculations.dart';
import '../core/money.dart';
import '../core/calendar_dates.dart';
import '../core/accounting.dart';

/// طبقة وسيطة بين الواجهات وقاعدة البيانات المحلية - كل عملية كتابة هنا
/// بتحط dirty=true تلقائيًا عشان خدمة المزامنة تعرف تبعتها لـ Firebase
class LocalRepository {
  LocalRepository(this._db, {void Function(bool)? onMutation})
    : _onMutation = onMutation;
  final void Function(bool)? _onMutation;
  final AppDatabase _db;
  static const _uuid = Uuid();

  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<T> _write<T>(Future<T> Function() operation) async {
    _onMutation?.call(true);
    try {
      return await _db.transaction(operation);
    } finally {
      _onMutation?.call(false);
    }
  }

  Future<Order> _currentOrder(String id, {bool allowArchived = false}) async {
    final row = await (_db.select(
      _db.orders,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    if (row == null || row.isDeleted || (!allowArchived && row.isArchived))
      throw StateError('الطلب غير موجود أو مؤرشف');
    final payments = await (_db.select(
      _db.paymentTransactions,
    )..where((t) => t.orderId.equals(id) & t.isDeleted.equals(false))).get();
    if (payments.isEmpty && Money.cents(row.totalPaid) != 0)
      throw StateError(
        'الطلب له مدفوع سابق بدون سجل دفعات. راجع فحص البيانات قبل تعديل حسابه.',
      );
    return row.copyWith(
      totalPaid: Money.sum(
        payments.where((t) => t.status == 'completed').map((t) => t.amountPaid),
      ),
    );
  }

  Future<void> _reconcile(String id) async {
    final raw = await (_db.select(
      _db.orders,
    )..where((o) => o.id.equals(id))).getSingle();
    final paid = await _db.sumPaymentsForOrder(id);
    if (Money.cents(paid) < 0) throw StateError('الحركة ستجعل المدفوع سالبًا');
    await _db.recomputeOrderTotalPaid(id);
    await _reconcileOrderOverpaymentDebt(
      orderId: id,
      customerName: raw.customerName,
      itemType: raw.itemType,
      totalAmount: raw.totalAmount,
      discountAmount: raw.discountAmount,
      totalPaid: paid,
    );
  }

  Future<void> repairDerivedOrder(String id) => _write(() async {
    await _currentOrder(id, allowArchived: true);
    await _reconcile(id);
  });
  String _text(String value, String label) {
    final text = value.trim();
    if (text.isEmpty) throw StateError('$label مطلوب');
    return text;
  }

  Future<List<ExpenseOrderAllocation>> _allocations(
    double amount,
    List<ExpenseOrderAllocation> input,
  ) async {
    if (input.isEmpty) return [];
    if (input.map((a) => a.orderId).toSet().length != input.length ||
        input.fold<int>(
              0,
              (s, a) =>
                  s + Money.cents(Money.require(a.amount, allowZero: true)),
            ) !=
            Money.cents(amount)) {
      throw StateError('تقسيم المصروف لا يطابق إجمالي المبلغ');
    }
    final output = <ExpenseOrderAllocation>[];
    for (final a in input) {
      final order = await _currentOrder(a.orderId, allowArchived: true);
      if (order.customerId != a.customerId)
        throw StateError('عميل المصروف لا يطابق الطلب');
      output.add(
        ExpenseOrderAllocation(
          orderId: order.id,
          customerId: order.customerId,
          customerName: order.customerName,
          amount: Money.amount(Money.cents(a.amount)),
        ),
      );
    }
    return output;
  }

  Future<void> _changeLinkedExpense(
    Expense expense,
    double delta, {
    bool deleting = false,
    int? date,
  }) async {
    if (expense.workshopDebtId?.isNotEmpty == true) {
      final debt = await (_db.select(
        _db.workshopDebts,
      )..where((d) => d.id.equals(expense.workshopDebtId!))).getSingleOrNull();
      if (debt == null || debt.isDeleted || debt.orderId.isNotEmpty)
        throw StateError('سجل المديونية المرتبط بالمصروف يحتاج مراجعة');
      final paid = Money.sum([debt.paidAmount, delta]);
      if (paid < 0 || paid > debt.totalAmount)
        throw StateError('تعديل المصروف سيجعل سداد المديونية غير صحيح');
      await _db.updateWorkshopDebtFields(
        WorkshopDebtsCompanion(
          id: Value(debt.id),
          paidAmount: Value(paid),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      );
    }
    final wages =
        await (_db.select(_db.workerPayments)..where(
              (w) => w.expenseId.equals(expense.id) & w.isDeleted.equals(false),
            ))
            .get();
    if (wages.length > 1 ||
        wages.any((w) => Money.cents(w.amount) != Money.cents(expense.amount)))
      throw StateError(
        'صرف العامل المرتبط بالمصروف مختلف أو مكرر؛ راجع فحص البيانات',
      );
    for (final wage in wages) {
      await _db.updateWorkerPaymentFields(
        WorkerPaymentsCompanion(
          id: Value(wage.id),
          amount: Value(
            deleting ? wage.amount : Money.sum([wage.amount, delta]),
          ),
          paymentDate: date == null ? const Value.absent() : Value(date),
          isDeleted: Value(deleting),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      );
    }
  }

  // ---------------- Customers ----------------

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String address,
  }) => _write(() async {
    final now = _now;
    await _db.upsertCustomer(
      CustomersCompanion(
        id: Value(_uuid.v4()),
        name: Value(_text(name, 'اسم العميل')),
        phone: Value(_text(phone, 'رقم الهاتف')),
        address: Value(address.trim()),
        serialNumber: Value(await _db.getNextCustomerSerialNumber()),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        isArchived: const Value(false),
        dirty: const Value(true),
      ),
    );
  });

  Future<void> updateCustomer(
    Customer customer, {
    required String name,
    required String phone,
    required String address,
  }) => _write(() async {
    final fresh = await (_db.select(
      _db.customers,
    )..where((c) => c.id.equals(customer.id))).getSingleOrNull();
    if (fresh == null || fresh.isDeleted || fresh.isArchived)
      throw StateError('العميل غير موجود أو مؤرشف');
    final value = _text(name, 'اسم العميل');
    await _db.updateCustomerFields(
      CustomersCompanion(
        id: Value(fresh.id),
        name: Value(value),
        phone: Value(_text(phone, 'رقم الهاتف')),
        address: Value(address.trim()),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
    final orders =
        await (_db.select(_db.orders)..where(
              (o) => o.customerId.equals(fresh.id) & o.isDeleted.equals(false),
            ))
            .get();
    for (final order in orders) {
      await _db.updateOrderFields(
        OrdersCompanion(
          id: Value(order.id),
          customerName: Value(value),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      );
      await (_db.update(
        _db.workshopDebts,
      )..where((d) => d.orderId.equals(order.id))).write(
        WorkshopDebtsCompanion(
          creditorName: Value(value),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      );
    }
  });

  Future<void> deleteCustomer(String id) => _write(() async {
    final orders = await (_db.select(
      _db.orders,
    )..where((o) => o.customerId.equals(id) & o.isDeleted.equals(false))).get();
    if (orders.isNotEmpty)
      throw StateError(
        'العميل له طلبات محفوظة؛ استخدم الأرشفة بعد تسوية الحسابات',
      );
    final expenses = await _db.select(_db.expenses).get();
    if (expenses.any(
      (e) =>
          !e.isDeleted &&
          (e.customerId == id || e.allocations.any((a) => a.customerId == id)),
    ))
      throw StateError('العميل له مصروفات محفوظة');
    await _db.softDeleteCustomer(id);
  });

  // ---------------- Orders ----------------

  Future<String> addOrder({
    required String customerId,
    required String customerName,
    required String itemType,
    required String details,
    required double totalAmount,
    required DateTime deliveryDate,
    List<String> imageUrls = const [],
    double initialDeposit = 0,
    String depositMethod = 'cash',
  }) => _write(() async {
    final total = Money.require(totalAmount, allowZero: true);
    final deposit = Money.require(initialDeposit, allowZero: true);
    final customer = await (_db.select(
      _db.customers,
    )..where((c) => c.id.equals(customerId))).getSingleOrNull();
    if (customer == null || customer.isDeleted || customer.isArchived)
      throw StateError('العميل غير موجود أو مؤرشف');
    final id = _uuid.v4();
    final now = _now;
    await _db.upsertOrder(
      OrdersCompanion(
        id: Value(id),
        customerId: Value(customerId),
        customerName: Value(customer.name),
        itemType: Value(_text(itemType, 'نوع الصنف')),
        details: Value(details),
        imagesJson: Value(jsonEncode(imageUrls.toSet().toList())),
        status: const Value('جاري التجهيز'),
        totalAmount: Value(total),
        totalPaid: const Value(0),
        deliveryDate: Value(
          CalendarDates.day(deliveryDate).millisecondsSinceEpoch,
        ),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        isArchived: const Value(false),
        dirty: const Value(true),
      ),
    );
    if (deposit > 0)
      await addPayment(
        orderId: id,
        customerId: customerId,
        amount: deposit,
        paymentType: 'deposit',
        paymentMethod: depositMethod,
      );
    return id;
  });

  /// بيضيف روابط صور جديدة (بعد رفعها على Cloudinary) لطلب موجود، من غير
  /// ما يمسح الصور القديمة اللي كانت متسجلة عليه
  Future<void> addImagesToOrder(Order order, List<String> newImageUrls) =>
      _write(() async {
        final fresh = await _currentOrder(order.id);
        final images = (jsonDecode(fresh.imagesJson) as List).map(
          (e) => e.toString(),
        );
        await _db.updateOrderFields(
          OrdersCompanion(
            id: Value(order.id),
            imagesJson: Value(
              jsonEncode({...images, ...newImageUrls}.toList()),
            ),
            updatedAt: Value(_now),
            dirty: const Value(true),
          ),
        );
      });

  /// بيمسح صورة واحدة بس من قائمة صور الطلب (بالرابط)
  Future<void> removeImageFromOrder(Order order, String imageUrl) =>
      _write(() async {
        final fresh = await _currentOrder(order.id);
        final images = (jsonDecode(fresh.imagesJson) as List)
            .map((e) => e.toString())
            .where((e) => e != imageUrl)
            .toList();
        await _db.updateOrderFields(
          OrdersCompanion(
            id: Value(order.id),
            imagesJson: Value(jsonEncode(images)),
            updatedAt: Value(_now),
            dirty: const Value(true),
          ),
        );
      });

  Future<void> updateOrder(
    Order order, {
    required String itemType,
    required String details,
    required double totalAmount,
    required DateTime deliveryDate,
    List<String> removedImages = const [],
    List<String> addedImages = const [],
  }) => _write(() async {
    final fresh = await _currentOrder(order.id);
    final total = Money.require(totalAmount, allowZero: true);
    if (Money.cents(total) < Money.cents(fresh.discountAmount))
      throw StateError('السعر الجديد أقل من الخصم المسجل؛ عدل الخصم أولًا');
    final images = (jsonDecode(fresh.imagesJson) as List)
        .map((e) => e.toString())
        .where((e) => !removedImages.contains(e));
    await _db.updateOrderFields(
      OrdersCompanion(
        id: Value(fresh.id),
        itemType: Value(_text(itemType, 'نوع الصنف')),
        details: Value(details),
        totalAmount: Value(total),
        totalPaid: Value(fresh.totalPaid),
        imagesJson: Value(jsonEncode({...images, ...addedImages}.toList())),
        deliveryDate: Value(
          CalendarDates.day(deliveryDate).millisecondsSinceEpoch,
        ),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
    await _reconcile(fresh.id);
  });

  Future<void> updateOrderStatus(String orderId, String status) =>
      _write(() async {
        await _currentOrder(orderId);
        if (!const [
          'جاري التجهيز',
          'قيد التنفيذ',
          'جاهز للتسليم',
          'تم التسليم',
        ].contains(status))
          throw StateError('حالة طلب غير صالحة');
        await _db.updateOrderFields(
          OrdersCompanion(
            id: Value(orderId),
            status: Value(status),
            updatedAt: Value(_now),
            dirty: const Value(true),
          ),
        );
      });

  /// حذف الطلب بيمسح (soft delete) كل الدفعات المسجلة عليه كمان، عشان
  /// مبلغها متفضلش محسوبة ضمن "المتاح" في الخزينة وهي مرتبطة بطلب محذوف
  Future<void> deleteOrder(String id) => _write(() async {
    await _currentOrder(id);
    final payments = await (_db.select(
      _db.paymentTransactions,
    )..where((t) => t.orderId.equals(id) & t.isDeleted.equals(false))).get();
    final expenses = await _db.select(_db.expenses).get();
    if (payments.isNotEmpty ||
        expenses.any(
          (e) => !e.isDeleted && e.allocations.any((a) => a.orderId == id),
        ))
      throw StateError(
        'الطلب له حركات مالية؛ لا يمكن حذفه. راجع الحركات أو استخدم الأرشفة بعد التسوية.',
      );
    await _db.softDeleteOrder(id);
  });

  /// بتسجّل (أو تعدّل) خصم بمبلغ ثابت على طلب معيّن - المبلغ ده بيتشال
  /// نهائيًا من حساب المديونية والإيراد المستحق على الطلب، مش بس بيظهر
  /// "متبقي صفر" عن طريق تعديل يدوي في المبلغ الإجمالي
  Future<void> setOrderDiscount(
    Order order, {
    required double discountAmount,
    String reason = '',
  }) => _write(() async {
    final fresh = await _currentOrder(order.id);
    final amount = Money.require(discountAmount, allowZero: true);
    if (Money.cents(amount) > Money.cents(fresh.totalAmount))
      throw StateError('الخصم أكبر من إجمالي الاتفاق');
    await _db.updateOrderFields(
      OrdersCompanion(
        id: Value(order.id),
        discountAmount: Value(amount),
        discountReason: Value(reason.trim()),
        totalPaid: Value(fresh.totalPaid),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
    await _reconcile(order.id);
  });

  // ---------------- Payments ----------------

  Future<String> addPayment({
    required String orderId,
    required String customerId,
    required double amount,
    required String paymentType,
    String paymentMethod = 'cash',
    String status = 'completed',
  }) => _write(() async {
    final value = Money.require(amount, signed: true);
    final order = await _currentOrder(orderId);
    if (order.customerId != customerId)
      throw StateError('الدفعة مرتبطة بعميل غير صحيح');
    if (!const ['pending', 'completed'].contains(status) ||
        !const ['deposit', 'installment', 'refund'].contains(paymentType))
      throw StateError('نوع أو حالة الدفعة غير صالح');
    if ((paymentType == 'refund') != (value < 0))
      throw StateError('المبلغ السالب مخصص لرد الأموال فقط');
    if (value < 0 && -Money.cents(value) > Money.cents(order.totalPaid))
      throw StateError('لا يمكن رد مبلغ أكبر من المقبوض');
    final id = _uuid.v4();
    final now = _now;
    await _db.upsertTransaction(
      PaymentTransactionsCompanion(
        id: Value(id),
        orderId: Value(orderId),
        customerId: Value(customerId),
        amountPaid: Value(value),
        paymentDate: Value(now),
        paymentType: Value(paymentType),
        paymentMethod: Value(_text(paymentMethod, 'طريقة الدفع')),
        status: Value(status),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        dirty: const Value(true),
      ),
    );
    await _reconcile(orderId);
    return id;
  });

  /// تحديث حالة دفعة سابقة (مثلاً من "معلقة" لـ "مكتملة")
  Future<void> updatePaymentStatus(String transactionId, String status) =>
      _write(() async {
        if (!const ['pending', 'completed'].contains(status))
          throw StateError('حالة دفعة غير صالحة');
        final tx = await (_db.select(
          _db.paymentTransactions,
        )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
        if (tx == null || tx.isDeleted) throw StateError('الدفعة غير موجودة');
        final order = await _currentOrder(tx.orderId);
        if (tx.status == status) return;
        final total = Money.sum([
          order.totalPaid,
          tx.status == 'completed' ? -tx.amountPaid : tx.amountPaid,
        ]);
        if (total < 0)
          throw StateError('تغيير حالة الدفعة سيجعل المدفوع سالبًا');
        await _db.updatePaymentStatus(
          transactionId,
          status,
          paymentDate: status == 'completed' ? _now : null,
        );
        await _reconcile(tx.orderId);
      });

  /// تعديل مبلغ دفعة (وطريقة الدفع لو اتبعتت) بعد ما اتسجلت غلط - بيعتمد
  /// على [recomputeOrderTotalPaid] (SUM من سجل الدفعات نفسه) عشان المتبقي
  /// يتظبط تلقائيًا من غير ما نحسب الفرق يدويًا، وبيعيد فحص مديونية الورشة
  /// (الفائض) بعد التعديل بالظبط زي addPayment
  Future<void> updatePayment(
    String orderId,
    String transactionId, {
    required double newAmount,
    String? paymentMethod,
  }) => _write(() async {
    final value = Money.require(newAmount, signed: true);
    final order = await _currentOrder(orderId);
    final tx = await (_db.select(
      _db.paymentTransactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (tx == null || tx.isDeleted || tx.orderId != orderId)
      throw StateError('الدفعة لا تخص الطلب');
    if ((tx.paymentType == 'refund') != (value < 0))
      throw StateError('إشارة مبلغ الدفعة غير صحيحة');
    if (tx.status == 'completed' &&
        Money.sum([order.totalPaid, -tx.amountPaid, value]) < 0)
      throw StateError('التعديل سيجعل المدفوع سالبًا');
    await _db.updateTransactionFields(
      PaymentTransactionsCompanion(
        id: Value(transactionId),
        amountPaid: Value(value),
        paymentMethod: paymentMethod == null
            ? const Value.absent()
            : Value(_text(paymentMethod, 'طريقة الدفع')),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
    await _reconcile(orderId);
  });

  /// حذف دفعة بالكامل (اتسجلت غلط) - بيرجّع المبلغ من المدفوع تلقائيًا عبر
  /// [recomputeOrderTotalPaid]، وبيعيد فحص مديونية الورشة (الفائض) بعد الحذف
  Future<void> deletePayment(String orderId, String transactionId) => _write(
    () async {
      final order = await _currentOrder(orderId);
      final tx = await (_db.select(
        _db.paymentTransactions,
      )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
      if (tx == null || tx.isDeleted || tx.orderId != orderId)
        throw StateError('الدفعة لا تخص الطلب');
      if (tx.status == 'completed' &&
          Money.subtract(order.totalPaid, tx.amountPaid) < 0)
        throw StateError('لا يمكن حذف قبض تم رد جزء منه قبل مراجعة حركات الرد');
      await _db.softDeleteTransaction(transactionId);
      await _reconcile(orderId);
    },
  );

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
  }) => _write(() async {
    if (workshopDebtId != null)
      throw StateError('سداد المديونية يتم من صفحة المديونيات');
    final value = Money.require(amount);
    final allocations = await _allocations(value, orderAllocations);
    final single = allocations.length == 1 ? allocations.first : null;
    final now = _now;
    await _db.upsertExpense(
      ExpensesCompanion(
        id: Value(_uuid.v4()),
        amount: Value(value),
        category: Value(_text(category, 'الفئة')),
        description: Value(description),
        workerName: Value(workerName),
        orderId: Value(single?.orderId),
        customerId: Value(single?.customerId),
        customerName: Value(single?.customerName),
        paymentMethod: Value(_text(paymentMethod, 'طريقة الدفع')),
        orderAllocationsJson: Value(
          ExpenseOrderAllocation.encodeList(allocations),
        ),
        date: Value(date.millisecondsSinceEpoch),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        dirty: const Value(true),
      ),
    );
  });

  Future<void> updateExpense(
    Expense expense, {
    required double amount,
    required String category,
    required String description,
    String? workerName,
    required DateTime date,
    required String paymentMethod,
    List<ExpenseOrderAllocation> orderAllocations = const [],
  }) => _write(() async {
    final old = await (_db.select(
      _db.expenses,
    )..where((e) => e.id.equals(expense.id))).getSingleOrNull();
    if (old == null || old.isDeleted) throw StateError('المصروف غير موجود');
    final value = Money.require(amount);
    final wages =
        await (_db.select(_db.workerPayments)..where(
              (w) => w.expenseId.equals(old.id) & w.isDeleted.equals(false),
            ))
            .get();
    if ((old.workshopDebtId != null && category != 'workshop_debt') ||
        (wages.isNotEmpty && category != 'wages'))
      throw StateError('فئة المصروف مرتبطة بسداد أو أجور ولا يمكن تغييرها');
    final allocations = await _allocations(value, orderAllocations);
    final single = allocations.length == 1 ? allocations.first : null;
    await _changeLinkedExpense(
      old,
      Money.subtract(value, old.amount),
      date: date.millisecondsSinceEpoch,
    );
    await _db.updateExpenseFields(
      ExpensesCompanion(
        id: Value(old.id),
        amount: Value(value),
        category: Value(_text(category, 'الفئة')),
        description: Value(description),
        workerName: Value(workerName),
        orderId: Value(single?.orderId),
        customerId: Value(single?.customerId),
        customerName: Value(single?.customerName),
        paymentMethod: Value(_text(paymentMethod, 'طريقة الدفع')),
        orderAllocationsJson: Value(
          ExpenseOrderAllocation.encodeList(allocations),
        ),
        date: Value(date.millisecondsSinceEpoch),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
  });

  Future<void> deleteExpense(String id) => _write(() async {
    final expense = await (_db.select(
      _db.expenses,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (expense == null || expense.isDeleted)
      throw StateError('المصروف غير موجود');
    await _changeLinkedExpense(expense, -expense.amount, deleting: true);
    await _db.softDeleteExpense(id);
  });

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
    Money.require(salaryAmount);
    if (!const ['daily', 'weekly', 'monthly'].contains(salaryType) ||
        payWeekday < 1 ||
        payWeekday > 7)
      throw StateError('نظام مرتب غير صالح');
    _text(name, 'اسم العامل');

    final now = _now;
    return _write(
      () => _db.upsertWorker(
        WorkersCompanion(
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
        ),
      ),
    );
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
    Money.require(salaryAmount);
    if (!const ['daily', 'weekly', 'monthly'].contains(salaryType) ||
        payWeekday < 1 ||
        payWeekday > 7)
      throw StateError('نظام مرتب غير صالح');
    _text(name, 'اسم العامل');

    return _write(
      () => _db.updateWorkerFields(
        WorkersCompanion(
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
        ),
      ),
    );
  }

  Future<void> deleteWorker(String id) =>
      _write(() => _db.softDeleteWorker(id));

  /// بتسجّل قبض العامل لمرتبه (أي نوع: يومي/أسبوعي/شهري) - بتعمل صف في
  /// سجل القبض وبتضيف مصروف "أجور" مرتبط بيه تلقائيًا عشان يدخل في
  /// حسابات الأرباح والتقارير من غير ما تتسجل مرتين يدوي
  Future<void> confirmWorkerPayment({
    required Worker worker,
    required double amount,
    required DateTime periodStart,
    String? note,
    String paymentMethod = 'cash',
  }) => _write(() async {
    final value = Money.require(amount);
    final now = _now;
    final fresh = await (_db.select(
      _db.workers,
    )..where((w) => w.id.equals(worker.id))).getSingleOrNull();
    if (fresh == null || fresh.isDeleted) throw StateError('العامل غير موجود');
    final anchor = CalendarDates.day(periodStart).millisecondsSinceEpoch;
    final existing =
        await (_db.select(_db.workerPayments)..where(
              (w) =>
                  w.workerId.equals(worker.id) &
                  w.periodStart.isBiggerOrEqualValue(anchor) &
                  w.periodStart.isSmallerThanValue(
                    CalendarDates.addDays(
                      periodStart,
                      1,
                    ).millisecondsSinceEpoch,
                  ) &
                  w.isDeleted.equals(false),
            ))
            .get();
    if (existing.isNotEmpty) throw StateError('تم تسجيل قبض هذه الفترة بالفعل');
    final expenseId = _uuid.v4();
    await _db.upsertExpense(
      ExpensesCompanion(
        id: Value(expenseId),
        amount: Value(value),
        category: const Value('wages'),
        description: Value(
          note?.trim().isNotEmpty == true
              ? note!.trim()
              : 'قبض ${fresh.jobTitle} - ${fresh.name}',
        ),
        workerName: Value(fresh.name),
        paymentMethod: Value(_text(paymentMethod, 'طريقة الدفع')),
        date: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        dirty: const Value(true),
      ),
    );
    await _db.insertWorkerPayment(
      WorkerPaymentsCompanion.insert(
        id: _uuid.v4(),
        workerId: fresh.id,
        workerName: fresh.name,
        amount: value,
        paymentDate: now,
        periodStart: anchor,
        expenseId: Value(expenseId),
        updatedAt: now,
      ),
    );
  });

  // ---------------- Workshop Debts ----------------

  /// تسجيل مديونية جديدة مستحقة على الورشة لصالح مورد أو صنايعي
  Future<void> addWorkshopDebt({
    required String creditorName,
    required double totalAmount,
    String notes = '',
    String orderId = '',
  }) => _write(() async {
    final value = Money.require(totalAmount);
    final now = _now;
    await _db.upsertWorkshopDebt(
      WorkshopDebtsCompanion(
        id: Value(_uuid.v4()),
        creditorName: Value(_text(creditorName, 'اسم الدائن')),
        totalAmount: Value(value),
        paidAmount: const Value(0),
        notes: Value(notes),
        orderId: Value(orderId),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        dirty: const Value(true),
      ),
    );
  });

  Future<void> updateWorkshopDebt(
    WorkshopDebt debt, {
    required String creditorName,
    required double totalAmount,
    String notes = '',
  }) => _write(() async {
    final fresh = await (_db.select(
      _db.workshopDebts,
    )..where((d) => d.id.equals(debt.id))).getSingleOrNull();
    if (fresh == null || fresh.isDeleted)
      throw StateError('المديونية غير موجودة');
    if (fresh.orderId.isNotEmpty)
      throw StateError('مديونية العميل تتحدث من الطلب ودفعاته');
    final value = Money.require(totalAmount);
    if (Money.cents(value) < Money.cents(fresh.paidAmount))
      throw StateError('إجمالي المديونية أقل من المسدد');
    await _db.updateWorkshopDebtFields(
      WorkshopDebtsCompanion(
        id: Value(fresh.id),
        creditorName: Value(_text(creditorName, 'اسم الدائن')),
        totalAmount: Value(value),
        notes: Value(notes),
        updatedAt: Value(_now),
        dirty: const Value(true),
      ),
    );
  });

  Future<void> deleteWorkshopDebt(String id) => _write(() async {
    final debt = await (_db.select(
      _db.workshopDebts,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    if (debt == null || debt.isDeleted)
      throw StateError('المديونية غير موجودة');
    final expenses =
        await (_db.select(_db.expenses)..where(
              (e) => e.workshopDebtId.equals(id) & e.isDeleted.equals(false),
            ))
            .get();
    if (debt.orderId.isNotEmpty ||
        Money.cents(debt.paidAmount) != 0 ||
        expenses.isNotEmpty)
      throw StateError('المديونية مرتبطة بطلب أو سداد محفوظ؛ لا يمكن حذفها');
    await _db.softDeleteWorkshopDebt(id);
  });

  /// بتتأكد إن مديونية الورشة الناتجة عن دفع العميل أكتر من السعر
  /// النهائي المتفق عليه لطلب معيّن (لو موجودة) متسقة مع حالة الطلب
  /// الحالية - بتنشئها لو لسه مفيش وفيه فايض، تحدّثها لو موجودة والمبلغ
  /// اتغيّر، أو تمسحها لو مبقاش فيه فايض خالص. بتتنادى تلقائيًا من جوه
  /// [updateOrder] و [setOrderDiscount] - مفيش داعي تتنادى يدوي
  Future<void> _reconcileOrderOverpaymentDebt({
    required String orderId,
    required String customerName,
    required String itemType,
    required double totalAmount,
    required double discountAmount,
    required double totalPaid,
  }) async {
    final overpaid = Money.subtract(
      totalPaid,
      Money.subtract(totalAmount, discountAmount),
    );
    final existing =
        await (_db.select(_db.workshopDebts)..where(
              (d) => d.orderId.equals(orderId) & d.isDeleted.equals(false),
            ))
            .get();
    if (existing.length > 1 ||
        existing.any((d) => Money.cents(d.paidAmount) != 0))
      throw StateError(
        'سجل مديونية العميل القديم يحتاج مراجعة من فحص البيانات',
      );
    final debt = existing.isEmpty ? null : existing.single;
    if (overpaid <= 0) {
      if (debt != null) await _db.softDeleteWorkshopDebt(debt.id);
      return;
    }
    if (debt == null) {
      await addWorkshopDebt(
        creditorName: customerName,
        totalAmount: overpaid,
        notes: 'زيادة مدفوعة على طلب $itemType',
        orderId: orderId,
      );
    } else {
      await _db.updateWorkshopDebtFields(
        WorkshopDebtsCompanion(
          id: Value(debt.id),
          totalAmount: Value(overpaid),
          creditorName: Value(customerName),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      );
    }
  }

  // ---------------- Cash Transfers (سحب إنستاباي كاش) ----------------

  /// تسجيل عملية سحب رصيد إنستاباي من الصراف الآلي وتحويله لكاش. مش
  /// مصروف ومش إيراد - بس نقل بين مصدرين، فمش بيدخل في "إجمالي
  /// المصروفات/الإيرادات"
  Future<void> addCashTransfer({required double amount, String note = ''}) =>
      _write(() async {
        final value = Money.require(amount);
        final orders = await (_db.select(
          _db.orders,
        )..where((o) => o.isDeleted.equals(false))).get();
        final txs = await (_db.select(
          _db.paymentTransactions,
        )..where((t) => t.isDeleted.equals(false))).get();
        final expenses = await (_db.select(
          _db.expenses,
        )..where((e) => e.isDeleted.equals(false))).get();
        final transfers = await (_db.select(
          _db.cashTransfers,
        )..where((t) => t.isDeleted.equals(false))).get();
        final balance = AccountingSnapshot(
          orders: orders,
          transactions: txs,
          expenses: expenses,
          transfers: transfers,
        ).instapay;
        if (Money.cents(value) > Money.cents(balance))
          throw StateError('المبلغ أكبر من رصيد إنستاباي الحالي');
        final now = _now;
        await _db.upsertCashTransfer(
          CashTransfersCompanion(
            id: Value(_uuid.v4()),
            amount: Value(value),
            note: Value(note),
            date: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
            dirty: const Value(true),
          ),
        );
      });

  Future<void> deleteCashTransfer(String id) =>
      _write(() => _db.softDeleteCashTransfer(id));

  /// سداد دفعة من مديونية الورشة - بيسجّلها تلقائيًا كمصروف جديد (فئة
  /// "سداد مديونية ورشة") بمصدر الدفع المحدد (نقدي/إنستاباي)، وده اللي
  /// بيخصمها فعليًا من "المبلغ المتاح" في الإيرادات (لأن الإيراد المتاح =
  /// الإيرادات - المصروفات).
  ///
  /// لو المديونية دي ناتجة تلقائيًا من طلب معيّن (orderId موجود، يعني
  /// العميل كان دفع أكتر من الاتفاق النهائي بعد تعديل السعر)، السداد هنا
  /// معناه إننا فعليًا رجّعنا فلوس للعميل - فبدل ما نتبعها في paidAmount
  /// بس (وده كان بيسيب "المتبقي" في تفاصيل الطلب والداش بورد واقف على
  /// الرقم القديم للأبد حتى بعد السداد)، بنسجّل دفعة سالبة (refund) على
  /// الطلب نفسه، وده بيخلي [addPayment] يعيد حساب totalPaid ويصفّي/يقلل
  /// مديونية الورشة تلقائيًا (عبر _reconcileOrderOverpaymentDebt) - بكده
  /// أي شاشة بتعرض بيانات الطلب بتتحدث لوحدها من غير ما نحتاج نلحقها
  /// واحدة واحدة. لو مش مرتبطة بطلب (مديونية عادية زي مورد)، بنزوّد
  /// paidAmount عادي زي ما كان
  Future<void> payWorkshopDebt({
    required WorkshopDebt debt,
    required double amount,
    required String paymentMethod,
    String? note,
  }) => _write(() async {
    final value = Money.require(amount);
    final fresh = await (_db.select(
      _db.workshopDebts,
    )..where((d) => d.id.equals(debt.id))).getSingleOrNull();
    if (fresh == null || fresh.isDeleted)
      throw StateError('المديونية غير موجودة أو تمت تسويتها');
    if (Money.cents(value) > Money.cents(fresh.remaining))
      throw StateError('المبلغ أكبر من المتبقي الحالي للمديونية');
    if (fresh.orderId.isNotEmpty) {
      final order = await _currentOrder(fresh.orderId);
      final overpaid = Money.subtract(order.totalPaid, order.effectiveTotal);
      if (Money.cents(value) > Money.cents(overpaid))
        throw StateError('المبلغ أكبر من الزيادة المستحقة للعميل');
      await addPayment(
        orderId: order.id,
        customerId: order.customerId,
        amount: -value,
        paymentType: 'refund',
        paymentMethod: paymentMethod,
      );
      return;
    }
    final now = _now;
    await _db.upsertExpense(
      ExpensesCompanion(
        id: Value(_uuid.v4()),
        amount: Value(value),
        category: const Value('workshop_debt'),
        description: Value(
          note?.trim().isNotEmpty == true
              ? note!.trim()
              : 'سداد مديونية - ${fresh.creditorName}',
        ),
        workshopDebtId: Value(fresh.id),
        paymentMethod: Value(_text(paymentMethod, 'طريقة الدفع')),
        date: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        dirty: const Value(true),
      ),
    );
    await _db.updateWorkshopDebtFields(
      WorkshopDebtsCompanion(
        id: Value(fresh.id),
        paidAmount: Value(Money.sum([fresh.paidAmount, value])),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
  });

  // ---------------- Materials ----------------

  Future<void> addMaterial({
    required String name,
    required String unit,
    required double quantity,
    required double minThreshold,
  }) {
    if (!quantity.isFinite ||
        !minThreshold.isFinite ||
        quantity < 0 ||
        minThreshold < 0)
      throw StateError('كمية خامة غير صالحة');
    _text(name, 'اسم الخامة');
    _text(unit, 'وحدة الخامة');

    return _write(
      () => _db.upsertMaterial(
        MaterialItemsCompanion(
          id: Value(_uuid.v4()),
          name: Value(name),
          unit: Value(unit),
          quantity: Value(quantity),
          minThreshold: Value(minThreshold),
          updatedAt: Value(_now),
          isDeleted: const Value(false),
          dirty: const Value(true),
        ),
      ),
    );
  }

  Future<void> updateMaterial(
    MaterialItem material, {
    required String name,
    required String unit,
    required double quantity,
    required double minThreshold,
  }) {
    if (!quantity.isFinite ||
        !minThreshold.isFinite ||
        quantity < 0 ||
        minThreshold < 0)
      throw StateError('كمية خامة غير صالحة');
    _text(name, 'اسم الخامة');
    _text(unit, 'وحدة الخامة');

    return _write(
      () => _db.updateMaterialFields(
        MaterialItemsCompanion(
          id: Value(material.id),
          name: Value(name),
          unit: Value(unit),
          quantity: Value(quantity),
          minThreshold: Value(minThreshold),
          updatedAt: Value(_now),
          dirty: const Value(true),
        ),
      ),
    );
  }

  Future<void> adjustMaterialQuantity(MaterialItem material, double delta) =>
      _write(() async {
        if (!delta.isFinite) throw StateError('كمية غير صالحة');
        final fresh = await (_db.select(
          _db.materialItems,
        )..where((m) => m.id.equals(material.id))).getSingleOrNull();
        if (fresh == null || fresh.isDeleted)
          throw StateError('الخامة غير موجودة');
        final quantity = ((fresh.quantity + delta) * 1000000).round() / 1000000;
        if (quantity < 0) throw StateError('الكمية أكبر من الرصيد المتاح');
        await _db.updateMaterialFields(
          MaterialItemsCompanion(
            id: Value(fresh.id),
            quantity: Value(quantity),
            updatedAt: Value(_now),
            dirty: const Value(true),
          ),
        );
      });

  Future<void> deleteMaterial(String id) =>
      _write(() => _db.softDeleteMaterial(id));
}
