import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

/// حالة تسجيل الدخول لجلسة التشغيل الحالية بس - مش متخزنة على القرص
/// عن قصد، عشان لو الحماية مفعّلة المستخدم يضطر يدخل كلمة المرور تاني
/// في كل مرة يفتح فيها التطبيق (مش بس أول مرة)
final isLoggedInProvider = StateProvider<bool>((ref) => false);

class AuthSettings {
  final bool enabled;
  final String password;
  const AuthSettings({required this.enabled, required this.password});
}

const _authEnabledKey = 'auth_enabled';
const _authPasswordKey = 'auth_password';

/// بيقرأ إعدادات الحماية بكلمة مرور من التخزين المحلي (جدول syncMeta -
/// مش بيتزامن مع Firebase، فبيفضل كل جهاز له إعداداته الخاصة)
final authSettingsProvider = FutureProvider<AuthSettings>((ref) async {
  final db = ref.watch(databaseProvider);
  final enabled = await db.getMeta(_authEnabledKey);
  final password = await db.getMeta(_authPasswordKey);
  return AuthSettings(enabled: enabled == 'true', password: password ?? '');
});

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;

  Future<void> setPassword(String password) async {
    final db = _ref.read(databaseProvider);
    await db.setMeta(_authPasswordKey, password);
    await db.setMeta(_authEnabledKey, 'true');
    _ref.invalidate(authSettingsProvider);
  }

  Future<void> disableProtection() async {
    final db = _ref.read(databaseProvider);
    await db.setMeta(_authEnabledKey, 'false');
    _ref.invalidate(authSettingsProvider);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
