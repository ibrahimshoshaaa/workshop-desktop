import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../data/database.dart';
import '../models/app_user_model.dart';

/// Credentials are local PBKDF2 hashes; legacy Firebase tokens are never used.
class LocalAccountService {
  LocalAccountService(this.db);
  final AppDatabase db;
  static const usersKey = 'local_users_v1';
  static const sessionKey = 'local_session_username';
  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  Future<List<Map<String, dynamic>>> _users() async {
    final raw = await db.getMeta(usersKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<bool> hasOwner() async =>
      (await _users()).any((u) => u['isAdmin'] == true);
  Future<void> _save(List<Map<String, dynamic>> users) =>
      db.setMeta(usersKey, jsonEncode(users));

  static Future<Map<String, String>> credentials(String password) async {
    if (password.length < 8)
      throw StateError('كلمة المرور لازم تكون 8 حروف أو أرقام على الأقل');
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    final key = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return {
      'salt': base64Encode(salt),
      'hash': base64Encode(await key.extractBytes()),
    };
  }

  Future<void> createOwner(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty) throw StateError('اكتب اسم المستخدم');
    final credential = await credentials(password);
    await db.transaction(() async {
      if (await hasOwner()) throw StateError('حساب المدير موجود بالفعل');
      await _save([
        {
          'id': 'local-owner',
          'username': name,
          'isAdmin': true,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'permissions': {
            for (final s in AppUserModel.permissionScreens) s.key: true,
          },
          ...credential,
        },
      ]);
    });
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final name = await db.getMeta(sessionKey);
    if (name == null || name.isEmpty) return null;
    for (final user in await _users()) {
      if (user['username'] == name) return user;
    }
    return null;
  }

  Future<String?> login(String username, String password) async {
    Map<String, dynamic>? found;
    for (final user in await _users()) {
      if (user['username'] == username.trim()) found = user;
    }
    if (found == null) return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    final key = await _kdf.deriveKeyFromPassword(
      password: password,
      nonce: base64Decode(found['salt'] as String),
    );
    final actual = await key.extractBytes();
    final expected = base64Decode(found['hash'] as String);
    var difference = actual.length ^ expected.length;
    for (var i = 0; i < actual.length && i < expected.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    if (difference != 0) return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    await db.setMeta(sessionKey, found['username'] as String);
    return null;
  }

  Future<void> logout() => db.setMeta(sessionKey, '');

  Future<void> _requireOwner() async {
    if ((await currentUser())?['isAdmin'] != true)
      throw StateError('العملية متاحة للمدير فقط');
  }

  Future<List<AppUserModel>> fetchUsers() async {
    await _requireOwner();
    return (await _users())
        .where((u) => u['isAdmin'] != true)
        .map((u) => AppUserModel.fromMap(u['id'] as String, u))
        .toList();
  }

  Future<String> addUser(
    String username,
    String password, {
    Map<String, bool>? permissions,
  }) async {
    final name = username.trim();
    if (name.isEmpty) throw StateError('اكتب اسم المستخدم');
    final credential = await credentials(password);
    return db.transaction(() async {
      await _requireOwner();
      final users = await _users();
      if (users.any((u) => u['username'] == name))
        throw StateError('اسم المستخدم موجود بالفعل');
      final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
      users.add({
        'id': id,
        'username': name,
        'isAdmin': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'permissions': permissions ?? <String, bool>{},
        ...credential,
      });
      await _save(users);
      return id;
    });
  }

  Future<void> updateUserPermissions(
    String id,
    Map<String, bool> permissions,
  ) => db.transaction(() async {
    await _requireOwner();
    final users = await _users();
    final user = users.firstWhere((u) => u['id'] == id && u['isAdmin'] != true);
    user['permissions'] = permissions;
    await _save(users);
  });

  Future<void> resetPassword(String id, String password) async {
    final credential = await credentials(password);
    await db.transaction(() async {
      await _requireOwner();
      final users = await _users();
      users.firstWhere((u) => u['id'] == id).addAll(credential);
      await _save(users);
    });
  }

  Future<void> deleteUser(String id) => db.transaction(() async {
    await _requireOwner();
    final users = await _users();
    if (users.any((u) => u['id'] == id && u['isAdmin'] == true))
      throw StateError('لا يمكن حذف المدير');
    users.removeWhere((u) => u['id'] == id);
    await _save(users);
  });
}
