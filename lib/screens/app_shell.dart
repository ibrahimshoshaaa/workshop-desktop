import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'orders_screen.dart';
import 'debts_screen.dart';
import 'expenses_screen.dart';
import 'inventory_screen.dart';

/// الهيكل الرئيسي لتطبيق سطح المكتب - شريط جانبي (NavigationRail) بدل
/// الشريط السفلي المستخدم في نسخة الموبايل، وده الأنسب لشاشات الكمبيوتر
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (Icons.dashboard_rounded, 'الرئيسية'),
    (Icons.people_alt_rounded, 'العملاء'),
    (Icons.checkroom_rounded, 'الطلبات'),
    (Icons.account_balance_wallet_rounded, 'المديونيات'),
    (Icons.receipt_long_rounded, 'المصروفات'),
    (Icons.inventory_2_rounded, 'المخزون'),
  ];

  static const _screens = [
    DashboardScreen(),
    CustomersScreen(),
    OrdersScreen(),
    DebtsScreen(),
    ExpensesScreen(),
    InventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: AppColors.woodDark,
            selectedIconTheme: const IconThemeData(color: AppColors.amber),
            unselectedIconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.6)),
            selectedLabelTextStyle: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.chair_alt_rounded, color: AppColors.amber, size: 32),
            ),
            destinations: _destinations
                .map((d) => NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2)))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }
}
