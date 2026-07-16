import 'dart:convert';
import '../data/database.dart';

/// حصة طلب واحد من مصروف مقسّم على أكتر من طلب - لو مصروف اتسجل على
/// 3 طلبات مثلًا، هيبقى ليه 3 كائنات من دول (واحد لكل طلب بنصيبه من المبلغ)
class ExpenseOrderAllocation {
  final String orderId;
  final String customerId;
  final String customerName;
  final double amount;

  const ExpenseOrderAllocation({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
      };

  factory ExpenseOrderAllocation.fromJson(Map<String, dynamic> json) => ExpenseOrderAllocation(
        orderId: json['orderId']?.toString() ?? '',
        customerId: json['customerId']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  static String encodeList(List<ExpenseOrderAllocation> list) =>
      jsonEncode(list.map((a) => a.toJson()).toList());

  static List<ExpenseOrderAllocation> decodeList(String json) {
    if (json.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((e) => ExpenseOrderAllocation.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}

extension ExpenseAllocationsExtension on Expense {
  /// الطلبات المقسّم عليها المصروف ده (فاضية = مصروف عام مش مربوط بطلبات،
  /// أو طلب واحد بس قديم مسجّل بالطريقة القديمة عن طريق orderId مباشرة)
  List<ExpenseOrderAllocation> get allocations {
    final fromJson = ExpenseOrderAllocation.decodeList(orderAllocationsJson);
    if (fromJson.isNotEmpty) return fromJson;
    // توافق مع مصروفات قديمة اتسجلت قبل ميزة التقسيم - كانت بتحفظ طلب
    // واحد بس في orderId/customerId/customerName مباشرة
    if (orderId != null && orderId!.isNotEmpty) {
      return [ExpenseOrderAllocation(orderId: orderId!, customerId: customerId ?? '', customerName: customerName ?? '', amount: amount)];
    }
    return [];
  }
}

/// كل حسابات "الإجمالي بعد الخصم" و"المتبقي" لازم تعدي من هنا، عشان
/// لو حد ضاف طريقة حساب جديدة يوم ما (زي خصم نسبة مثلًا) يغيّرها في
/// مكان واحد بس، وكل الشاشات والتقارير هتتظبط لوحدها
extension OrderCalculations on Order {
  /// الإجمالي الفعلي المستحق على العميل بعد خصم مبلغ الخصم (لو موجود)
  /// من الاتفاق الأصلي - ده اللي بيدخل في حسابات الإيرادات والمديونيات،
  /// مش totalAmount الخام
  double get effectiveTotal => totalAmount - discountAmount;

  /// المتبقي الفعلي على العميل بعد الخصم والدفعات
  double get remaining => effectiveTotal - totalPaid;
}

/// نفس فكرة [OrderCalculations] بس لمديونيات الورشة (الديون اللي علينا
/// لصالح الموردين/الصنايعية - عكس مديونيات العملاء) - المتبقي = الإجمالي
/// ناقص المسدد لحد دلوقتي
extension WorkshopDebtCalculations on WorkshopDebt {
  double get remaining => totalAmount - paidAmount;
}
