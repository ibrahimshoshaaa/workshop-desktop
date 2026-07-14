import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/sync_provider.dart';
import '../providers/navigation_provider.dart';   // 👈 جديد
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'orders_screen.dart';
import 'debts_screen.dart';
import 'expenses_screen.dart';
import 'inventory_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AppShell extends ConsumerWidget {          // 👈 كان StatefulWidget، بقى ConsumerWidget
  const AppShell({super.key});

  static const _destinations = [
    (Icons.dashboard_rounded, 'الرئيسية'),
    (Icons.people_alt_rounded, 'العملاء'),
    (Icons.checkroom_rounded, 'الطلبات'),
    (Icons.account_balance_wallet_rounded, 'المديونيات'),
    (Icons.receipt_long_rounded, 'المصروفات'),
    (Icons.inventory_2_rounded, 'المخزون'),
    (Icons.summarize_rounded, 'التقارير'),
    (Icons.settings_rounded, 'الإعدادات'),
  ];

  static const _screens = [
    DashboardScreen(),
    CustomersScreen(),
    OrdersScreen(),
    DebtsScreen(),
    ExpensesScreen(),
    InventoryScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {              // 👈 بقت build(context, ref)
    final index = ref.watch(selectedTabProvider);                  // 👈 بدل _index

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,  // 👈 بدل setState
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SyncButton(),
                      Consumer(
                        builder: (context, ref, _) {
                          final authAsync = ref.watch(authSettingsProvider);
                          final protectionEnabled = authAsync.value?.enabled ?? false;
                          if (!protectionEnabled) return const SizedBox.shrink();
                          return IconButton(
                            tooltip: 'تسجيل الخروج',
                            onPressed: () => ref.read(isLoggedInProvider.notifier).state = false,
                            icon: const Icon(Icons.logout_rounded, color: AppColors.amber),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _destinations.map((d) => NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2))).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[index]),
        ],
      ),
    );
  }
}

// _SyncButton يفضل زي ما هو من غير أي تغيير
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
