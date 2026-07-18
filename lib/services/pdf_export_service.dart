import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../core/order_calculations.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// خدمة توليد ملفات PDF - نفس منطق نسخة الموبايل، بس هنا بنستخدم
/// Printing.layoutPdf بدل sharePdf عشان دي الطريقة الصح لفتح نافذة
/// طباعة/حفظ حقيقية على سطح المكتب (ويندوز)
class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  pw.Font? _arabicFont;
  pw.Font? _arabicFontBold;

  Future<void> _ensureFontsLoaded() async {
    _arabicFont ??= await PdfGoogleFonts.cairoRegular();
    _arabicFontBold ??= await PdfGoogleFonts.cairoBold();
  }

  final _currency = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م', decimalDigits: 0);

  /// عربي Locale بيضيف حروف اتجاه مخفية (bidi/format marks) جوه النص عشان
  /// يظبط ترتيب الأرقام والعملة، بس خط Cairo مالوش شكل ليها فبتظهر كمربع
  /// فاضي "تُفُو". الميثود دي بتشيل أي حرف مخفي من النوع ده وتستبدل الـ
  /// non-breaking space بمسافة عادية، عشان النص يترسم نضيف من غير علامات غريبة.
  static final RegExp _invisibleChars = RegExp(
    r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\u061C\uFEFF]',
  );

  String _clean(String input) => input.replaceAll('\u00A0', ' ').replaceAll(_invisibleChars, '');

  String _fmt(double value) => _clean(_currency.format(value));

  Future<Uint8List> buildCustomerInvoice({
    required Customer customer,
    required List<Order> orders,
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();
    final totalAmount = orders.fold<double>(0, (s, o) => s + o.effectiveTotal);
    final totalPaid = orders.fold<double>(0, (s, o) => s + o.totalPaid);
    final totalRemaining = totalAmount - totalPaid;

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _arabicFont, bold: _arabicFontBold),
        build: (context) => [
          pw.Text('فاتورة عميل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Tahoun Royal Home', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(height: 24),
          pw.Text('اسم العميل: ${customer.name}', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('رقم الهاتف: ${customer.phone}', style: const pw.TextStyle(fontSize: 14)),
          if (customer.address.isNotEmpty) pw.Text('العنوان: ${customer.address}', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('تاريخ الإصدار: ${DateFormat('d/M/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            cellAlignment: pw.Alignment.centerRight,
            tableDirection: pw.TextDirection.rtl,
            headers: ['الصنف', 'الحالة', 'الإجمالي', 'المدفوع', 'المتبقي'],
            data: orders
                .map((o) => [
                      o.itemType,
                      o.status,
                      _fmt(o.effectiveTotal),
                      _fmt(o.totalPaid),
                      _fmt(o.remaining),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('إجمالي الاتفاق: ${_fmt(totalAmount)}'),
                pw.SizedBox(height: 4),
                pw.Text('إجمالي المدفوع: ${_fmt(totalPaid)}'),
                pw.SizedBox(height: 4),
                pw.Text('إجمالي المتبقي: ${_fmt(totalRemaining)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: totalRemaining > 0 ? PdfColors.red700 : PdfColors.green700)),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> buildFinancialReport({
    required List<Order> orders,
    required List<Expense> expenses,
    required List<PaymentTransaction> transactions,
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();

    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPaid);
    final totalDebts = orders.fold<double>(0, (s, o) => s + o.remaining);
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final netProfit = totalRevenue - totalExpenses;

    // تفنيط "المبلغ المتاح" حسب مصدره: كاش/إنستاباي - بنستبعد أي دفعة
    // مرتبطة بطلب اتحذف (شايف نفس الشرح في dashboardStatsProvider)
    final liveOrderIds = orders.map((o) => o.id).toSet();
    double revenueByMethod(String method) => transactions
        .where((t) => t.paymentMethod == method && liveOrderIds.contains(t.orderId))
        .fold<double>(0, (s, t) => s + t.amountPaid);
    double expensesByMethod(String method) =>
        expenses.where((e) => e.paymentMethod == method).fold<double>(0, (s, e) => s + e.amount);
    final cashAvailable = revenueByMethod('cash') - expensesByMethod('cash');
    final instapayAvailable = revenueByMethod('instapay') - expensesByMethod('instapay');

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _arabicFont, bold: _arabicFontBold),
        build: (context) => [
          pw.Text('تقرير مالي شامل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('من ${DateFormat('d/M/yyyy').format(from)} إلى ${DateFormat('d/M/yyyy').format(to)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('الإيرادات', totalRevenue, PdfColors.green700),
              _summaryBox('المديونيات', totalDebts, PdfColors.red700),
              _summaryBox('المصروفات', totalExpenses, PdfColors.orange700),
              _summaryBox('المبلغ المتاح', netProfit, netProfit >= 0 ? PdfColors.blue700 : PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryBox('المبلغ المتاح - نقدي', cashAvailable, cashAvailable >= 0 ? PdfColors.green700 : PdfColors.red700),
              _summaryBox('المبلغ المتاح - إنستاباي', instapayAvailable, instapayAvailable >= 0 ? PdfColors.blue700 : PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('الطلبات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            cellAlignment: pw.Alignment.centerRight,
            tableDirection: pw.TextDirection.rtl,
            headers: ['العميل', 'الصنف', 'الحالة', 'الإجمالي', 'المتبقي'],
            data: orders
                .map((o) => [o.customerName, o.itemType, o.status, _fmt(o.effectiveTotal), _fmt(o.remaining)])
                .toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text('المصروفات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            cellAlignment: pw.Alignment.centerRight,
            tableDirection: pw.TextDirection.rtl,
            headers: ['الفئة', 'الوصف', 'المصدر', 'التاريخ', 'المبلغ'],
            data: expenses
                .map((e) => [
                      expenseCategories[e.category] ?? e.category,
                      e.description,
                      paymentMethods[e.paymentMethod] ?? e.paymentMethod,
                      DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date)),
                      _fmt(e.amount),
                    ])
                .toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }

  /// إيصال استلام فوري - بيتطبع بعد تسجيل أي دفعة (عربون أو قسط) مباشرة
  Future<Uint8List> buildPaymentReceipt({
    required String customerName,
    required String itemType,
    required double amount,
    required String method,
    required DateTime date,
    String status = 'مكتملة',
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _arabicFont, bold: _arabicFontBold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: pw.Text('إيصال استلام', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Tahoun Royal Home', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700))),
            pw.Divider(height: 24),
            pw.SizedBox(height: 8),
            _receiptRow('اسم العميل', customerName),
            _receiptRow('الصنف', itemType),
            _receiptRow('المبلغ المستلم', _fmt(amount)),
            _receiptRow('طريقة الاستلام', method),
            _receiptRow('حالة الدفعة', status),
            _receiptRow('التاريخ', DateFormat('d/M/yyyy - hh:mm a').format(date)),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text('توقيع المستلم: ..............................', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _receiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// تقرير التسليمات المقرر إتمامها خلال فترة معيّنة (الأسبوع القادم
  /// افتراضيًا) - بيتبعت للورشة/المتابعة عن طريق زر "إرسال" في التقارير
  Future<Uint8List> buildWeeklyDeliveriesReport({
    required List<Order> orders,
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();
    final sorted = [...orders]..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _arabicFont, bold: _arabicFontBold),
        build: (context) => [
          pw.Text('تقرير التسليمات القادمة', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text('من ${DateFormat('d/M/yyyy').format(from)} إلى ${DateFormat('d/M/yyyy').format(to)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(height: 24),
          if (sorted.isEmpty)
            pw.Text('لا توجد تسليمات مقررة خلال هذه الفترة', style: const pw.TextStyle(fontSize: 14))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
              cellAlignment: pw.Alignment.centerRight,
              tableDirection: pw.TextDirection.rtl,
              headers: ['تاريخ التسليم', 'العميل', 'الصنف', 'الحالة', 'المتبقي'],
              data: sorted
                  .map((o) => [
                        DateFormat('EEEE d/M', 'ar_EG').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate)),
                        o.customerName,
                        o.itemType,
                        o.status,
                        _fmt(o.remaining),
                      ])
                  .toList(),
            ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _summaryBox(String label, double value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(_fmt(value), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// بيفتح شاشة معاينة جوه التطبيق الأول (تعرض شكل التقرير/الفاتورة كامل)،
  /// وبعدين المستخدم هو اللي يقرر: يطبع/يحفظ، أو يقفل الشاشة من غير ما
  /// يحصل تصدير خالص. ده بديل previewAndPrint اللي كانت بتفتح ديالوج
  /// الطباعة بتاع ويندوز على طول من غير معاينة.
  Future<void> preview(BuildContext context, Uint8List bytes, String fileName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('معاينة قبل التصدير'),
            backgroundColor: AppColors.wood,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) async => bytes,
            pdfFileName: fileName,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  /// نسخة قديمة (بتفتح ديالوج الطباعة/الحفظ بتاع النظام على طول من غير
  /// معاينة داخل التطبيق) - سايبها موجودة لو احتجتها في مكان تاني.
  Future<void> previewAndPrint(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: fileName);
  }
}
