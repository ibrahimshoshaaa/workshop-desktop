import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/constants.dart';
import '../core/order_calculations.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../providers/data_providers.dart';
import '../providers/navigation_provider.dart';
import '../providers/sync_provider.dart';
import 'customers_screen.dart' show CustomerOrdersDialog;
import 'orders_screen.dart';
import 'revenues_detail_screen.dart';

const List<String> _arabicMonthsShort = [
  'ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس',
];

/// ألوان توزيع فئات المصروفات - مبنية على هوية التطبيق (AppColors) مع لون
/// محايد إضافي بس لفئة "أخرى"
const Map<String, Color> _categoryColors = {
  'materials': AppColors.wood,
  'rent': AppColors.navy,
  'wages': AppColors.amber,
  'workshop_debt': AppColors.danger,
  'other': Color(0xFF8E7CC3),
};

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _monthsRange = 6;
  bool _isSyncing = false;

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await ref.read(syncServiceProvider).syncAll();
    if (mounted) setState(() => _isSyncing = false);
  }

  List<_MonthlyPoint> _buildMonthlySeries(
    List<Order> orders,
    List<PaymentTransaction> transactions,
    List<Expense> expenses,
  ) {
    final liveOrderIds = orders.map((o) => o.id).toSet();
    final now = DateTime.now();
    final months = List.generate(_monthsRange, (i) => DateTime(now.year, now.month - (_monthsRange - 1 - i), 1));

    return months.map((m) {
      final monthEnd = DateTime(m.year, m.month + 1, 1);
      final revenue = transactions.where((t) {
        if (!liveOrderIds.contains(t.orderId)) return false;
        final d = DateTime.fromMillisecondsSinceEpoch(t.paymentDate);
        return !d.isBefore(m) && d.isBefore(monthEnd);
      }).fold<double>(0, (s, t) => s + t.amountPaid);
      final expense = expenses.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.date);
        return !d.isBefore(m) && d.isBefore(monthEnd);
      }).fold<double>(0, (s, e) => s + e.amount);
      return _MonthlyPoint(month: m, revenue: revenue, expense: expense);
    }).toList();
  }

  List<_DonutSlice> _buildExpenseSlices(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final slices = totals.entries.map((entry) {
      return _DonutSlice(
        label: expenseCategories[entry.key] ?? entry.key,
        value: entry.value,
        color: _categoryColors[entry.key] ?? Colors.grey.shade400,
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return slices;
  }

  List<_ActivityItem> _buildActivity(
    List<Order> orders,
    List<PaymentTransaction> transactions,
    List<Expense> expenses,
    List<Customer> customers,
  ) {
    final items = <_ActivityItem>[];

    for (final o in orders) {
      items.add(_ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(o.createdAt),
        title: 'تم تسجيل طلب جديد',
        subtitle: '${o.customerName} - ${o.itemType}',
        icon: Icons.checkroom_rounded,
        color: AppColors.navy,
      ));
    }
    for (final t in transactions) {
      items.add(_ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(t.paymentDate),
        title: 'تم تسجيل إيراد جديد',
        subtitle: '+${t.amountPaid.toStringAsFixed(0)} ج.م',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ));
    }
    for (final e in expenses) {
      items.add(_ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(e.date),
        title: 'تم تسجيل مصروف',
        subtitle: '-${e.amount.toStringAsFixed(0)} ج.م • ${expenseCategories[e.category] ?? e.category}',
        icon: Icons.receipt_long_rounded,
        color: AppColors.danger,
      ));
    }
    for (final c in customers) {
      items.add(_ActivityItem(
        time: DateTime.fromMillisecondsSinceEpoch(c.createdAt),
        title: 'تم إضافة عميل جديد',
        subtitle: c.name,
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.amber,
      ));
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items.take(8).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'تم التسليم':
        return AppColors.success;
      case 'جاهز للتسليم':
        return AppColors.navy;
      case 'قيد التنفيذ':
        return AppColors.amber;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final dueWorkers = ref.watch(workersDueTodayProvider);
    final upcomingDeliveries = ref.watch(upcomingDeliveriesProvider);
    final debtorOrders = ref.watch(debtorOrdersProvider);
    final outstandingWorkshopDebts = ref.watch(outstandingWorkshopDebtsProvider);
    final orders = ref.watch(ordersProvider).value ?? [];
    final customers = ref.watch(customersProvider).value ?? [];
    final expenses = ref.watch(expensesProvider).value ?? [];
    final transactions = ref.watch(allTransactionsProvider).value ?? [];
    final formatter = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 0);

    final monthlySeries = _buildMonthlySeries(orders, transactions, expenses);
    final expenseSlices = _buildExpenseSlices(expenses);
    final activity = _buildActivity(orders, transactions, expenses, customers);

    final recentOrders = [...orders]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentCustomers = [...customers]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      color: const Color(0xFFFAF6F0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              dueWorkersCount: dueWorkers.length,
              debtorOrdersCount: debtorOrders.length,
              workshopDebtsCount: outstandingWorkshopDebts.length,
              onWorkersTap: () => ref.read(selectedTabProvider.notifier).state = 5,
              onDebtorsTap: () => ref.read(selectedTabProvider.notifier).state = 3,
              onWorkshopDebtsTap: () => ref.read(selectedTabProvider.notifier).state = 4,
            ),
            const SizedBox(height: 28),
            if (dueWorkers.isNotEmpty) ...[
              _DueWorkersBanner(
                names: dueWorkers.map((w) => w.name).join('، '),
                onTap: () => ref.read(selectedTabProvider.notifier).state = 5,
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'إجمالي الإيرادات',
                    value: formatter.format(stats.totalRevenue),
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenuesDetailScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'المديونيات المستحقة',
                    value: formatter.format(stats.totalDebts),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'إجمالي المصروفات',
                    value: formatter.format(stats.totalExpenses),
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.warning,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'المتاح نقدي (كاش)',
                    value: formatter.format(stats.cashAvailable),
                    icon: Icons.payments_rounded,
                    color: stats.cashAvailable >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'المتاح إنستاباي',
                    value: formatter.format(stats.instapayAvailable),
                    icon: Icons.phone_iphone_rounded,
                    color: stats.instapayAvailable >= 0 ? AppColors.navy : AppColors.danger,
                    onTap: () => _showCashTransferDialog(context, ref, stats.instapayAvailable),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    title: 'مديونيات الورشة (علينا)',
                    value: formatter.format(stats.totalWorkshopDebts),
                    icon: Icons.store_rounded,
                    color: AppColors.danger,
                    onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ResponsiveRow(
              breakpoint: 900,
              spacing: 20,
              flexes: const [1, 1],
              children: [
                _SectionCard(
                  title: 'التسليمات القادمة',
                  icon: Icons.local_shipping_rounded,
                  child: upcomingDeliveries.isEmpty
                      ? const _EmptyState(text: 'مفيش تسليمات خلال الأسبوع الجاي')
                      : Column(
                          children: upcomingDeliveries.take(6).map((o) {
                            final delivery = DateTime.fromMillisecondsSinceEpoch(o.deliveryDate);
                            final today = DateTime.now();
                            final daysLeft = DateTime(delivery.year, delivery.month, delivery.day)
                                .difference(DateTime(today.year, today.month, today.day))
                                .inDays;
                            final label = daysLeft == 0 ? 'النهاردة' : (daysLeft == 1 ? 'بكرة' : 'بعد $daysLeft أيام');
                            return _ListRow(
                              leadingIcon: Icons.checkroom_rounded,
                              leadingColor: daysLeft == 0 ? AppColors.danger : AppColors.navy,
                              title: '${o.customerName} - ${o.itemType}',
                              subtitle: '${DateFormat('d/M/yyyy').format(delivery)} • $label',
                              trailingAction: IconButton(
                                tooltip: 'مشاركة على واتساب',
                                icon: const Icon(Icons.share_rounded, color: AppColors.success, size: 18),
                                onPressed: () => showShareToWorkerDialog(context, ref, o),
                              ),
                              onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                            );
                          }).toList(),
                        ),
                ),
                _SectionCard(
                  title: 'أحدث الطلبات',
                  icon: Icons.receipt_rounded,
                  child: recentOrders.isEmpty
                      ? const _EmptyState(text: 'مفيش طلبات مسجّلة بعد')
                      : Column(
                          children: recentOrders.take(6).map((o) {
                            return _ListRow(
                              leadingIcon: Icons.checkroom_rounded,
                              leadingColor: _statusColor(o.status),
                              title: '${o.customerName} - ${o.itemType}',
                              subtitle: o.status,
                              trailingText: '${o.totalPaid.toStringAsFixed(0)} ج.م',
                              onTap: () => showDialog(context: context, builder: (context) => OrderDetailDialog(order: o)),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ResponsiveRow(
              breakpoint: 980,
              spacing: 20,
              flexes: const [3, 2],
              children: [
                _SectionCard(
                  title: 'نظرة عامة على الأداء',
                  icon: Icons.show_chart_rounded,
                  trailing: _MonthsRangeDropdown(
                    value: _monthsRange,
                    onChanged: (v) => setState(() => _monthsRange = v),
                  ),
                  child: _RevenueExpenseChart(points: monthlySeries),
                ),
                _SectionCard(
                  title: 'توزيع المصروفات',
                  icon: Icons.donut_large_rounded,
                  child: _ExpenseDonut(slices: expenseSlices, total: stats.totalExpenses, formatter: formatter),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ResponsiveRow(
              breakpoint: 900,
              spacing: 20,
              flexes: const [1, 1],
              children: [
                _SectionCard(
                  title: 'أحدث العملاء',
                  icon: Icons.people_alt_rounded,
                  child: recentCustomers.isEmpty
                      ? const _EmptyState(text: 'مفيش عملاء مسجّلين بعد')
                      : Column(
                          children: recentCustomers.take(6).map((c) {
                            return _ListRow(
                              leadingText: c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                              leadingColor: AppColors.wood,
                              title: c.name,
                              subtitle: c.phone,
                              onTap: () => showDialog(context: context, builder: (context) => CustomerOrdersDialog(customer: c)),
                            );
                          }).toList(),
                        ),
                ),
                _SectionCard(
                  title: 'سجل الأنشطة',
                  icon: Icons.history_rounded,
                  child: activity.isEmpty
                      ? const _EmptyState(text: 'مفيش أي نشاط لسه')
                      : _ActivityTimeline(items: activity),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _QuickActionsRow(ref: ref),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required int dueWorkersCount,
    required int debtorOrdersCount,
    required int workshopDebtsCount,
    required VoidCallback onWorkersTap,
    required VoidCallback onDebtorsTap,
    required VoidCallback onWorkshopDebtsTap,
  }) {
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar_EG').format(DateTime.now());
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 720;
      final title = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('مرحباً بك 👋', style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
          const SizedBox(height: 6),
          Text('نظرة سريعة وشاملة على أداء طاحون رويال هوم',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600)),
        ],
      );
      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dateStr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.wood)),
          const SizedBox(width: 14),
          _NotificationBell(
            dueWorkersCount: dueWorkersCount,
            debtorOrdersCount: debtorOrdersCount,
            workshopDebtsCount: workshopDebtsCount,
            onWorkersTap: onWorkersTap,
            onDebtorsTap: onDebtorsTap,
            onWorkshopDebtsTap: onWorkshopDebtsTap,
          ),
          const SizedBox(width: 10),
          _HoverCard(
            borderRadius: BorderRadius.circular(14),
            onTap: _isSyncing ? null : _syncNow,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSyncing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.wood),
                        )
                      : const Icon(Icons.sync_rounded, size: 18, color: AppColors.wood),
                  const SizedBox(width: 8),
                  Text(_isSyncing ? 'جاري المزامنة...' : 'مزامنة الآن',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.wood)),
                ],
              ),
            ),
          ),
        ],
      );

      if (narrow) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 16), actions]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: title), actions]);
    });
  }
}

