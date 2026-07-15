// lib/core/constants/cloudinary_config.dart
/// بيانات حساب Cloudinary - Cloud Name و Upload Preset بتاعين ورشة إبراهيم.
///
/// Upload Preset: "Workshop" - Unsigned، معناه الرفع بيحصل مباشرة من
/// التطبيق من غير أي مفتاح سري مخزّن في الكود.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'dzbvceezc';
  static const String uploadPreset = 'Workshop';
}
