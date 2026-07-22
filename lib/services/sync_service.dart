import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../data/database.dart';
import 'firebase_rest_auth.dart';

/// خدمة المزامنة مع Firebase Realtime Database عن طريق REST API مباشرة
/// (مفيش SDK رسمي لويندوز). المنطق: أي سجل "متغيّر" محليًا (dirty) بيتبعت
/// لـ Firebase، وأي سجل جديد/أحدث من Firebase بينزل محليًا، على أساس
/// "آخر تعديل بيكسب" (Last-Write-Wins) بمقارنة updatedAt.
class SyncService {
  SyncService(this._db, {required String databaseUrl, this.onSynced}) : _baseUrl = databaseUrl;

  final AppDatabase _db;
  final String _baseUrl; // مثال: https://workshopmanage-e7555-default-rtdb.firebaseio.com
  /// بيتنادى (لو موجود) بعد كل دورة مزامنة ناجحة - بنستخدمه لتحديث صلاحيات
  /// المستخدم الحالي من غير ما نربط SyncService مباشرة بمنطق الصلاحيات
  final Future<void> Function()? onSynced;

  static const _timeout = Duration(seconds: 10);
  Timer? _periodicTimer;
  bool _isSyncing = false;

  /// يبدأ مزامنة دورية كل [interval] - بيتجاهل أي خطأ (زي انقطاع النت)
  /// بصمت ويحاول تاني في الدورة الجاية
  void startPeriodicSync({Duration interval = const Duration(minutes: 2)}) {
    _periodicTimer?.cancel();
    syncAll();
    _periodicTimer = Timer.periodic(interval, (_) => syncAll());
  }

