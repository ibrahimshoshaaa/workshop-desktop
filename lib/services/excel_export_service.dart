import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/database.dart';

/// خدمة توليد وحفظ ملف Excel - على سطح المكتب بنسأل المستخدم فين عايز
/// يحفظ الملف (بدل المشاركة المباشرة زي الموبايل)
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  Uint8List buildFinancialWorkbook({
    required List<Order> orders,
    required List<Expense> expenses,
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
        DoubleCellValue(o.totalAmount),
        DoubleCellValue(o.totalPaid),
        DoubleCellValue(o.totalAmount - o.totalPaid),
        TextCellValue(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(o.deliveryDate))),
      ]);
    }

    final expensesSheet = excel['المصروفات'];
    expensesSheet.appendRow([
      TextCellValue('الفئة'),
      TextCellValue('الوصف'),
      TextCellValue('اسم الصنايعي'),
      TextCellValue('المبلغ'),
      TextCellValue('التاريخ'),
    ]);
    for (final e in expenses) {
      expensesSheet.appendRow([
        TextCellValue(e.category),
        TextCellValue(e.description),
        TextCellValue(e.workerName ?? ''),
        DoubleCellValue(e.amount),
        TextCellValue(DateFormat('d/M/yyyy').format(DateTime.fromMillisecondsSinceEpoch(e.date))),
      ]);
    }

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
