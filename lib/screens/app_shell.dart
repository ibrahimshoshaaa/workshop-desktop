import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/sync_provider.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'orders_screen.dart';
import 'debts_screen.dart';
import 'expenses_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';

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
    (Icons.summarize_rounded, 'التقارير'),
  ];

  static const _screens = [
    DashboardScreen(),
    CustomersScreen(),
    OrdersScreen(),
    DebtsScreen(),
    ExpensesScreen(),
    InventoryScreen(),
    ReportsScreen(),
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
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SyncButton(),
                ),
              ),
            ),
            destinations: _destinations.map((d) => NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2))).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_index]),
        ],
      ),
    );
  }
}

/// زرار مزامنة يدوي - يظهر تحت الشريط الجانبي، يفيد لما تعرف إن فيه
/// تعديل حصل على الموبايل وعايز تشوفه فورًا من غير ما تستنى الدورة التلقائية
class _SyncButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    await ref.read(syncServiceProvider).syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'مزامنة الآن',
      onPressed: _isSyncing ? null : _sync,
      icon: _isSyncing
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
            )
          : const Icon(Icons.sync_rounded, color: AppColors.amber),
    );
  }
}
