import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/sync_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'orders_screen.dart';
import 'debts_screen.dart';
import 'workshop_debts_screen.dart';
import 'workers_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  // كل شاشة مرتبطة بمفتاح الصلاحية بتاعها. null = متاحة للكل دايمًا.
  // 'admin_only' = الأدمن بس (مش مرتبطة بصلاحيات المستخدم العادية)
  static const _allDestinations = [
    (Icons.dashboard_rounded, 'الرئيسية', null),
    (Icons.people_alt_rounded, 'العملاء', 'customers'),
    (Icons.checkroom_rounded, 'الطلبات', 'orders'),
    (Icons.account_balance_wallet_rounded, 'المديونيات', 'debts'),
    (Icons.store_rounded, 'مديونيات الورشة', 'debts'),
    (Icons.engineering_rounded, 'العمال', 'workers'),
    (Icons.receipt_long_rounded, 'المصروفات', 'expenses'),
    (Icons.summarize_rounded, 'التقارير', 'reports'),
    (Icons.settings_rounded, 'الإعدادات', 'admin_only'),
  ];

  static const _allScreens = [
    DashboardScreen(),
    CustomersScreen(),
    OrdersScreen(),
    DebtsScreen(),
    WorkshopDebtsScreen(),
    WorkersScreen(),
    ExpensesScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;

    // نبني قائمة الفهارس المسموحة بس حسب صلاحيات المستخدم الحالي
    final visibleIndexes = <int>[];
    for (var i = 0; i < _allDestinations.length; i++) {
      final permKey = _allDestinations[i].$3;
      if (permKey == null) {
        visibleIndexes.add(i);
      } else if (permKey == 'admin_only') {
        if (session?.isAdmin ?? false) visibleIndexes.add(i);
      } else if (session?.can(permKey) ?? true) {
        visibleIndexes.add(i);
      }
    }

    final destinations = visibleIndexes.map((i) => _allDestinations[i]).toList();
    final screens = visibleIndexes.map((i) => _allScreens[i]).toList();

    final rawIndex = ref.watch(selectedTabProvider);
    final index = screens.isEmpty ? 0 : rawIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,
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
                      IconButton(
                        tooltip: 'تسجيل الخروج',
                        onPressed: () => ref.read(authRepositoryProvider).logout(),
                        icon: const Icon(Icons.logout_rounded, color: AppColors.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: destinations.map((d) => NavigationRailDestination(icon: Icon(d.$1), label: Text(d.$2))).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: screens.isEmpty ? const SizedBox.shrink() : screens[index]),
        ],
      ),
    );
  }
}

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
