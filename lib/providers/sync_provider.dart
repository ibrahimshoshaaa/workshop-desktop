import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';

/// رابط قاعدة بيانات Firebase - نفس المشروع اللي شغال عليه تطبيق الموبايل بالظبط
const firebaseDatabaseUrl = 'https://workshopmanage-e7555-default-rtdb.firebaseio.com';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db, databaseUrl: firebaseDatabaseUrl);
  ref.onDispose(service.dispose);
  return service;
});
