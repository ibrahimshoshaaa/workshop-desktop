import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';
import '../core/order_calculations.dart';
import '../core/constants.dart';
import '../core/accounting.dart';

/// خدمة توليد وحفظ ملف Excel - على سطح المكتب بنسأل المستخدم فين عايز
/// يحفظ الملف (بدل المشاركة المباشرة زي الموبايل)
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  Uint8List buildFinancialWorkbook({
    required List<Order> orders,
    required List<Expense> expenses,
    List<PaymentTransaction> transactions = const [],
    List<CashTransfer> transfers = const [],
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
        TextCellValue(
          DateFormat(
            'd/M/yyyy',
          ).format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate)),
        ),
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
        TextCellValue(
          DateFormat(
            'd/M/yyyy',
          ).format(DateTime.fromMillisecondsSinceEpoch(e.date)),
        ),
      ]);
    }

    final totals = AccountingSnapshot(
      orders: orders,
      transactions: transactions,
      expenses: expenses,
      transfers: transfers,
    );
    final totalRevenue = totals.revenue;
    final totalExpenses = totals.expense;
    final paymentsSheet = excel['حركات الدفعات في الفترة'];
    paymentsSheet.appendRow([
      TextCellValue('معرّف الطلب'),
      TextCellValue('المبلغ'),
      TextCellValue('الحالة'),
      TextCellValue('طريقة الدفع'),
      TextCellValue('تاريخ الدفع'),
    ]);
    for (final tx in transactions.where((t) => !t.isDeleted)) {
      paymentsSheet.appendRow([
        TextCellValue(tx.orderId),
        DoubleCellValue(tx.amountPaid),
        TextCellValue(
          tx.status == 'completed' ? 'مكتملة' : 'معلقة — خارج الإيراد',
        ),
        TextCellValue(tx.paymentMethod),
        TextCellValue(
          DateFormat(
            'yyyy/MM/dd HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(tx.paymentDate)),
        ),
      ]);
    }
    final summarySheet = excel['ملخص الخزينة'];
    summarySheet.appendRow([TextCellValue('البند'), TextCellValue('القيمة')]);
    summarySheet.appendRow([
      TextCellValue('إجمالي الإيرادات'),
      DoubleCellValue(totalRevenue),
    ]);
    summarySheet.appendRow([
      TextCellValue('إجمالي المصروفات'),
      DoubleCellValue(totalExpenses),
    ]);
    summarySheet.appendRow([
      TextCellValue('صافي حركة الفترة'),
      DoubleCellValue(totals.net),
    ]);
    summarySheet.appendRow([
      TextCellValue('صافي حركة الفترة - نقدي'),
      DoubleCellValue(totals.cash),
    ]);
    summarySheet.appendRow([
      TextCellValue('صافي حركة الفترة - إنستاباي'),
      DoubleCellValue(totals.instapay),
    ]);

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
