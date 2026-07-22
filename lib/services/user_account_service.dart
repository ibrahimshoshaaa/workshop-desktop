import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user_model.dart';
import 'firebase_rest_auth.dart';
import '../core/auth_email_mapper.dart';

/// خدمة إدارة حسابات العمال (app_users) عن طريق REST API مباشرة - بنفس
/// طريقة SyncService بالظبط (مفيش SDK رسمي لـ Firebase على ويندوز).
/// دي نفس العقدة اللي بيستخدمها تطبيق الموبايل، فأي حساب يتضاف/يتعدّل من
/// هنا يظهر فورًا في الموبايل والعكس.
///
/// كل طلب هنا بيعدّي على FirebaseRestAuth.withAuth() عشان يضيف توكن
/// الدخول الحالي - من غيره قواعد الأمان (auth != null) هترفض الطلب.
class UserAccountService {
  UserAccountService({required String databaseUrl}) : _baseUrl = databaseUrl;

  final String _baseUrl;
  static const _timeout = Duration(seconds: 10);
  static const _path = 'app_users';

  Future<List<AppUserModel>> fetchUsers() async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$_path.json'));
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return [];
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return [];
    final result = <AppUserModel>[];
    decoded.forEach((key, value) {
      if (value is Map) {
        try {
          result.add(AppUserModel.fromMap(key.toString(), value));
        } catch (_) {
          // تجاهل أي سجل تالف
        }
      }
    });
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// بيتحقق هل الـ UID ده هو حساب الأدمن الرئيسي (config/adminUid المتحدد
  /// يدويًا من Firebase Console). بيرجع false افتراضيًا لو مش متأكدين
  Future<bool> isAdminUid(String uid) async {
    try {
      final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/config/adminUid.json'));
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded != null && decoded.toString() == uid;
    } catch (_) {
      return false;
    }
  }

  /// إضافة حساب عامل جديد - بينشئ حساب Firebase Authentication حقيقي
  /// (باسورد مهشّر عند Firebase، مش متخزّن عندنا خالص)، وبعدين سجل بياناته
  /// (بدون الباسورد) في app_users. بما إن ده REST بلا جلسة محلية، النداء
  /// ده مبيأثرش على جلسة الأدمن الحالية المسجّل بيها فعليًا.
  Future<String> addUser(String username, String password, {Map<String, bool>? permissions}) async {
    final trimmedUsername = username.trim();
    final email = usernameToAuthEmail(trimmedUsername);

    final error = await FirebaseRestAuth.createAccount(email, password);
    if (error != null) throw Exception(error);

    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$_path.json'));
    final response = await http
        .post(
          uri,
          body: jsonEncode({
            'username': trimmedUsername,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'permissions': permissions ?? {for (final s in AppUserModel.permissionScreens) s.key: true},
          }),
        )
        .timeout(_timeout);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['name'] as String;
  }

  Future<void> updateUserPermissions(String id, Map<String, bool> permissions) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$_path/$id.json'));
    await http.patch(uri, body: jsonEncode({'permissions': permissions})).timeout(_timeout);
  }

  Future<void> deleteUser(String id) async {
    final uri = await FirebaseRestAuth.withAuth(Uri.parse('$_baseUrl/$_path/$id.json'));
    await http.delete(uri).timeout(_timeout);
  }
}
