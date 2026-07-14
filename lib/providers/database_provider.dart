import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

/// نسخة واحدة من قاعدة البيانات المحلية طول عمر التطبيق
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
