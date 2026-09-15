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
          ..where((o) => o.customerId.equals(customerId) & o.isDeleted.equals(false) & o.isArchived.equals(false)))
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

    final now = DateTime.now().millisecondsSinceEpoch;
    final orders = await (_db.select(_db.orders)
          ..where((o) => o.customerId.equals(customerId) & o.isDeleted.equals(false) & o.isArchived.equals(false)))
        .get();

    await (_db.update(_db.customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        isArchived: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );

    for (final order in orders) {
      await (_db.update(_db.orders)..where((o) => o.id.equals(order.id))).write(
        OrdersCompanion(
          isDeleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    return orders.length;
  }

  Future<int> reactivateCustomer(String customerId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final orders = await (_db.select(_db.orders)
          ..where((o) => o.customerId.equals(customerId) & o.isDeleted.equals(false) & o.isArchived.equals(true)))
        .get();

    await (_db.update(_db.customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        isArchived: const Value(false),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );

    for (final order in orders) {
      await (_db.update(_db.orders)..where((o) => o.id.equals(order.id))).write(
        OrdersCompanion(
          isDeleted: const Value(false),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    return orders.length;
  }
}
