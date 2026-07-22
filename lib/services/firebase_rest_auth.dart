import 'dart:convert';
import 'package:http/http.dart' as http;

/// Firebase Authentication عن طريق REST مباشر - لأن مفيش SDK رسمي لـ
/// Firebase على ويندوز (زي ما موضّح في تعليق user_account_service.dart
/// وsync_service.dart أصلًا). بنكلم Identity Toolkit REST API بتاع Google
/// نفسه، وهو نفس اللي مكتبة firebase_auth بتستخدمه من تحت في أي حال.
///
/// ⚠️ لازم تحط [webApiKey] القيمة الصحيحة - تلاقيها في Firebase Console:
/// Project Settings (⚙️ جنب "Project Overview") → General تاب →
/// "Web API Key". القيمة دي مش سر (زي أي Firebase apiKey تاني، عادي
/// تتحط في الكود - الحماية الحقيقية في قواعد قاعدة البيانات مش في إخفاء
/// المفتاح ده).
class FirebaseRestAuth {
  FirebaseRestAuth._();

  // TODO: استبدل القيمة دي بالـ Web API Key الحقيقي من Firebase Console
  static const String webApiKey = 'AIzaSyA2u7EIySiILna5ycloOpHav3BP93lrOSA';

  static const _timeout = Duration(seconds: 15);

  static String? _idToken;
  static String? _refreshToken;
  static String? _uid;
  static DateTime? _expiresAt;

  static String? get currentUid => _uid;

  /// بيتنادى مع كل طلب REST لقاعدة البيانات - بيضيف التوكن الحالي كـ query
  /// param (auth=...) عشان يعدّي قاعدة ".read/.write": "auth != null".
  /// لو التوكن قرب ينتهي (أو خلص) بيجدده تلقائيًا الأول لو فيه refresh token
  static Future<Uri> withAuth(Uri uri) async {
    await _ensureFreshToken();
    final token = _idToken;
    if (token == null) return uri;
    final params = Map<String, String>.from(uri.queryParameters)..['auth'] = token;
    return uri.replace(queryParameters: params);
  }

  static Future<void> _ensureFreshToken() async {
    if (_idToken != null && _expiresAt != null && DateTime.now().isBefore(_expiresAt!.subtract(const Duration(minutes: 2)))) {
      return; // لسه صالح لدقيقتين على الأقل، مفيش داعي نجدده
    }
    if (_refreshToken == null) return; // مفيش جلسة أصلًا
    try {
      final response = await http
          .post(
            Uri.parse('https://securetoken.googleapis.com/v1/token?key=$webApiKey'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'grant_type': 'refresh_token', 'refresh_token': _refreshToken!},
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // ملحوظة: استجابة endpoint التجديد ده بالذات بتستخدم snake_case
        // (id_token) مش camelCase زي باقي endpoints بتاعة Identity Toolkit
        _idToken = data['id_token'] as String?;
        _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
        final expiresIn = int.tryParse(data['expires_in']?.toString() ?? '3600') ?? 3600;
        _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      }
    } catch (_) {
      // مفيش نت - نسيب التوكن القديم زي ما هو (ممكن يفضل شغال لو لسه
      // ماخلصش فعليًا، أو الطلبات هتفشل وبتتعامل معاها الأماكن التانية)
    }
  }

  /// تسجيل دخول - بيرجع رسالة خطأ لو فشل، أو null لو نجح
  static Future<String?> signIn(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$webApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
          )
          .timeout(_timeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final message = (data['error']?['message'] ?? '').toString();
        if (message.contains('EMAIL_NOT_FOUND') || message.contains('INVALID_PASSWORD') || message.contains('INVALID_LOGIN_CREDENTIALS')) {
          return 'اليوزر أو الباسورد غلط';
        }
        return 'حصل خطأ في تسجيل الدخول: $message';
      }

      _idToken = data['idToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _uid = data['localId'] as String?;
      final expiresIn = int.tryParse(data['expiresIn']?.toString() ?? '3600') ?? 3600;
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      return null;
    } catch (_) {
      return 'مفيش اتصال بالإنترنت للتحقق من الحساب';
    }
  }

  /// إنشاء حساب Firebase Auth جديد لعامل - REST بطبيعته "بدون جلسة"،
  /// يعني النداء ده مبيأثرش خالص على جلسة الأدمن الحالية المحفوظة فوق
  /// (عكس مكتبة الـ SDK في الموبايل اللي كانت محتاجة حيلة Secondary App
  /// عشان تتجنب نفس المشكلة دي - هنا مش محتاجينها أصلًا)
  static Future<String?> createAccount(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$webApiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (data['error']?['message'] ?? '').toString();
      if (message.contains('EMAIL_EXISTS')) return 'في يوزر بنفس الاسم موجود بالفعل';
      return 'حصل خطأ في إنشاء الحساب: $message';
    } catch (_) {
      return 'مفيش اتصال بالإنترنت';
    }
  }

  /// بيستعيد جلسة سابقة من refresh token متخزّن محليًا (لو موجود) - عشان
  /// المستخدم يفضل داخل حتى لو قفل التطبيق وفتحه تاني، بنفس سلوك الموبايل
  static Future<bool> restoreSession(String refreshToken) async {
    _refreshToken = refreshToken;
    await _ensureFreshToken();
    return _idToken != null;
  }

  static String? get refreshTokenForPersistence => _refreshToken;

  static void clear() {
    _idToken = null;
    _refreshToken = null;
    _uid = null;
    _expiresAt = null;
  }
}
