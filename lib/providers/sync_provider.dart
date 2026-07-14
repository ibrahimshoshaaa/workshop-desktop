import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/firebase_config.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(
    db,
    databaseUrl: firebaseDatabaseUrl,
    // بعد كل مزامنة ناجحة، نحدّث صلاحيات المستخدم الحالي (لو مش أدمن) من
    // Firebase - عشان أي تغيير في صلاحياته يوصله من غير ما يسجّل خروج ودخول
    onSynced: () => ref.read(authRepositoryProvider).refreshCurrentUserPermissions(),
  );
  ref.onDispose(service.dispose);
  return service;
});