class _MonthlyPoint {
  final DateTime month;
  final double revenue;
  final double expense;
  const _MonthlyPoint({required this.month, required this.revenue, required this.expense});
}

class _DonutSlice {
  final String label;
  final double value;
  final Color color;
  const _DonutSlice({required this.label, required this.value, required this.color});
}

class _ActivityItem {
  final DateTime time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ActivityItem({required this.time, required this.title, required this.subtitle, required this.icon, required this.color});
}

// ==================== الويدجت المشتركة ====================

/// كارت بأثر hover ناعم (رفعة خفيفة + ظل أكبر) - بيتلف حوله أي كارت في
/// الداشبورد عشان يبقى فيه إحساس تفاعلي واحد متسق في كل مكان
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  const _HoverCard({required this.child, this.onTap, this.borderRadius = const BorderRadius.all(Radius.circular(20))});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.wood.withValues(alpha: _hovering ? 0.14 : 0.06),
              blurRadius: _hovering ? 26 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: widget.onTap, borderRadius: widget.borderRadius, child: widget.child),
        ),
      ),
    );
  }
}

/// صف يتحول تلقائيًا لعمود لو المساحة المتاحة ضيقة (تصميم متجاوب) -
/// [flexes] بتحدد نسبة عرض كل عنصر لما تكون العناصر جنب بعض
class _ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final List<int> flexes;
  final double breakpoint;
  final double spacing;
  const _ResponsiveRow({required this.children, required this.flexes, required this.breakpoint, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint) {
        final items = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) items.add(SizedBox(height: spacing));
          items.add(children[i]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items);
      }
      final items = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        if (i > 0) items.add(SizedBox(width: spacing));
        items.add(Expanded(flex: flexes[i], child: children[i]));
      }
      return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: items));
    });
  }
}

