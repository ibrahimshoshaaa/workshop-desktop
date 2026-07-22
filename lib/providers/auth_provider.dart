import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase_config.dart';
import '../core/auth_email_mapper.dart';
import '../models/app_user_model.dart';
import '../services/user_account_service.dart';
import '../services/firebase_rest_auth.dart';
import 'database_provider.dart';

const _keyUsername = 'session_username';
const _keyIsAdmin = 'session_is_admin';
const _keyPermsJson = 'session_permissions_json';
const _keyRefreshToken = 'session_refresh_token';

/// جلسة المستخدم الحالي - مين داخل، هو أدمن ولا عامل، وإيه الشاشات
/// المسموح له يشوفها
class SessionUser {
  final String username;
  final bool isAdmin;
  final Map<String, bool> permissions;

  const SessionUser({required this.username, required this.isAdmin, required this.permissions});

  /// الأدمن عنده كل الصلاحيات دايمًا. العامل بيتحدد حسب permissions
  /// (وأي شاشة مش موجودة فيها بتتحسب "مسموحة" افتراضيًا)
  bool can(String screenKey) => isAdmin || (permissions[screenKey] ?? true);
}

final userAccountServiceProvider =
    Provider<UserAccountService>((ref) => UserAccountService(databaseUrl: firebaseDatabaseUrl));

final appUsersProvider = FutureProvider<List<AppUserModel>>((ref) {
  return ref.watch(userAccountServiceProvider).fetchUsers();
});

/// بيقرأ آخر جلسة محفوظة محليًا (لو موجودة)، وبيحاول يستعيد توكن Firebase
/// من الـ refresh token المحفوظ (بدل ما يفترض إن الجلسة سليمة من غير أي
/// تحقق حقيقي) - بنفس فكرة "Firebase بيحتفظ بالجلسة لوحده" بتاعة الموبايل،
/// لكن هنا بنعمل التخزين والاستعادة يدويًا بما إننا REST مش SDK
final sessionProvider = FutureProvider<SessionUser?>((ref) async {
  final db = ref.watch(databaseProvider);
  final username = await db.getMeta(_keyUsername);
  if (username == null || username.isEmpty) return null;

  final refreshToken = await db.getMeta(_keyRefreshToken);
  if (refreshToken == null || refreshToken.isEmpty) return null;

  final restored = await FirebaseRestAuth.restoreSession(refreshToken);
  if (!restored) return null; // الـ refresh token بقى غير صالح - يدخل تاني يدويًا

  final isAdmin = (await db.getMeta(_keyIsAdmin)) == 'true';
  final permsRaw = await db.getMeta(_keyPermsJson);
  final perms = <String, bool>{};
  if (permsRaw != null && permsRaw.isNotEmpty) {
    final decoded = jsonDecode(permsRaw) as Map;
    decoded.forEach((k, v) => perms[k.toString()] = v == true);
  }
  return SessionUser(username: username, isAdmin: isAdmin, permissions: perms);
});

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;

  /// بيرجع رسالة خطأ لو فشل الدخول، أو null لو نجح
  Future<String?> login(String username, String password) async {
    final trimmedUser = username.trim();
    final email = usernameToAuthEmail(trimmedUser);

    final error = await FirebaseRestAuth.signIn(email, password);
    if (error != null) return error;

    // نجح الدخول في Firebase - نحدد هل ده الأدمن (UID مطابق لـ
    // config/adminUid) ولا عامل (له سجل في app_users)
    final uid = FirebaseRestAuth.currentUid;
    bool admin = false;
    Map<String, bool> permissions = {};
    bool foundValidAccount = false;

    try {
      if (uid != null && await _ref.read(userAccountServiceProvider).isAdminUid(uid)) {
        admin = true;
        foundValidAccount = true;
      } else {
        final users = await _ref.read(userAccountServiceProvider).fetchUsers();
        final match = users.firstWhereOrNull((u) => u.username == trimmedUser);
        if (match != null) {
          permissions = match.permissions;
          foundValidAccount = true;
        }
      }
    } catch (_) {
      // مفيش نت نقدر نتأكد بيه - منسمحش بالدخول لحد ما نتأكد فعليًا
    }

    if (!foundValidAccount) {
      FirebaseRestAuth.clear();
      return 'الحساب ده متشالة صلاحياته أو مش موجود في التطبيق';
    }

    await _persistSession(username: trimmedUser, isAdmin: admin, permissions: permissions);
    return null;
  }

  Future<void> _persistSession({
    required String username,
    required bool isAdmin,
    required Map<String, bool> permissions,
  }) async {
    final db = _ref.read(databaseProvider);
    await db.setMeta(_keyUsername, username);
    await db.setMeta(_keyIsAdmin, isAdmin.toString());
    await db.setMeta(_keyPermsJson, jsonEncode(permissions));
    await db.setMeta(_keyRefreshToken, FirebaseRestAuth.refreshTokenForPersistence ?? '');
    _ref.invalidate(sessionProvider);
  }

  Future<void> logout() async {
    final db = _ref.read(databaseProvider);
    await db.setMeta(_keyUsername, '');
    await db.setMeta(_keyIsAdmin, '');
    await db.setMeta(_keyPermsJson, '');
    await db.setMeta(_keyRefreshToken, '');
    FirebaseRestAuth.clear();
    _ref.invalidate(sessionProvider);
  }

  /// بيحدّث صلاحيات المستخدم الحالي من Firebase - بيتنادى تلقائيًا بعد كل
  /// مزامنة ناجحة، عشان لو الأدمن غيّر صلاحيات حد وهو شغال، التغيير يوصله
  /// من غير ما يضطر يسجّل خروج ويدخل تاني
  Future<void> refreshCurrentUserPermissions() async {
    final session = await _ref.read(sessionProvider.future);
    if (session == null || session.isAdmin) return;
    try {
      final users = await _ref.read(userAccountServiceProvider).fetchUsers();
      final match = users.firstWhereOrNull((u) => u.username == session.username);
      if (match != null) {
        await _persistSession(username: match.username, isAdmin: false, permissions: match.permissions);
      }
    } catch (_) {
      // مفيش نت - نسيب الصلاحيات المحفوظة محليًا زي ما هي
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
