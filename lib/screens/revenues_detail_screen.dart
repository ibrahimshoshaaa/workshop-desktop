import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../core/theme.dart';

class RevenuesDetailScreen extends ConsumerStatefulWidget {
  const RevenuesDetailScreen({super.key});

  @override
  ConsumerState<RevenuesDetailScreen> createState() => _RevenuesDetailScreenState();
}

class _RevenuesDetailScreenState extends ConsumerState<RevenuesDetailScreen> {
  late DateTimeRange _selectedDateRange;
  String _sortBy = 'date'; // 'date' or 'amount'
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider).value ?? [];
    final formatter = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 0);
    final dateFormatter = DateFormat('yyyy-MM-dd', 'ar_EG');

    // تصفية الطلبات حسب التاريخ
    final filteredOrders = orders.where((order) {
      final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
      return orderDate.isAfter(_selectedDateRange.start) && orderDate.isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
    }).toList();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الإيرادات'),
        backgroundColor: AppColors.wood,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // بطاقة الإجماليات والمرشحات
          Container(
            color: AppColors.wood.withValues(alpha: 0.05),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الفترة الزمنية:', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: _selectedDateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      useMaterial3: true,
                                    ),
                                    child: Directionality(textDirection: TextDirection.rtl, child: child!),
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _selectedDateRange = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.wood),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${dateFormatter.format(_selectedDateRange.start)} إلى ${dateFormatter.format(_selectedDateRange.end)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ترتيب:', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        const SizedBox(height: 6),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: Container(),
                          items: [
                            DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                            DropdownMenuItem(value: 'amount', child: Text('المبلغ')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _sortBy = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // بطاقة الإجمالي
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إجمالي الإيرادات في الفترة', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(totalRevenue),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('عدد الطلبات', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            '${filteredOrders.length}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // قائمة الطلبات
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('لا توجد إيرادات في هذه الفترة', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final orderDate = DateTime.fromMillisecondsSinceEpoch(order.createdAt);
                      final outstanding = order.totalAmount - order.totalPaid;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // رأس البطاقة: اسم العميل والتاريخ
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.customerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${order.itemType} • ${dateFormatter.format(orderDate)}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(order.status),
                                    backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // التفاصيل المالية
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('المبلغ الإجمالي:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          Text(formatter.format(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('المدفوع:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          Text(
                                            formatter.format(order.totalPaid),
                                            style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (outstanding > 0) ...[
                                      const Divider(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('المتبقي:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                            Text(
                                              formatter.format(outstanding),
                                              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.danger),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