/// إطار موحّد لكل قسم في الداشبورد (عنوان + أيقونة + محتوى) - عشان كل
/// الأقسام يبقى شكلها متناسق
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _SectionCard({required this.title, required this.icon, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: AppColors.wood, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade400)),
      ),
    );
  }
}

/// صف قائمة موحّد (بيتستخدم في التسليمات، الطلبات، العملاء) - أيقونة أو
/// حرف افتتاحي + عنوان وتفاصيل + نص جانبي اختياري
class _ListRow extends StatelessWidget {
  final IconData? leadingIcon;
  final String? leadingText;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final String? trailingText;
  final Widget? trailingAction;
  final VoidCallback? onTap;
  const _ListRow({
    this.leadingIcon,
    this.leadingText,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.trailingAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: leadingColor.withValues(alpha: 0.12),
                child: leadingIcon != null
                    ? Icon(leadingIcon, color: leadingColor, size: 18)
                    : Text(leadingText ?? '', style: TextStyle(color: leadingColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF2A2320))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(trailingText!, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
              ],
              if (trailingAction != null) trailingAction!,
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_left_rounded, color: Colors.grey.shade300, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// كارت KPI رئيسي - نفس بيانات ومنطق _StatCard الأصلي (title/value/icon/
/// color/onTap) بس بشكل بريميوم مع أثر hover
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(fontSize: 16.5, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
          ],
        ),
      ),
    );
  }
}

