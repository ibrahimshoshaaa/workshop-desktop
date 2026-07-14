import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/data_providers.dart';
import '../core/theme.dart';
import '../core/search_bar.dart';

enum _StatusFilter { all, completed, pending, cancelled }

class RevenuesDetailScreen extends ConsumerStatefulWidget {
  const RevenuesDetailScreen({super.key});

  @override
  ConsumerState<RevenuesDetailScreen> createState() => _RevenuesDetailScreenState();
}

class _RevenuesDetailScreenState extends ConsumerState<RevenuesDetailScreen> {
  late DateTimeRange _selectedDateRange;
  late String _sortBy;
  late bool _sortAscending;
  _StatusFilter _statusFilter = _StatusFilter.all;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sortBy = 'date';
    _sortAscending = false;
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  bool _matchesStatusFilter(String status) {
    if (_statusFilter == _StatusFilter.all) return true;
    final s = status.toLowerCase();
    switch (_statusFilter) {
      case _StatusFilter.completed:
        return s == 'completed' || s == 'مكتمل';
      case _StatusFilter.pending:
        return s == 'pending' || s == 'قيد الانتظار';
      case _StatusFilter.cancelled:
        return s == 'cancelled' || s == 'ملغى';
      case _StatusFilter.all:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider).value ?? [];
    final formatter = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 0);
    final dateFormatter = DateFormat('d/M/yyyy', 'ar_EG');

    // تصفية الطلبات حسب التاريخ
    var filteredOrders = orders.where((order) {
      final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
      return orderDate.isAfter(_selectedDateRange.start) &&
          orderDate.isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
    }).toList();

    // تصفية حسب الحالة
    filteredOrders = filteredOrders.where((o) => _matchesStatusFilter(o.status)).toList();

    // تصفية حسب نص البحث (اسم العميل أو نوع الصنف)
    final q = normalizeForSearch(_query);
    if (q.isNotEmpty) {
      filteredOrders = filteredOrders.where((order) {
        return normalizeForSearch(order.customerName).contains(q) || normalizeForSearch(order.itemType).contains(q);
      }).toList();
    }

    // فرز الطلبات
    if (_sortBy == 'date') {
      filteredOrders.sort((a, b) {
        int compare = b.createdAt.compareTo(a.createdAt);
        return _sortAscending ? -compare : compare;
      });
    } else if (_sortBy == 'amount') {
      filteredOrders.sort((a, b) {
        int compare = b.totalPaid.compareTo(a.totalPaid);
        return _sortAscending ? -compare : compare;
      });
    }

