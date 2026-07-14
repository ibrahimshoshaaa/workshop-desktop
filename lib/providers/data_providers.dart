import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/local_repository.dart';
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

/// مصروفات مرتبطة بطلب معيّن فقط - بنستخدمه في ديالوج تفاصيل الطلب
final orderExpensesProvider = StreamProvider.family<List<Expense>, String>((ref, orderId) {
  return ref.watch(databaseProvider).watchExpensesForOrder(orderId);
});

final materialsProvider = StreamProvider<List<MaterialItem>>((ref) {
  return ref.watch(databaseProvider).watchMaterials();
});

final debtorOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  return orders.where((o) => o.totalAmount - o.totalPaid > 0).toList()
    ..sort((a, b) => (b.totalAmount - b.totalPaid).compareTo(a.totalAmount - a.totalPaid));
});

final lowStockMaterialsProvider = Provider<List<MaterialItem>>((ref) {
  final materials = ref.watch(materialsProvider).value ?? [];
  return materials.where((m) => m.quantity <= m.minThreshold).toList();
});

class DashboardStats {
  final double totalRevenue;
  final double totalDebts;
  final double totalExpenses;
  final double netProfit;
  DashboardStats({
    required this.totalRevenue,
    required this.totalDebts,
    required this.totalExpenses,
    required this.netProfit,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final orders = ref.watch(ordersProvider).value ?? [];
  final expenses = ref.watch(expensesProvider).value ?? [];
  final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPaid);
  final totalDebts = orders.fold<double>(0, (s, o) => s + (o.totalAmount - o.totalPaid));
  final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
  return DashboardStats(
    totalRevenue: totalRevenue,
    totalDebts: totalDebts,
    totalExpenses: totalExpenses,
    netProfit: totalRevenue - totalExpenses,
  );
});
