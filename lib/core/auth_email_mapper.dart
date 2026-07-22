/// نفس الفكرة والدالة الموجودة في تطبيق الموبايل بالظبط
/// (lib/core/auth_email_mapper.dart هناك) - Firebase Auth بيتطلب صيغة
/// إيميل، مش يوزرنيم بسيط زي "admin"، فبنحوّله لإيميل مصطنع بدومين وهمي.
///
/// لازم يفضل نفس المنطق بالظبط في التطبيقين عشان نفس الحساب (admin) يشتغل
/// في الموبايل والديسكتوب مع بعض من غير أي فرق في التحويل.
String usernameToAuthEmail(String username) {
  final normalized = username.trim().toLowerCase();
  return '$normalized@workshop.local';
}
