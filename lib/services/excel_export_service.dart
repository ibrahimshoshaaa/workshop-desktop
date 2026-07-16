import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../core/order_calculations.dart';
import '../core/constants.dart';

/// خدمة توليد وحفظ ملف Excel - على سطح المكتب بنسأل المستخدم فين عايز
/// يحفظ الملف (بدل المشاركة المباشرة زي الموبايل)
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  Uint8List buildFinancialWorkbook({
    required List<Order> orders,
    required List<Expense> expenses,
    List<PaymentTransaction> transactions = const [],
  }) {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet()!;

    final ordersSheet = excel['الطلبات'];
    ordersSheet.appendRow([
      TextCellValue('العميل'),
      TextCellValue('الصنف'),
      TextCellValue('الحالة'),
      TextCellValue('الإجمالي'),
      TextCellValue('المدفوع'),
      TextCellValue('المتبقي'),
      TextCellValue('تاريخ التسليم'),
    ]);
    for (final o in orders) {
      ordersSheet.appendRow([
        TextCellValue(o.customerName),
        TextCellValue(o.itemType),
        TextCellValue(o.status),
        DoubleCellValue(o.effectiveTotal),
        DoubleCellValue(o.totalPaid),
        DoubleCellValue(o.remaining),
        TextCellValue(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))),
      ]);
    }

    final expensesSheet = excel['المصروفات'];
    expensesSheet.appendRow([
      TextCellValue('الفئة'),
      TextCellValue('الوصف'),
      TextCellValue('اسم الصنايعي'),
      TextCellValue('مصدر الدفع'),
      TextCellValue('المبلغ'),
      TextCellValue('التاريخ'),
    ]);
    for (final e in expenses) {
      expensesSheet.appendRow([
        TextCellValue(expenseCategories[e.category] ?? e.category),
        TextCellValue(e.description),
        TextCellValue(e.workerName ?? ''),
        TextCellValue(paymentMethods[e.paymentMethod] ?? e.paymentMethod),
        DoubleCellValue(e.amount),
        TextCellValue(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))),
      ]);
    }

    // ورقة ملخص - تفنيط "المبلغ المتاح" حسب مصدره (نقدي/إنستاباي) - بنستبعد
    // أي دفعة مرتبطة بطلب اتحذف (شايف نفس الشرح في dashboardStatsProvider)
    final liveOrderIds = orders.map((o) => o.id).toSet();
    double revenueByMethod(String method) => transactions
        .where((t) => t.paymentMethod == method && liveOrderIds.contains(t.orderId))
        .fold<double>(0, (s, t) => s + t.amountPaid);
    double expensesByMethod(String method) =>
        expenses.where((e) => e.paymentMethod == method).fold<double>(0, (s, e) => s + e.amount);
    final totalRevenue = orders.fold<double>(0, (s, o) => s + o.totalPaid);
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);

    final summarySheet = excel['ملخص الخزينة'];
    summarySheet.appendRow([TextCellValue('البند'), TextCellValue('القيمة')]);
    summarySheet.appendRow([TextCellValue('إجمالي الإيرادات'), DoubleCellValue(totalRevenue)]);
    summarySheet.appendRow([TextCellValue('إجمالي المصروفات'), DoubleCellValue(totalExpenses)]);
    summarySheet.appendRow([TextCellValue('المبلغ المتاح'), DoubleCellValue(totalRevenue - totalExpenses)]);
    summarySheet.appendRow([TextCellValue('المبلغ المتاح - نقدي'), DoubleCellValue(revenueByMethod('cash') - expensesByMethod('cash'))]);
    summarySheet.appendRow([TextCellValue('المبلغ المتاح - إنستاباي'), DoubleCellValue(revenueByMethod('instapay') - expensesByMethod('instapay'))]);

    excel.delete(defaultSheetName);
    final bytes = excel.save();
    return Uint8List.fromList(bytes!);
  }

  /// يفتح نافذة "حفظ باسم" حقيقية بتاعة ويندوز، ولو المستخدم لغى، بيتجاهل
  Future<bool> saveWorkbook(Uint8List bytes, String suggestedName) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'احفظ التقرير',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (path == null) return false;
    final file = File(path.endsWith('.xlsx') ? path : '$path.xlsx');
    await file.writeAsBytes(bytes);
    return true;
  }
}