    final totalRevenue = filteredOrders.fold<double>(0, (sum, order) => sum + order.totalPaid);
    final averageRevenue = filteredOrders.isEmpty ? 0.0 : totalRevenue / filteredOrders.length;
    final completedRevenue = filteredOrders
        .where((o) => _matchesStatusFilterFor(o.status, _StatusFilter.completed))
        .fold<double>(0, (sum, o) => sum + o.totalPaid);
    final pendingRevenue = filteredOrders
        .where((o) => _matchesStatusFilterFor(o.status, _StatusFilter.pending))
        .fold<double>(0, (sum, o) => sum + o.totalPaid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('تفاصيل الإيرادات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final cards = [
                  _StatCard(
                    icon: Icons.payments_rounded,
                    label: 'إجمالي الإيرادات',
                    value: formatter.format(totalRevenue),
                    color: AppColors.success,
                  ),
                  _StatCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'متوسط الإيراد',
                    value: formatter.format(averageRevenue),
                    color: AppColors.navy,
                  ),
                  _StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'إيراد المكتمل',
                    value: formatter.format(completedRevenue),
                    color: Colors.green.shade700,
                  ),
                  _StatCard(
                    icon: Icons.hourglass_top_rounded,
                    label: 'إيراد قيد الانتظار',
                    value: formatter.format(pendingRevenue),
                    color: AppColors.warning,
                  ),
                ];
                if (isNarrow) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.4,
                    physics: const NeverScrollableScrollPhysics(),
                    children: cards,
                  );
                }
                return Row(
                  children: cards
                      .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(left: 12), child: c)))
                      .toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: AppSearchBar(
                        controller: _searchController,
                        hintText: 'ابحث باسم العميل أو نوع الصنف...',
                        onChanged: (v) => setState(() => _query = v),
                        onClear: () => setState(() => _query = ''),
                      ),
                    ),
                    _FilterChipButton(
                      icon: Icons.date_range_rounded,
                      label: '${dateFormatter.format(_selectedDateRange.start)} - ${dateFormatter.format(_selectedDateRange.end)}',
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Directionality(textDirection: TextDirection.ltr, child: child!);
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                        }
                      },
                    ),
                    _buildStatusDropdown(),
                    _buildSortControl(),
                  ],
                ),
              ),
            ),
          ),
          if (filteredOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${filteredOrders.length} عملية',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('لا توجد إيرادات مطابقة', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
                            child: DataTable(
                              sortColumnIndex: _sortBy == 'date' ? 1 : (_sortBy == 'amount' ? 4 : null),
                              sortAscending: _sortAscending,
                              headingRowColor: WidgetStateProperty.all(AppColors.wood.withValues(alpha: 0.06)),
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 64,
                              columns: [
                                const DataColumn(label: Text('العميل / الصنف')),
                                DataColumn(
                                  label: const Text('التاريخ'),
                                  onSort: (_, asc) => setState(() {
                                    _sortBy = 'date';
                                    _sortAscending = asc;
                                  }),
                                ),
                                const DataColumn(label: Text('الحالة')),
                                const DataColumn(label: Text('الإجمالي'), numeric: true),
                                DataColumn(
                                  label: const Text('المدفوع'),
                                  numeric: true,
                                  onSort: (_, asc) => setState(() {
                                    _sortBy = 'amount';
                                    _sortAscending = asc;
                                  }),
                                ),
                                const DataColumn(label: Text('المتبقي'), numeric: true),
                              ],
                              rows: filteredOrders.map((order) {
                                final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
                                final outstanding = order.totalAmount - order.totalPaid;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text(order.itemType, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(dateFormatter.format(orderDate), style: const TextStyle(fontSize: 12))),
                                    DataCell(_StatusBadge(status: order.status, color: _getStatusColor(order.status))),
                                    DataCell(Text(formatter.format(order.totalAmount), style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(
                                      formatter.format(order.totalPaid),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                                    )),
                                    DataCell(Text(
                                      outstanding > 0 ? formatter.format(outstanding) : '—',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: outstanding > 0 ? FontWeight.w600 : FontWeight.normal,
                                        color: outstanding > 0 ? AppColors.danger : Colors.grey.shade400,
                                      ),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool _matchesStatusFilterFor(String status, _StatusFilter filter) {
    final s = status.toLowerCase();
    switch (filter) {
      case _StatusFilter.completed:
        return s == 'completed' || s == 'مكتمل';
      case _StatusFilter.pending:
        return s == 'pending' || s == 'قيد الانتظار';
      case _StatusFilter.cancelled:
        return s == 'cancelled' || s == 'ملغى';
      case _StatusFilter.all:
        return true;
    }
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_StatusFilter>(
          value: _statusFilter,
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: _StatusFilter.all, child: Text('كل الحالات')),
            DropdownMenuItem(value: _StatusFilter.completed, child: Text('مكتمل')),
            DropdownMenuItem(value: _StatusFilter.pending, child: Text('قيد الانتظار')),
            DropdownMenuItem(value: _StatusFilter.cancelled, child: Text('ملغى')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _statusFilter = value);
          },
        ),
      ),
    );
  }

  Widget _buildSortControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
              items: const [
                DropdownMenuItem(value: 'date', child: Text('ترتيب بالتاريخ')),
                DropdownMenuItem(value: 'amount', child: Text('ترتيب بالمبلغ')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sortBy = value);
              },
            ),
          ),
          IconButton(
            icon: Icon(_sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18),
            tooltip: _sortAscending ? 'تصاعدي' : 'تنازلي',
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'مكتمل':
        return AppColors.success;
      case 'pending':
      case 'قيد الانتظار':
        return AppColors.warning;
      case 'cancelled':
      case 'ملغى':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterChipButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.wood),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}
