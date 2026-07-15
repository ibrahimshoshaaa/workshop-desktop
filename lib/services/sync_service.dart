import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' show Value;
import '../data/database.dart';

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
      await _syncCustomers();
      await _syncOrders();
      await _syncTransactions();
      await _syncExpenses();
      await _syncMaterials();
      await _db.setMeta('lastSyncAt', DateTime.now().millisecondsSinceEpoch.toString());
      if (onSynced != null) await onSynced!();
    } catch (_) {
      // غالبًا مفيش نت - هنحاول تاني في الدورة الجاية من غير ما نوقف التطبيق
    } finally {
      _isSyncing = false;
    }
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
          'date': row.date,
        });
        await _db.updateExpenseFields(ExpensesCompanion(id: Value(row.id), dirty: const Value(false)));
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

  // ---------------- HTTP Helpers ----------------

  Future<Map<String, dynamic>?> _fetchNode(String path) async {
    final response = await http.get(Uri.parse('$_baseUrl/$path.json')).timeout(_timeout);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return decoded.cast<String, dynamic>();
  }

  Future<void> _putNode(String path, Map<String, dynamic> data) async {
    await http.put(Uri.parse('$_baseUrl/$path.json'), body: jsonEncode(data)).timeout(_timeout);
  }

  Future<void> _deleteNode(String path) async {
    await http.delete(Uri.parse('$_baseUrl/$path.json')).timeout(_timeout);
  }
}
