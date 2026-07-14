import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_credentials.dart';
import '../core/firebase_config.dart';
import '../models/app_user_model.dart';
import '../services/user_account_service.dart';
import 'database_provider.dart';

const _keyUsername = 'session_username';
const _keyIsAdmin = 'session_is_admin';
const _keyPermsJson = 'session_permissions_json';

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

/// بيقرأ آخر جلسة محفوظة محليًا (لو موجودة) عشان المستخدم يفضل داخل حتى
/// لو قفل التطبيق وفتحه تاني - بنفس سلوك الموبايل تمامًا
final sessionProvider = FutureProvider<SessionUser?>((ref) async {
  final db = ref.watch(databaseProvider);
  final username = await db.getMeta(_keyUsername);
  if (username == null || username.isEmpty) return null;

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

    // الحساب الرئيسي الثابت في الكود - خط أمان دائم، يفضل شغال حتى لو
    // مفيش نت أو حصلت أي مشكلة في app_users
    if (trimmedUser == AppCredentials.username && password == AppCredentials.password) {
      await _persistSession(username: trimmedUser, isAdmin: true, permissions: {});
      return null;
    }

    AppUserModel? extraUser;
    try {
      extraUser = await _ref.read(userAccountServiceProvider).verifyUser(trimmedUser, password);
    } catch (_) {
      extraUser = null;
    }

    if (extraUser != null) {
      await _persistSession(username: extraUser.username, isAdmin: false, permissions: extraUser.permissions);
      return null;
    }

    return 'اليوزر أو الباسورد غلط، أو مفيش إنترنت للتحقق من الحساب';
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
    _ref.invalidate(sessionProvider);
  }

  Future<void> logout() async {
    final db = _ref.read(databaseProvider);
    await db.setMeta(_keyUsername, '');
    await db.setMeta(_keyIsAdmin, '');
    await db.setMeta(_keyPermsJson, '');
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
