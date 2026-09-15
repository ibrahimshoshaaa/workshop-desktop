import 'package:drift/drift.dart';
import '../data/database.dart';
import '../core/order_calculations.dart';

/// منطق أرشفة العميل واسترجاعه بالكامل.
///
/// الأرشيف حالة مستقلة عن الحذف الحقيقي:
/// - isDeleted = حذف حقيقي للمزامنة.
/// - isArchived = إخفاء مؤقت من القوائم والإجماليات.
/// - العميل وطلباته بيتأرشفوا ويرجعوا معًا.
class CustomerArchiveService {
  CustomerArchiveService(this._db);
  final AppDatabase _db;

  Future<String?> getArchiveBlockReason(String customerId) async {
    final orders = await (_db.select(_db.orders)
          ..where((o) =>
              o.customerId.equals(customerId) &
              o.isDeleted.equals(false) &
              o.isArchived.equals(false)))
        .get();

    for (final order in orders) {
      if (order.remaining > 0.01) {
        return 'لا يمكن أرشفة العميل لأن عليه مبلغًا متبقيًا في أحد الطلبات.';
      }
      if (order.status != 'تم التسليم') {
        return 'لا يمكن أرشفة العميل لأن لديه طلبًا لم يتم تسليمه بعد.';
      }
    }
    return null;
  }

  Future<int> archiveCustomer(String customerId) async {
    final reason = await getArchiveBlockReason(customerId);
    if (reason != null) throw StateError(reason);

    return _db.transaction(() async {
      final customer = await (_db.select(_db.customers)
            ..where((c) =>
                c.id.equals(customerId) &
                c.isDeleted.equals(false) &
                c.isArchived.equals(false)))
          .getSingleOrNull();
      if (customer == null)
        throw StateError('العميل غير موجود أو مؤرشف بالفعل.');

      final orders = await (_db.select(_db.orders)
            ..where((o) =>
                o.customerId.equals(customerId) &
                o.isDeleted.equals(false) &
                o.isArchived.equals(false)))
          .get();

      for (final order in orders) {
        if (order.remaining > 0.01 || order.status != 'تم التسليم') {
          throw StateError(
              'لا يمكن أرشفة العميل لأن لديه طلبًا غير مكتمل أو عليه مبلغ متبقٍ.');
        }
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.customers)..where((c) => c.id.equals(customerId)))
          .write(
        CustomersCompanion(
          isArchived: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );

      for (final order in orders) {
        await (_db.update(_db.orders)..where((o) => o.id.equals(order.id)))
            .write(
          OrdersCompanion(
            isArchived: const Value(true),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
      return orders.length;
    });
  }

  Future<int> reactivateCustomer(String customerId) async {
    return _db.transaction(() async {
      final customer = await (_db.select(_db.customers)
            ..where((c) =>
                c.id.equals(customerId) &
                c.isDeleted.equals(false) &
                c.isArchived.equals(true)))
          .getSingleOrNull();
      if (customer == null) throw StateError('العميل غير موجود في الأرشيف.');

      final orders = await (_db.select(_db.orders)
            ..where((o) =>
                o.customerId.equals(customerId) &
                o.isDeleted.equals(false) &
                o.isArchived.equals(true)))
          .get();

      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.customers)..where((c) => c.id.equals(customerId)))
          .write(
        CustomersCompanion(
          isArchived: const Value(false),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );

      for (final order in orders) {
        await (_db.update(_db.orders)..where((o) => o.id.equals(order.id)))
            .write(
          OrdersCompanion(
            isArchived: const Value(false),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
      return orders.length;
    });
  }
}