  void dispose() => _periodicTimer?.cancel();

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      await _repairMissingDiscountsOnce();
      await _syncCustomers();
      await _syncOrders();
      await _syncTransactions();
      await _syncExpenses();
      await _syncWorkshopDebts();
      await _syncMaterials();
      await _syncWorkers();
      await _syncWorkerPayments();
      await _syncCashTransfers();
      await _repairMissingOverpaymentDebtsOnce();
      await _db.setMeta('lastSyncAt', DateTime.now().millisecondsSinceEpoch.toString());
      if (onSynced != null) await onSynced!();
    } catch (_) {
      // غالبًا مفيش نت - هنحاول تاني في الدورة الجاية من غير ما نوقف التطبيق
    } finally {
      _isSyncing = false;
    }
  }

  /// إصلاح لمرة واحدة بس: قبل التصليح، الطلبات اللي عليها خصم كانت
  /// بتتزامن مع Firebase من غير ما يترفع فيها discountAmount/discountReason
  /// (باگ في _syncOrders) - فالطلبات دي كانت وصلت لـ Firebase وهي "نضيفة"
  /// (dirty = false) بمبلغ الخصم فيها صفر، فمش هتترفع تاني لوحدها. الدالة
  /// دي بتحدد الطلبات اللي عندها خصم محلي (discountAmount != 0) وترجّعها
  /// "متغيّرة" (dirty) عشان تتبعت تاني في نفس دورة المزامنة دي بالمنطق
  /// المُصلَّح، وده بيحصل مرة واحدة بس في عمر التطبيق (معلّم بمفتاح ميتا).
  Future<void> _repairMissingDiscountsOnce() async {
    final done = await _db.getMeta('discountSyncRepairDone');
    if (done == '1') return;
    final allOrders = await _db.select(_db.orders).get();
    final discounted = allOrders.where((row) => row.discountAmount > 0).toList();
    for (final row in discounted) {
      await _db.updateOrderFields(OrdersCompanion(
        id: Value(row.id),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        dirty: const Value(true),
      ));
    }
    await _db.setMeta('discountSyncRepairDone', '1');
  }

  /// إصلاح لمرة واحدة بس: طلبات كانت موجودة أصلاً قبل ما ميزة "مديونية
  /// الورشة التلقائية عند الدفع الزيادة" تتضاف - الطلبات دي ممكن يكون
  /// العميل فيها دفع أكتر من الاتفاق النهائي من زمان (دفعة قديمة أو
  /// تعديل سعر قديم) من غير ما حد يسجّلها كمديونية، لأن المنطق الجديد
  /// بيتفعّل بس وقت إضافة دفعة أو تعديل سعر جديد، مش بيراجع القديم
  /// تلقائي. الدالة دي بتراجع كل الطلبات مرة واحدة بس (معلّمة بمفتاح
  /// ميتا) وتصلّح أي حالة زيادة قديمة كانت فاتت
  Future<void> _repairMissingOverpaymentDebtsOnce() async {
    final done = await _db.getMeta('overpaymentDebtRepairDone');
    if (done == '1') return;
    final orders = await (_db.select(_db.orders)..where((t) => t.isDeleted.equals(false))).get();
    for (final order in orders) {
      final overpaid = order.totalPaid - (order.totalAmount - order.discountAmount);
      final existing = await (_db.select(_db.workshopDebts)
            ..where((t) => t.orderId.equals(order.id) & t.isDeleted.equals(false)))
          .getSingleOrNull();

      if (overpaid <= 0) {
        if (existing != null) {
          await _db.softDeleteWorkshopDebt(existing.id);
        }
        continue;
      }

      if (existing == null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await _db.upsertWorkshopDebt(WorkshopDebtsCompanion(
          id: Value(const Uuid().v4()),
          creditorName: Value(order.customerName),
          totalAmount: Value(overpaid),
          paidAmount: const Value(0),
          notes: Value('دفع أكتر من الاتفاق النهائي على طلب "${order.itemType}" (تصليح تلقائي لطلب قديم)'),
          orderId: Value(order.id),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDeleted: const Value(false),
          dirty: const Value(true),
        ));
      } else if (existing.totalAmount != overpaid) {
        await _db.updateWorkshopDebtFields(WorkshopDebtsCompanion(
          id: Value(existing.id),
          totalAmount: Value(overpaid),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          dirty: const Value(true),
        ));
      }
    }
    await _db.setMeta('overpaymentDebtRepairDone', '1');
  }

  // ---------------- Customers ----------------

  Future<void> _syncCustomers() async {
    final remote = await _fetchNode('customers');
    final localRows = await _db.select(_db.customers).get();
    final localById = {for (final c in localRows) c.id: c};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertCustomer(CustomersCompanion(
            id: Value(id),
            name: Value(map['name']?.toString() ?? ''),
            phone: Value(map['phone']?.toString() ?? ''),
            address: Value(map['address']?.toString() ?? ''),
            serialNumber: Value((map['serialNumber'] as num?)?.toInt() ?? local?.serialNumber ?? 0),
            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.customers)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.customers)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('customers/${row.id}');
        await (_db.delete(_db.customers)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('customers/${row.id}', {
          'name': row.name,
          'phone': row.phone,
          'address': row.address,
          'serialNumber': row.serialNumber,
          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
        });
        await _db.updateCustomerFields(CustomersCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Orders ----------------

  Future<void> _syncOrders() async {
    final remote = await _fetchNode('orders');
    final localRows = await _db.select(_db.orders).get();
    final localById = {for (final o in localRows) o.id: o};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          final imagesRaw = map['images'];
          final images = <String>[];
          if (imagesRaw is Map) {
            images.addAll(imagesRaw.values.map((v) => v.toString()));
          } else if (imagesRaw is List) {
            images.addAll(imagesRaw.map((v) => v.toString()));
          }
          await _db.upsertOrder(OrdersCompanion(
            id: Value(id),
            customerId: Value(map['customerId']?.toString() ?? ''),
            customerName: Value(map['customerName']?.toString() ?? ''),
            itemType: Value(map['itemType']?.toString() ?? ''),
            details: Value(map['details']?.toString() ?? ''),
            imagesJson: Value(jsonEncode(images)),
            status: Value(map['status']?.toString() ?? 'جاري التجهيز'),
            totalAmount: Value((map['totalAmount'] as num?)?.toDouble() ?? 0),
            totalPaid: Value((map['totalPaid'] as num?)?.toDouble() ?? 0),
            discountAmount: Value((map['discountAmount'] as num?)?.toDouble() ?? 0),
            discountReason: Value(map['discountReason']?.toString() ?? ''),
            deliveryDate: Value((map['deliveryDate'] as num?)?.toInt() ?? remoteUpdatedAt),
            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.orders)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.orders)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('orders/${row.id}');
        await (_db.delete(_db.orders)..where((t) => t.id.equals(row.id))).go();
      } else {
        final images = (jsonDecode(row.imagesJson) as List).map((e) => e.toString()).toList();
        await _putNode('orders/${row.id}', {
          'customerId': row.customerId,
          'customerName': row.customerName,
          'itemType': row.itemType,
          'details': row.details,
          'images': images,
          'status': row.status,
          'totalAmount': row.totalAmount,
          'totalPaid': row.totalPaid,
          'discountAmount': row.discountAmount,
          'discountReason': row.discountReason,
          'deliveryDate': row.deliveryDate,
          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
        });
        await _db.updateOrderFields(OrdersCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Payment Transactions ----------------

  Future<void> _syncTransactions() async {
    final remote = await _fetchNode('transactions');
    final localRows = await _db.select(_db.paymentTransactions).get();
    final localById = {for (final t in localRows) t.id: t};

    final touchedOrderIds = <String>{};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['paymentDate'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          final orderId = map['orderId']?.toString() ?? '';
          await _db.upsertTransaction(PaymentTransactionsCompanion(
            id: Value(id),
            orderId: Value(orderId),
            customerId: Value(map['customerId']?.toString() ?? ''),
            amountPaid: Value((map['amountPaid'] as num?)?.toDouble() ?? 0),
            paymentDate: Value((map['paymentDate'] as num?)?.toInt() ?? remoteUpdatedAt),
            paymentType: Value(map['paymentType']?.toString() ?? 'installment'),
            paymentMethod: Value(map['paymentMethod']?.toString() ?? 'cash'),
            status: Value(map['status']?.toString() ?? 'completed'),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
          touchedOrderIds.add(orderId);
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        touchedOrderIds.add(local.orderId);
        await (_db.delete(_db.paymentTransactions)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.paymentTransactions)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      touchedOrderIds.add(row.orderId);
      if (row.isDeleted) {
        await _deleteNode('transactions/${row.id}');
        await (_db.delete(_db.paymentTransactions)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('transactions/${row.id}', {
          'orderId': row.orderId,
          'customerId': row.customerId,
          'amountPaid': row.amountPaid,
          'paymentDate': row.paymentDate,
          'paymentType': row.paymentType,
          'paymentMethod': row.paymentMethod,
          'status': row.status,
        });
        await _db.updateTransactionFields(PaymentTransactionsCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }

    for (final orderId in touchedOrderIds) {
      if (orderId.isEmpty) continue;
      await _db.recomputeOrderTotalPaid(orderId);
    }
  }

  // ---------------- Expenses ----------------

  Future<void> _syncExpenses() async {
    final remote = await _fetchNode('expenses');
    final localRows = await _db.select(_db.expenses).get();
    final localById = {for (final e in localRows) e.id: e};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['date'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertExpense(ExpensesCompanion(
            id: Value(id),
            amount: Value((map['amount'] as num?)?.toDouble() ?? 0),
            category: Value(map['category']?.toString() ?? 'other'),
            description: Value(map['description']?.toString() ?? ''),
            workerName: Value(map['workerName']?.toString()),
            orderId: Value(map['orderId']?.toString()),
            customerId: Value(map['customerId']?.toString()),
            customerName: Value(map['customerName']?.toString()),
            paymentMethod: Value(map['paymentMethod']?.toString() ?? 'cash'),
            workshopDebtId: Value(map['workshopDebtId']?.toString()),
            orderAllocationsJson: Value(map['orderAllocationsJson']?.toString() ?? '[]'),
            date: Value((map['date'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.expenses)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.expenses)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('expenses/${row.id}');
        await (_db.delete(_db.expenses)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('expenses/${row.id}', {
          'amount': row.amount,
          'category': row.category,
          'description': row.description,
          if (row.workerName != null) 'workerName': row.workerName,
          if (row.orderId != null) 'orderId': row.orderId,
          if (row.customerId != null) 'customerId': row.customerId,
          if (row.customerName != null) 'customerName': row.customerName,
          'paymentMethod': row.paymentMethod,
          if (row.workshopDebtId != null) 'workshopDebtId': row.workshopDebtId,
          'orderAllocationsJson': row.orderAllocationsJson,
          'date': row.date,
        });
        await _db.updateExpenseFields(ExpensesCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Workshop Debts ----------------

  Future<void> _syncWorkshopDebts() async {
    final remote = await _fetchNode('workshopDebts');
    final localRows = await _db.select(_db.workshopDebts).get();
    final localById = {for (final d in localRows) d.id: d};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertWorkshopDebt(WorkshopDebtsCompanion(
            id: Value(id),
            creditorName: Value(map['creditorName']?.toString() ?? ''),
            totalAmount: Value((map['totalAmount'] as num?)?.toDouble() ?? 0),
            paidAmount: Value((map['paidAmount'] as num?)?.toDouble() ?? 0),
            notes: Value(map['notes']?.toString() ?? ''),
            orderId: Value(map['orderId']?.toString() ?? ''),
            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.workshopDebts)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.workshopDebts)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('workshopDebts/${row.id}');
        await (_db.delete(_db.workshopDebts)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('workshopDebts/${row.id}', {
          'creditorName': row.creditorName,
          'totalAmount': row.totalAmount,
          'paidAmount': row.paidAmount,
          'notes': row.notes,
          'orderId': row.orderId,
          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
        });
        await _db.updateWorkshopDebtFields(WorkshopDebtsCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Cash Transfers (سحب إنستاباي كاش) ----------------

  Future<void> _syncCashTransfers() async {
    final remote = await _fetchNode('cashTransfers');
    final localRows = await _db.select(_db.cashTransfers).get();
    final localById = {for (final t in localRows) t.id: t};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['date'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertCashTransfer(CashTransfersCompanion(
            id: Value(id),
            amount: Value((map['amount'] as num?)?.toDouble() ?? 0),
            note: Value(map['note']?.toString() ?? ''),
            date: Value((map['date'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.cashTransfers)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.cashTransfers)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('cashTransfers/${row.id}');
        await (_db.delete(_db.cashTransfers)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('cashTransfers/${row.id}', {
          'amount': row.amount,
          'note': row.note,
          'date': row.date,
          'updatedAt': row.updatedAt,
        });
        await _db.updateCashTransferFields(CashTransfersCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Materials ----------------

  Future<void> _syncMaterials() async {
    final remote = await _fetchNode('materials');
    final localRows = await _db.select(_db.materialItems).get();
    final localById = {for (final m in localRows) m.id: m};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertMaterial(MaterialItemsCompanion(
            id: Value(id),
            name: Value(map['name']?.toString() ?? ''),
            unit: Value(map['unit']?.toString() ?? 'قطعة'),
            quantity: Value((map['quantity'] as num?)?.toDouble() ?? 0),
            minThreshold: Value((map['minThreshold'] as num?)?.toDouble() ?? 0),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.materialItems)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.materialItems)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('materials/${row.id}');
        await (_db.delete(_db.materialItems)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('materials/${row.id}', {
          'name': row.name,
          'unit': row.unit,
          'quantity': row.quantity,
          'minThreshold': row.minThreshold,
          'updatedAt': row.updatedAt,
        });
        await _db.updateMaterialFields(MaterialItemsCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Workers ----------------

  Future<void> _syncWorkers() async {
    final remote = await _fetchNode('workers');
    final localRows = await _db.select(_db.workers).get();
    final localById = {for (final w in localRows) w.id: w};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['createdAt'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertWorker(WorkersCompanion(
            id: Value(id),
            name: Value(map['name']?.toString() ?? ''),
            jobTitle: Value(map['jobTitle']?.toString() ?? ''),
            salaryType: Value(map['salaryType']?.toString() ?? 'monthly'),
            salaryAmount: Value((map['salaryAmount'] as num?)?.toDouble() ?? 0),
            payWeekday: Value((map['payWeekday'] as num?)?.toInt() ?? 4),
            phone: Value(map['phone']?.toString() ?? ''),
            notes: Value(map['notes']?.toString() ?? ''),
            createdAt: Value((map['createdAt'] as num?)?.toInt() ?? remoteUpdatedAt),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.workers)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.workers)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('workers/${row.id}');
        await (_db.delete(_db.workers)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('workers/${row.id}', {
          'name': row.name,
          'jobTitle': row.jobTitle,
          'salaryType': row.salaryType,
          'salaryAmount': row.salaryAmount,
          'payWeekday': row.payWeekday,
          'phone': row.phone,
          'notes': row.notes,
          'createdAt': row.createdAt,
          'updatedAt': row.updatedAt,
        });
        await _db.updateWorkerFields(WorkersCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- Worker Payments ----------------

  Future<void> _syncWorkerPayments() async {
    final remote = await _fetchNode('workerPayments');
    final localRows = await _db.select(_db.workerPayments).get();
    final localById = {for (final p in localRows) p.id: p};

    if (remote != null) {
      for (final entry in remote.entries) {
        final id = entry.key;
        final map = Map<String, dynamic>.from(entry.value as Map);
        final remoteUpdatedAt = (map['updatedAt'] as num?)?.toInt() ?? (map['paymentDate'] as num?)?.toInt() ?? 0;
        final local = localById[id];
        if (local == null || (!local.dirty && remoteUpdatedAt > local.updatedAt)) {
          await _db.upsertWorkerPayment(WorkerPaymentsCompanion(
            id: Value(id),
            workerId: Value(map['workerId']?.toString() ?? ''),
            workerName: Value(map['workerName']?.toString() ?? ''),
            amount: Value((map['amount'] as num?)?.toDouble() ?? 0),
            paymentDate: Value((map['paymentDate'] as num?)?.toInt() ?? remoteUpdatedAt),
            periodStart: Value((map['periodStart'] as num?)?.toInt() ?? remoteUpdatedAt),
            expenseId: Value(map['expenseId']?.toString()),
            updatedAt: Value(remoteUpdatedAt),
            isDeleted: const Value(false),
            dirty: const Value(false),
          ));
        }
      }
    }

    final remoteIds = remote?.keys.toSet() ?? {};
    for (final local in localById.values) {
      if (!local.dirty && !remoteIds.contains(local.id)) {
        await (_db.delete(_db.workerPayments)..where((t) => t.id.equals(local.id))).go();
      }
    }

    final dirtyRows = await (_db.select(_db.workerPayments)..where((t) => t.dirty.equals(true))).get();
    for (final row in dirtyRows) {
      if (row.isDeleted) {
        await _deleteNode('workerPayments/${row.id}');
        await (_db.delete(_db.workerPayments)..where((t) => t.id.equals(row.id))).go();
      } else {
        await _putNode('workerPayments/${row.id}', {
          'workerId': row.workerId,
          'workerName': row.workerName,
          'amount': row.amount,
          'paymentDate': row.paymentDate,
          'periodStart': row.periodStart,
          if (row.expenseId != null) 'expenseId': row.expenseId,
          'updatedAt': row.updatedAt,
        });
        await _db.updateWorkerPaymentFields(WorkerPaymentsCompanion(id: Value(row.id), dirty: const Value(false)));
      }
    }
  }

  // ---------------- HTTP Helpers ----------------
  // كل نداء هنا بيعدّي على FirebaseRestAuth.withAuth() عشان يضيف توكن
  // الدخول الحالي - من غيره قواعد الأمان (auth != null) هترفض أي طلب

  Future<Map<String, dynamic>?> _fetchNode(String path) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return decoded.cast<String, dynamic>();
  }

  Future<void> _putNode(String path, Map<String, dynamic> data) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    await http.put(uri, body: jsonEncode(data)).timeout(_timeout);
  }

  Future<void> _deleteNode(String path) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$path.json'));
    await http.delete(uri).timeout(_timeout);
  }
}
