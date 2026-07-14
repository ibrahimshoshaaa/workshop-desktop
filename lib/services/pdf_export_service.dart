import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';

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

  Future<Uint8List> buildCustomerInvoice({
    required Customer customer,
    required List<Order> orders,
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();
    final totalAmount = orders.fold<double>(0, (s, o) => s + o.totalAmount);
    final totalPaid = orders.fold<double>(0, (s, o) => s + o.totalPaid);
    final totalRemaining = totalAmount - totalPaid;

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: _arabicFont, bold: _arabicFontBold),
        build: (context) => [
          pw.Text('فاتورة عميل', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('طاحون رويال هوم', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
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
            headers: ['الصنف', 'الحالة', 'الإجمالي', 'المدفوع', 'المتبقي'],
            data: orders
                .map((o) => [
                      o.itemType,
                      o.status,
                      _currency.format(o.totalAmount),
                      _currency.format(o.totalPaid),
                      _currency.format(o.totalAmount - o.totalPaid),
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
                pw.Text('إجمالي الاتفاق: ${_currency.format(totalAmount)}'),
                pw.SizedBox(height: 4),
                pw.Text('إجمالي المدفوع: ${_currency.format(totalPaid)}'),
                pw.SizedBox(height: 4),
                pw.Text('إجمالي المتبقي: ${_currency.format(totalRemaining)}',
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
    required DateTime from,
    required DateTime to,
  }) async {
    await _ensureFontsLoaded();
    final doc = pw.Document();

    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPaid);
    final totalDebts = orders.fold<double>(0, (s, o) => s + (o.totalAmount - o.totalPaid));
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final netProfit = totalRevenue - totalExpenses;

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
              _summaryBox('صافي الربح', netProfit, netProfit >= 0 ? PdfColors.blue700 : PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('الطلبات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            cellAlignment: pw.Alignment.centerRight,
            headers: ['العميل', 'الصنف', 'الحالة', 'الإجمالي', 'المتبقي'],
            data: orders
                .map((o) => [o.customerName, o.itemType, o.status, _currency.format(o.totalAmount), _currency.format(o.totalAmount - o.totalPaid)])
                .toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text('المصروفات', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
            cellAlignment: pw.Alignment.centerRight,
            headers: ['الفئة', 'الوصف', 'التاريخ', 'المبلغ'],
            data: expenses
                .map((e) => [e.category, e.description, DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date)), _currency.format(e.amount)])
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
          pw.Text(_currency.format(value), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  /// يفتح نافذة معاينة/طباعة/حفظ حقيقية بتاعة ويندوز - دي الطريقة الصح
  /// على سطح المكتب (بدل sharePdf اللي مخصصة للموبايل)
  Future<void> previewAndPrint(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(onLayout: (format) async => bytes, name: fileName);
  }
}
