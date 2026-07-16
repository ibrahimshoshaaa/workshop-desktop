import '../data/database.dart';

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
