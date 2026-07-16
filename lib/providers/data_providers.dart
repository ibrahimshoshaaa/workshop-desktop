import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/local_repository.dart';
import '../core/order_calculations.dart';
import 'database_provider.dart';

final repositoryProvider = Provider<LocalRepository>((ref) {
  return LocalRepository(ref.watch(databaseProvider));
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(databaseProvider).watchCustomers();
});

final ordersProvider = StreamProvider<List<Order>>((ref) {
  return ref.watch(databaseProvider).watchOrders();
});

final allTransactionsProvider = StreamProvider<List<PaymentTransaction>>((ref) {
  return ref.watch(databaseProvider).watchAllTransactions();
});

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(databaseProvider).watchExpenses();
});

/// حصة طلب معيّن من مصروف (ممكن يكون المصروف مقسّم على أكتر من طلب،
/// فـ [shareAmount] هنا هو نصيب الطلب ده بس، مش إجمالي المصروف كامل)
class OrderExpenseShare {
  final Expense expense;
  final double shareAmount;
  final int totalOrdersCount;
  const OrderExpenseShare({required this.expense, required this.shareAmount, required this.totalOrdersCount});
}

/// مصروفات مرتبطة بطلب معيّن فقط - بتاخد في الاعتبار المصروفات المقسّمة
/// على أكتر من طلب (كل طلب بياخد نصيبه بس، مش المصروف كامل)
final orderExpensesProvider = Provider.family<List<OrderExpenseShare>, String>((ref, orderId) {
  final expenses = ref.watch(expensesProvider).value ?? [];
  final result = <OrderExpenseShare>[];
  for (final e in expenses) {
    final allocs = e.allocations;
    final match = allocs.where((a) => a.orderId == orderId).toList();
    if (match.isEmpty) continue;
    final shareAmount = match.fold<double>(0, (s, a) => s + a.amount);
    result.add(OrderExpenseShare(expense: e, shareAmount: shareAmount, totalOrdersCount: allocs.length));
  }
  return result;
});

final materialsProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(databaseProvider).watchMaterials();
});

final workersProvider = StreamProvider<List<Worker>>((ref) {
  return ref.watch(databaseProvider).watchWorkers();
});

final workerPaymentsProvider = StreamProvider<List<WorkerPayment>>((ref) {
  return ref.watch(databaseProvider).watchWorkerPayments();
});

/// سجل قبض عامل معيّن بس - بنستخدمه في ديالوج تفاصيل العامل
final workerPaymentsForWorkerProvider = StreamProvider.family<List<WorkerPayment>, String>((ref, workerId) {
  return ref.watch(databaseProvider).watchPaymentsForWorker(workerId);
});

/// بيحسب بداية دورة الاستحقاق الحالية (منتصف الليل) لعامل معيّن حسب
/// نوع مرتبه: يومي = النهاردة، أسبوعي = آخر (أو نفس) يوم القبض المحدد،
/// شهري = أول يوم في الشهر الحالي
DateTime workerPeriodAnchor(Worker worker, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (worker.salaryType) {
    case 'weekly':
      final diff = (now.weekday - worker.payWeekday + 7) % 7;
      return today.subtract(Duration(days: diff));
    case 'monthly':
      return DateTime(now.year, now.month, 1);
    default: // daily
      return today;
  }
}

bool isWorkerPaidForCurrentPeriod(Worker worker, List<WorkerPayment> payments, DateTime now) {
  final anchor = workerPeriodAnchor(worker, now);
  return payments.any((p) => p.workerId == worker.id && DateTime.fromMillisecondsSinceEpoch(p.periodStart).isAtSameMomentAs(anchor));
}

/// العمال الأسبوعيين اللي موعد قبضهم النهاردة بالظبط ولسه ما اتأكدش
/// دفعهم - ده اللي بيبني عليه بانر "موعد القبض" في صفحة العمال والرئيسية
final workersDueTodayProvider = Provider<List<Worker>>((ref) {
  final workers = ref.watch(workersProvider).value ?? [];
  final payments = ref.watch(workerPaymentsProvider).value ?? [];
  final now = DateTime.now();
  return workers.where((w) {
    if (w.salaryType != 'weekly' || w.payWeekday != now.weekday) return false;
    return !isWorkerPaidForCurrentPeriod(w, payments, now);
  }).toList();
});

final debtorOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  return orders.where((o) => o.remaining > 0).toList()..sort((a, b) => b.remaining.compareTo(a.remaining));
});

/// مديونيات الورشة (لصالح الموردين/الصنايعية) - عكس [debtorOrdersProvider]
final workshopDebtsProvider = StreamProvider<List<WorkshopDebt>>((ref) {
  return ref.watch(databaseProvider).watchWorkshopDebts();
});

final outstandingWorkshopDebtsProvider = Provider<List<WorkshopDebt>>((ref) {
  final debts = ref.watch(workshopDebtsProvider).value ?? [];
  return debts.where((d) => d.remaining > 0).toList()..sort((a, b) => b.remaining.compareTo(a.remaining));
});

final lowStockMaterialsProvider = Provider<List<MaterialItem>>((ref) {
  final materials = ref.watch(materialsProvider).value ?? [];
  return materials.where((m) => m.quantity <= m.minThreshold).toList();
});

/// الطلبات اللي معاد تسليمها خلال الأسبوع الجاي (من دلوقتي لحد بعد 7
/// أيام) ولسه ماتسلمتش - بنستخدمها في بانر "التسليمات القادمة" بالرئيسية
final upcomingDeliveriesProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekAhead = today.add(const Duration(days: 7));
  return orders.where((o) {
    if (o.status == 'تم التسليم') return false;
    final delivery = DateTime.fromMillisecondsSinceEpoch(o.deliveryDate);
    return !delivery.isBefore(today) && delivery.isBefore(weekAhead);
  }).toList()
    ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
});

class DashboardStats {
  final double totalRevenue;
  final double totalDebts;
  final double totalExpenses;
  final double netProfit;
  /// تفنيط "المبلغ المتاح" حسب مصدره: كاش/إنستاباي - كل واحد فيهم = ما
  /// دخل من دفعات بنفس الطريقة ناقص المصروفات اللي خرجت من نفس المصدر
  final double cashAvailable;
  final double instapayAvailable;
  final double totalWorkshopDebts;
  DashboardStats({
    required this.totalRevenue,
    required this.totalDebts,
    required this.totalExpenses,
    required this.netProfit,
    required this.cashAvailable,
    required this.instapayAvailable,
    required this.totalWorkshopDebts,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final expenses = ref.watch(expensesProvider).value ?? [];
  final transactions = ref.watch(allTransactionsProvider).value ?? [];
  final workshopDebts = ref.watch(workshopDebtsProvider).value ?? [];

  final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPaid);
  final totalDebts = orders.fold<double>(0, (s, o) => s + o.remaining);
  final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
  final totalWorkshopDebts = workshopDebts.fold<double>(0, (s, d) => s + d.remaining);

  double revenueByMethod(String method) {
    // بنستبعد أي دفعة مرتبطة بطلب اتحذف - الطلب لما بيتحذف بيفضل تاريخ
    // الدفعات بتاعته موجود في جدول الدفعات (مش بيتمسح تلقائي معاه)، فلو
    // حسبناها كلها هيبان "المتاح" أعلى من الإيرادات نفسها وده رقم غلط
    final liveOrderIds = orders.map((o) => o.id).toSet();
    return transactions
        .where((t) => t.paymentMethod == method && liveOrderIds.contains(t.orderId))
        .fold<double>(0, (s, t) => s + t.amountPaid);
  }

  double expensesByMethod(String method) =>
      expenses.where((e) => e.paymentMethod == method).fold<double>(0, (s, e) => s + e.amount);

  final cashAvailable = revenueByMethod('cash') - expensesByMethod('cash');
  final instapayAvailable = revenueByMethod('instapay') - expensesByMethod('instapay');

  return DashboardStats(
    totalRevenue: totalRevenue,
    totalDebts: totalDebts,
    totalExpenses: totalExpenses,
    netProfit: totalRevenue - totalExpenses,
    cashAvailable: cashAvailable,
    instapayAvailable: instapayAvailable,
    totalWorkshopDebts: totalWorkshopDebts,
  );
});
