import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../services/pdf_export_service.dart';
import '../services/excel_export_service.dart';
import '../core/theme.dart';
import '../core/whatsapp.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange _range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
  String? _selectedCustomerId;
  bool _isExporting = false;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _exportWeeklyDeliveries() async {
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final to = from.add(const Duration(days: 7));
      final orders = (ref.read(ordersProvider).value ?? [])
          .where((o) =>
              o.status != 'تم التسليم' &&
              DateTime.fromMillisecondsSinceEpoch(o.deliveryDate).isAfter(from.subtract(const Duration(seconds: 1))) &&
              DateTime.fromMillisecondsSinceEpoch(o.deliveryDate).isBefore(to))
          .toList();
      final bytes = await PdfExportService.instance.buildWeeklyDeliveriesReport(orders: orders, from: from, to: to);
      if (mounted) await PdfExportService.instance.preview(context, bytes, 'تقرير_التسليمات_الأسبوعية.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sendWeeklyDeliveriesOnWhatsApp() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 7));
    final orders = (ref.read(ordersProvider).value ?? [])
        .where((o) =>
            o.status != 'تم التسليم' &&
            DateTime.fromMillisecondsSinceEpoch(o.deliveryDate).isAfter(from.subtract(const Duration(seconds: 1))) &&
            DateTime.fromMillisecondsSinceEpoch(o.deliveryDate).isBefore(to))
        .toList()
      ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    final buffer = StringBuffer()..writeln('تسليمات الأسبوع القادم:');
    if (orders.isEmpty) {
      buffer.writeln('لا توجد تسليمات مقررة');
    } else {
      for (final o in orders) {
        final d = DateTime.fromMillisecondsSinceEpoch(o.deliveryDate);
        buffer.writeln('- ${o.customerName} (${o.itemType}) بتاريخ ${d.day}/${d.month}');
      }
    }
    await shareTextOnWhatsApp(buffer.toString());
  }

  Future<void> _exportFinancialPdf() async {
    setState(() => _isExporting = true);
    try {
      final orders = (ref.read(ordersProvider).value ?? [])
          .where((o) => DateTime.fromMillisecondsSinceEpoch(o.createdAt).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(o.createdAt).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final expenses = (ref.read(expensesProvider).value ?? [])
          .where((e) => DateTime.fromMillisecondsSinceEpoch(e.date).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(e.date).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final bytes = await PdfExportService.instance.buildFinancialReport(orders: orders, expenses: expenses, from: _range.start, to: _range.end);
      if (mounted) await PdfExportService.instance.preview(context, bytes, 'تقرير_مالي.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFinancialExcel() async {
    setState(() => _isExporting = true);
    try {
      final orders = (ref.read(ordersProvider).value ?? [])
          .where((o) => DateTime.fromMillisecondsSinceEpoch(o.createdAt).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(o.createdAt).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final expenses = (ref.read(expensesProvider).value ?? [])
          .where((e) => DateTime.fromMillisecondsSinceEpoch(e.date).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(e.date).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final bytes = ExcelExportService.instance.buildFinancialWorkbook(orders: orders, expenses: expenses);
      final saved = await ExcelExportService.instance.saveWorkbook(bytes, 'تقرير_مالي.xlsx');
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الملف بنجاح')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCustomerInvoice() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر العميل أولاً')));
      return;
    }
    setState(() => _isExporting = true);
    try {
      final customers = ref.read(customersProvider).value ?? [];
      final customer = customers.firstWhere((c) => c.id == _selectedCustomerId);
      final orders = (ref.read(ordersProvider).value ?? []).where((o) => o.customerId == _selectedCustomerId).toList();
      final bytes = await PdfExportService.instance.buildCustomerInvoice(customer: customer, orders: orders);
      if (mounted) await PdfExportService.instance.preview(context, bytes, 'فاتورة_${customer.name}.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والتصدير'), backgroundColor: AppColors.wood, foregroundColor: Colors.white),
      body: AbsorbPointer(
        absorbing: _isExporting,
        child: Opacity(
          opacity: _isExporting ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('تقرير التسليمات (الأسبوع القادم)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('كل الطلبات المقرر تسليمها خلال الأيام السبعة القادمة ولسه ما اتسلمتش',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton.icon(onPressed: _exportWeeklyDeliveries, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('عرض/طباعة'))),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton.icon(onPressed: _sendWeeklyDeliveriesOnWhatsApp, icon: const Icon(Icons.send_rounded), label: const Text('إرسال واتساب'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('التقرير المالي الشامل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('الفترة الزمنية'),
                          subtitle: Text('${_range.start.year}/${_range.start.month}/${_range.start.day} - ${_range.end.year}/${_range.end.month}/${_range.end.day}'),
                          trailing: const Icon(Icons.date_range_rounded),
                          onTap: _pickRange,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton.icon(onPressed: _exportFinancialPdf, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('PDF'))),
                            const SizedBox(width: 12),
                            Expanded(child: OutlinedButton.icon(onPressed: _exportFinancialExcel, icon: const Icon(Icons.table_chart_rounded), label: const Text('Excel'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('فاتورة عميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCustomerId,
                          decoration: const InputDecoration(labelText: 'اختر العميل'),
                          items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (v) => setState(() => _selectedCustomerId = v),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(onPressed: _exportCustomerInvoice, icon: const Icon(Icons.receipt_long_rounded), label: const Text('تصدير فاتورة PDF')),
                      ],
                    ),
                  ),
                ),
                if (_isExporting) const Padding(padding: EdgeInsets.only(top: 24), child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
