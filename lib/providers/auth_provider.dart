import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user_model.dart';
import '../services/local_account_service.dart';
import 'database_provider.dart';

class SessionUser {
  final String username;
  final bool isAdmin;
  final Map<String, bool> permissions;
  const SessionUser({
    required this.username,
    required this.isAdmin,
    required this.permissions,
  });
  bool can(String screenKey) => isAdmin || (permissions[screenKey] ?? false);
}

final userAccountServiceProvider = Provider<LocalAccountService>(
  (ref) => LocalAccountService(ref.watch(databaseProvider)),
);
final ownerExistsProvider = FutureProvider<bool>(
  (ref) => ref.watch(userAccountServiceProvider).hasOwner(),
);
final appUsersProvider = FutureProvider<List<AppUserModel>>(
  (ref) => ref.watch(userAccountServiceProvider).fetchUsers(),
);
final sessionProvider = FutureProvider<SessionUser?>((ref) async {
  final user = await ref.watch(userAccountServiceProvider).currentUser();
  if (user == null) return null;
  return SessionUser(
    username: user['username'] as String,
    isAdmin: user['isAdmin'] == true,
    permissions: Map<String, bool>.from(user['permissions'] as Map),
  );
});

class AuthRepository {
  AuthRepository(this.ref);
  final Ref ref;
  Future<String?> login(String username, String password) async {
    try {
      final service = ref.read(userAccountServiceProvider);
      final error = await service.login(username, password);
      if (error == null) ref.invalidate(sessionProvider);
      return error;
    } catch (_) {
      return 'تعذر قراءة الحساب المحلي. راجع النسخة الاحتياطية.';
    }
  }

  Future<String?> setupOwner(String username, String password) async {
    try {
      await ref
          .read(userAccountServiceProvider)
          .createOwner(username, password);
      ref.invalidate(ownerExistsProvider);
      return login(username, password);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await ref.read(userAccountServiceProvider).logout();
    ref.invalidate(sessionProvider);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref),
);
