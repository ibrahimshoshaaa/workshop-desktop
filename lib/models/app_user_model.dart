/// نموذج حساب مستخدم إضافي (عامل) - نفس عقدة app_users بتاعة تطبيق الموبايل
/// بالظبط، مع إضافة حقل permissions الجديد اللي بيتحكم في الشاشات اللي
/// اليوزر ده يقدر يشوفها في نسخة الديسكتوب. الحقل ده اختياري تمامًا وتطبيق
/// الموبايل الحالي بيتجاهله، فمفيش أي مشكلة توافق مع حسابات اتعملت قبل
/// إضافة الميزة دي أو حسابات هتتعمل من الموبايل نفسه.
class AppUserModel {
  final String id;
  final String username;
  final String password;
  final DateTime createdAt;
  final Map<String, bool> permissions;

  /// كل الشاشات اللي ممكن تتحدد صلاحية دخول ليها. الرئيسية مستثناة عمدًا
  /// (متاحة للكل دايمًا)، والإعدادات كمان مستثناة (للأدمن بس، لأنها بتدي
  /// تحكم كامل في كل الحسابات والباسوردات)
  static const List<MapEntry<String, String>> permissionScreens = [
    MapEntry('customers', 'العملاء'),
    MapEntry('orders', 'الطلبات'),
    MapEntry('debts', 'المديونيات'),
    MapEntry('expenses', 'المصروفات'),
    MapEntry('inventory', 'المخزون'),
    MapEntry('reports', 'التقارير'),
  ];

  AppUserModel({
    required this.id,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.permissions,
  });

  /// أي شاشة مش موجودة صراحةً في permissions بتتحسب "مسموحة" افتراضيًا -
  /// عشان الحسابات القديمة (اتعملت قبل ميزة الصلاحيات، أو من الموبايل)
  /// تفضل شغالة بكامل صلاحياتها زي ما كانت من غير ما حد يتفاجئ إنه اتقفل فجأة
  bool canAccess(String screenKey) => permissions[screenKey] ?? true;

  factory AppUserModel.fromMap(String id, Map<dynamic, dynamic> map) {
    final permsRaw = map['permissions'];
    final perms = <String, bool>{};
    if (permsRaw is Map) {
      permsRaw.forEach((k, v) => perms[k.toString()] = v == true);
    }
    return AppUserModel(
      id: id,
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      permissions: perms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'permissions': permissions,
    };
  }
}
