import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user_model.dart';

/// خدمة إدارة حسابات العمال (app_users) عن طريق REST API مباشرة - بنفس
/// طريقة SyncService بالظبط (مفيش SDK رسمي لـ Firebase على ويندوز).
/// دي نفس العقدة اللي بيستخدمها تطبيق الموبايل، فأي حساب يتضاف/يتعدّل من
/// هنا يظهر فورًا في الموبايل والعكس.
class UserAccountService {
  UserAccountService({required String databaseUrl}) : _baseUrl = databaseUrl;

  final String _baseUrl;
  static const _timeout = Duration(seconds: 10);
  static const _path = 'app_users';

  Future<List<AppUserModel>> fetchUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/$_path.json')).timeout(_timeout);
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

  /// بيرجع اليوزر لو اليوزرنيم والباسورد مطابقين لحساب موجود في app_users،
  /// أو null لو مفيش تطابق أو حصل خطأ اتصال (زي مفيش نت)
  Future<AppUserModel?> verifyUser(String username, String password) async {
    final users = await fetchUsers();
    for (final u in users) {
      if (u.username == username && u.password == password) return u;
    }
    return null;
  }

  /// إضافة حساب جديد - لو مبعتش [permissions] بيتضاف بكل الصلاحيات مفعّلة
  /// افتراضيًا (زي أي حساب عامل جديد من الموبايل)، وتقدر تحدد صلاحيات
  /// مخصوصة من الأول وقت الإضافة لو حبيت
  Future<String> addUser(String username, String password, {Map<String, bool>? permissions}) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$_path.json'),
          body: jsonEncode({
            'username': username,
            'password': password,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'permissions': permissions ?? {for (final s in AppUserModel.permissionScreens) s.key: true},
          }),
        )
        .timeout(_timeout);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['name'] as String;
  }

  Future<void> updateUserPassword(String id, String newPassword) async {
    await http
        .patch(Uri.parse('$_baseUrl/$_path/$id.json'), body: jsonEncode({'password': newPassword}))
        .timeout(_timeout);
  }

  Future<void> updateUserPermissions(String id, Map<String, bool> permissions) async {
    await http
        .patch(Uri.parse('$_baseUrl/$_path/$id.json'), body: jsonEncode({'permissions': permissions}))
        .timeout(_timeout);
  }

  Future<void> deleteUser(String id) async {
    await http.delete(Uri.parse('$_baseUrl/$_path/$id.json')).timeout(_timeout);
  }
}
