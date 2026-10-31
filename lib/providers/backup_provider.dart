import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import '../services/local_paths.dart';
import 'database_provider.dart';

final localPathsProvider = Provider<LocalPaths>(
  (ref) => throw StateError('LocalPaths must be initialized at startup'),
);
final backupServiceProvider = ChangeNotifierProvider<BackupService>(
  (ref) =>
      BackupService(ref.watch(databaseProvider), ref.watch(localPathsProvider)),
);
