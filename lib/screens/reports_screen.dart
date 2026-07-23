import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../data/database.dart';
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
  String? _selectedOrderId;
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
      final transactions = (ref.read(allTransactionsProvider).value ?? [])
          .where((t) => DateTime.fromMillisecondsSinceEpoch(t.paymentDate).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(t.paymentDate).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final bytes = await PdfExportService.instance.buildFinancialReport(orders: orders, expenses: expenses, transactions: transactions, from: _range.start, to: _range.end);
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
      final transactions = (ref.read(allTransactionsProvider).value ?? [])
          .where((t) => DateTime.fromMillisecondsSinceEpoch(t.paymentDate).isAfter(_range.start) &&
              DateTime.fromMillisecondsSinceEpoch(t.paymentDate).isBefore(_range.end.add(const Duration(days: 1))))
          .toList();
      final bytes = ExcelExportService.instance.buildFinancialWorkbook(orders: orders, expenses: expenses, transactions: transactions);
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
      var orders = (ref.read(ordersProvider).value ?? []).where((o) => o.customerId == _selectedCustomerId).toList();
      if (_selectedOrderId != null) {
        orders = orders.where((o) => o.id == _selectedOrderId).toList();
      }
      final bytes = await PdfExportService.instance.buildCustomerInvoice(customer: customer, orders: orders);
      final fileSuffix = orders.length == 1 ? '${customer.name}_${orders.first.itemType}' : customer.name;
      if (mounted) await PdfExportService.instance.preview(context, bytes, 'فاتورة_$fileSuffix.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).value ?? [];
    final allOrders = ref.watch(ordersProvider).value ?? [];
    final customerOrders = _selectedCustomerId == null
        ? const <Order>[]
        : allOrders.where((o) => o.customerId == _selectedCustomerId).toList();

    return Container(
      color: const Color(0xFFFAF6F0),
      child: AbsorbPointer(
        absorbing: _isExporting,
        child: Opacity(
          opacity: _isExporting ? 0.5 : 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.wood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.summarize_rounded, color: AppColors.wood, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التقارير والتصدير', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF2A2320))),
                        const SizedBox(height: 4),
                        Text('تقارير جاهزة PDF/Excel وإرسال واتساب مباشر',
                            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'تقرير التسليمات (الأسبوع القادم)',
                  icon: Icons.local_shipping_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كل الطلبات المقرر تسليمها خلال الأيام السبعة القادمة ولسه ما اتسلمتش',
                          style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _exportWeeklyDeliveries,
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('عرض/طباعة'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendWeeklyDeliveriesOnWhatsApp,
                              icon: const Icon(Icons.send_rounded),
                              label: const Text('إرسال واتساب'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'التقرير المالي الشامل',
                  icon: Icons.pie_chart_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateRangeRow(range: _range, onTap: _pickRange),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(onPressed: _exportFinancialPdf, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('PDF')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(onPressed: _exportFinancialExcel, icon: const Icon(Icons.table_chart_rounded), label: const Text('Excel')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'فاتورة عميل',
                  icon: Icons.receipt_long_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCustomerId,
                        decoration: _fieldDecoration('اختر العميل', Icons.person_outline_rounded),
                        items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() {
                          _selectedCustomerId = v;
                          _selectedOrderId = null;
                        }),
                      ),
                      if (_selectedCustomerId != null && customerOrders.length > 1) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String?>(
                          value: _selectedOrderId,
                          decoration: _fieldDecoration('نوع الطلب', Icons.checkroom_rounded),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('كل الطلبات')),
                            ...customerOrders.map((o) => DropdownMenuItem<String?>(
                                  value: o.id,
                                  child: Text('${o.itemType} - ${DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))}'),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedOrderId = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(onPressed: _exportCustomerInvoice, icon: const Icon(Icons.receipt_long_rounded), label: const Text('تصدير فاتورة PDF')),
                      ),
                    ],
                  ),
                ),
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.wood)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label, [IconData? icon]) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 20, color: AppColors.wood) : null,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.wood, width: 1.5)),
  );
}

class _DateRangeRow extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onTap;
  const _DateRangeRow({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_rounded, color: AppColors.wood, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الفترة الزمنية', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                  Text(
                    '${range.start.year}/${range.start.month}/${range.start.day} - ${range.end.year}/${range.end.month}/${range.end.day}',
                    style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

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

/// كارت بأثر hover ناعم (رفعة خفيفة + ظل أكبر) - نفس فكرة اللي في
/// dashboard_screen.dart بالظبط، بس متكرر هنا لأن الويدجتس الخاصة
/// (بادئة _) ملهاش مشاركة بين الملفات في دارت
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