class _DueWorkersBanner extends StatelessWidget {
  final String names;
  final VoidCallback onTap;
  const _DueWorkersBanner({required this.names, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_active_rounded, color: AppColors.warning),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('النهاردة يوم القبض الأسبوعي',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF2A2320))),
                  const SizedBox(height: 3),
                  Text('مستني تأكيد الدفع: $names',
                      style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey.shade700)),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _MonthsRangeDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _MonthsRangeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2A2320)),
          items: const [
            DropdownMenuItem(value: 3, child: Text('آخر 3 أشهر')),
            DropdownMenuItem(value: 6, child: Text('آخر 6 أشهر')),
            DropdownMenuItem(value: 12, child: Text('آخر 12 شهر')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// شارت الإيرادات مقابل المصروفات - مرسوم يدوي (CustomPainter) من غير أي
/// مكتبة تشارتس خارجية، عشان معندناش أي مكتبة تشارتس في المشروع أصلاً
class _RevenueExpenseChart extends StatelessWidget {
  final List<_MonthlyPoint> points;
  const _RevenueExpenseChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: AppColors.success, label: 'الإيرادات'),
            const SizedBox(width: 16),
            _LegendDot(color: AppColors.wood, label: 'المصروفات'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: CustomPaint(
            painter: _RevenueExpenseChartPainter(points),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _RevenueExpenseChartPainter extends CustomPainter {
  final List<_MonthlyPoint> points;
  _RevenueExpenseChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    final maxValue = points.fold<double>(0, (m, p) => math.max(m, math.max(p.revenue, p.expense)));
    final safeMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    const double leftPadding = 6;
    const double bottomPadding = 26;
    const double topPadding = 6;
    final double chartWidth = size.width - leftPadding * 2;
    final double chartHeight = size.height - bottomPadding - topPadding;
    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight - (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - leftPadding, y), gridPaint);
    }

    final double dx = points.length > 1 ? chartWidth / (points.length - 1) : 0;

    Offset pointOffset(int i, double value) {
      final x = leftPadding + dx * i;
      final y = topPadding + chartHeight - (value / safeMax) * chartHeight;
      return Offset(x, y);
    }

    void drawSeries(List<double> values, Color color, {bool fill = false}) {
      final path = Path();
      final fillPath = Path();
      for (int i = 0; i < values.length; i++) {
        final o = pointOffset(i, values[i]);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
          fillPath.moveTo(o.dx, topPadding + chartHeight);
          fillPath.lineTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
          fillPath.lineTo(o.dx, o.dy);
        }
      }

      if (fill && values.isNotEmpty) {
        final lastX = pointOffset(values.length - 1, values.last).dx;
        fillPath.lineTo(lastX, topPadding + chartHeight);
        fillPath.close();
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
        canvas.drawPath(fillPath, fillPaint);
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, linePaint);

      for (int i = 0; i < values.length; i++) {
        final o = pointOffset(i, values[i]);
        canvas.drawCircle(o, 4.2, Paint()..color = Colors.white);
        canvas.drawCircle(o, 4.2, Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4);
      }
    }

    drawSeries(points.map((p) => p.expense).toList(), AppColors.wood);
    drawSeries(points.map((p) => p.revenue).toList(), AppColors.success, fill: true);

    for (int i = 0; i < points.length; i++) {
      final o = pointOffset(i, 0);
      final label = _arabicMonthsShort[points[i].month.month - 1];
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(o.dx - tp.width / 2, size.height - bottomPadding + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueExpenseChartPainter oldDelegate) => oldDelegate.points != points;
}

/// دونات توزيع المصروفات - مرسومة يدويًا برضه بنفس منطق الشارت فوق
class _ExpenseDonut extends StatelessWidget {
  final List<_DonutSlice> slices;
  final double total;
  final NumberFormat formatter;
  const _ExpenseDonut({required this.slices, required this.total, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(painter: _DonutChartPainter(slices, total), size: Size.infinite),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatter.format(total), style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('إجمالي', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (slices.isEmpty)
          const _EmptyState(text: 'مفيش مصروفات مسجّلة بعد')
        else
          ...slices.map((s) {
            final pct = total > 0 ? (s.value / total * 100) : 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.label, style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey.shade700)),
                  ),
                  Text('${pct.toStringAsFixed(0)}%', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final double total;
  _DonutChartPainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const double strokeWidth = 20;

    if (total <= 0 || slices.isEmpty) {
      final bgPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), 0, 2 * math.pi, false, bgPaint);
      return;
    }

    var startAngle = -math.pi / 2;
    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => oldDelegate.slices != slices || oldDelegate.total != total;
}

/// جرس التنبيهات - أيقونة فوق جنب التاريخ بدل ما كانت بوكس لوحدها تحت.
/// الرقم على الجرس بيعدّ فئات التنبيهات النشطة (قبض عمال / مديونيات
/// عملاء / مديونيات ورشة) - مش عدد كل عنصر لوحده، عشان الرقم يفضل صغير
/// ومفهوم بدل ما يبقى رقم كبير مربك
class _NotificationBell extends StatelessWidget {
  final int dueWorkersCount;
  final int debtorOrdersCount;
  final int workshopDebtsCount;
  final VoidCallback onWorkersTap;
  final VoidCallback onDebtorsTap;
  final VoidCallback onWorkshopDebtsTap;
  const _NotificationBell({
    required this.dueWorkersCount,
    required this.debtorOrdersCount,
    required this.workshopDebtsCount,
    required this.onWorkersTap,
    required this.onDebtorsTap,
    required this.onWorkshopDebtsTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeCategories =
        (dueWorkersCount > 0 ? 1 : 0) + (debtorOrdersCount > 0 ? 1 : 0) + (workshopDebtsCount > 0 ? 1 : 0);

    return _HoverCard(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('التنبيهات', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: 380,
            child: _NotificationsList(
              dueWorkersCount: dueWorkersCount,
              debtorOrdersCount: debtorOrdersCount,
              workshopDebtsCount: workshopDebtsCount,
              onWorkersTap: () {
                Navigator.pop(context);
                onWorkersTap();
              },
              onDebtorsTap: () {
                Navigator.pop(context);
                onDebtorsTap();
              },
              onWorkshopDebtsTap: () {
                Navigator.pop(context);
                onWorkshopDebtsTap();
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_rounded, size: 20, color: AppColors.wood),
            if (activeCategories > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: Text(
                    '$activeCategories',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  final int dueWorkersCount;
  final int debtorOrdersCount;
  final int workshopDebtsCount;
  final VoidCallback onWorkersTap;
  final VoidCallback onDebtorsTap;
  final VoidCallback onWorkshopDebtsTap;
  const _NotificationsList({
    required this.dueWorkersCount,
    required this.debtorOrdersCount,
    required this.workshopDebtsCount,
    required this.onWorkersTap,
    required this.onDebtorsTap,
    required this.onWorkshopDebtsTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (dueWorkersCount > 0) {
      rows.add(_ListRow(
        leadingIcon: Icons.engineering_rounded,
        leadingColor: AppColors.warning,
        title: 'موعد قبض عمال أسبوعي',
        subtitle: '$dueWorkersCount عامل مستني تأكيد الدفع',
        onTap: onWorkersTap,
      ));
    }
    if (debtorOrdersCount > 0) {
      rows.add(_ListRow(
        leadingIcon: Icons.account_balance_wallet_rounded,
        leadingColor: AppColors.danger,
        title: 'مديونيات عملاء مستحقة',
        subtitle: '$debtorOrdersCount طلب لسه عليه فلوس',
        onTap: onDebtorsTap,
      ));
    }
    if (workshopDebtsCount > 0) {
      rows.add(_ListRow(
        leadingIcon: Icons.store_rounded,
        leadingColor: AppColors.danger,
        title: 'مديونيات ورشة مستحقة',
        subtitle: '$workshopDebtsCount مديونية للموردين/الصنايعية',
        onTap: onWorkshopDebtsTap,
      ));
    }

    if (rows.isEmpty) {
      return const _EmptyState(text: 'كله تمام، مفيش تنبيهات دلوقتي ✅');
    }
    return Column(children: rows);
  }
}

class _ActivityTimeline extends StatelessWidget {
  final List<_ActivityItem> items;
  const _ActivityTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        final item = entry.value;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: item.color.withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: Icon(item.icon, size: 13, color: item.color),
                  ),
                  if (!isLast) Expanded(child: Container(width: 1.4, color: Colors.grey.shade200)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2A2320))),
                      const SizedBox(height: 2),
                      Text(item.subtitle, style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade500)),
                      const SizedBox(height: 3),
                      Text(DateFormat('d/M - hh:mm a', 'ar_EG').format(item.time),
                          style: GoogleFonts.cairo(fontSize: 10.5, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// اختصارات سريعة للتنقل بين الشاشات الأساسية - بتستخدم selectedTabProvider
/// الموجود بالفعل (نفس آلية التنقل المستخدمة في كل التطبيق)
class _QuickActionsRow extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActionsRow({required this.ref});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.people_alt_rounded, 'العملاء', 1),
      (Icons.checkroom_rounded, 'الطلبات', 2),
      (Icons.account_balance_wallet_rounded, 'المديونيات', 3),
      (Icons.store_rounded, 'مديونيات الورشة', 4),
      (Icons.engineering_rounded, 'العمال', 5),
      (Icons.receipt_long_rounded, 'المصروفات', 6),
      (Icons.summarize_rounded, 'التقارير', 7),
    ];

    return _HoverCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختصارات سريعة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions.map((a) {
                return _QuickActionChip(
                  icon: a.$1,
                  label: a.$2,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = a.$3,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.wood),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2A2320))),
          ],
        ),
      ),
    );
  }
}

/// سحب رصيد إنستاباي عن طريق الصراف الآلي وتحويله لكاش - بينقل المبلغ
/// من "المتاح إنستاباي" لـ "المتاح نقدي" في الداشبورد. تحت الفورم فيه
/// سجل بآخر العمليات يقدر يحذف منه أي عملية غلط. نفس تصميم تطبيق
/// الموبايل بالظبط
void _showCashTransferDialog(BuildContext context, WidgetRef ref, double availableInstapay) {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  bool isSaving = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سحب إنستاباي كاش', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتاح حاليًا في إنستاباي: ${availableInstapay.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'المبلغ اللي اتسحب (ج.م)'),
                        validator: (v) {
                          final amount = double.tryParse(v ?? '');
                          if (amount == null || amount <= 0) return 'أدخل مبلغ صحيح';
                          if (amount > availableInstapay) {
                            return 'المبلغ أكبر من المتاح في إنستاباي (${availableInstapay.toStringAsFixed(0)} ج.م)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                Text('آخر العمليات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final transfers = ref.watch(cashTransfersProvider).value ?? [];
                    if (transfers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد عمليات سحب مسجّلة بعد', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                      );
                    }
                    final sorted = [...transfers]..sort((a, b) => b.date.compareTo(a.date));
                    return Column(
                      children: sorted.take(5).map((t) {
                        final date = DateTime.fromMillisecondsSinceEpoch(t.date);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('${t.amount.toStringAsFixed(0)} ج.م'),
                          subtitle: Text(
                            [
                              '${date.day}/${date.month}/${date.year}',
                              if (t.note.isNotEmpty) t.note,
                            ].join(' - '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                            onPressed: () => ref.read(repositoryProvider).deleteCashTransfer(t.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      await ref.read(repositoryProvider).addCashTransfer(
                            amount: double.parse(amountController.text.trim()),
                            note: noteController.text.trim(),
                          );
                      amountController.clear();
                      noteController.clear();
                      setDialogState(() => isSaving = false);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                      }
                      setDialogState(() => isSaving = false);
                    }
                  },
            child: isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('تسجيل السحب'),
          ),
        ],
      ),
    ),
  );
}
