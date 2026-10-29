import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Keep the original application support directory; preserve the legacy file
/// and initialize an independent database with a consistent read-only snapshot.
class LocalPaths {
  LocalPaths(this.root);
  final Directory root;
  static Future<LocalPaths> load() async =>
      LocalPaths(await getApplicationSupportDirectory());
  File get database => File(p.join(root.path, 'workshop_desktop_local.sqlite'));
  File get legacyDatabase => File(p.join(root.path, 'workshop_desktop.sqlite'));
  Directory get media => Directory(p.join(root.path, 'media'));
  Directory get backups => Directory(p.join(root.path, 'backups'));
  Directory get pendingRestore =>
      Directory(p.join(root.path, 'pending-restore'));
  Future<void> prepareLocalDatabase() async {
    await root.create(recursive: true);
    if (await database.exists() || !await legacyDatabase.exists()) return;
    final temporary = File('${database.path}.migration');
    if (await temporary.exists()) await temporary.delete();
    final source = sqlite3.open(legacyDatabase.path, mode: OpenMode.readOnly);
    try {
      source.execute('PRAGMA busy_timeout=5000');
      if (source.select('PRAGMA quick_check').single.values.first != 'ok')
        throw const FormatException(
          'قاعدة البيانات القديمة تحتاج مراجعة قبل التحويل',
        );
      final version =
          source.select('PRAGMA user_version').single.values.first as int;
      if (version < 1 || version > 11)
        throw const FormatException('نسخة البيانات القديمة غير مدعومة');
      source.execute('VACUUM INTO ?', [temporary.path]);
    } finally {
      source.dispose();
    }
    await temporary.rename(database.path);
  }
}

/// An OS file lock is released even when Windows terminates the process.
/// Never delete the lock file: another process may already be waiting on it.
class SingleInstanceLock {
  SingleInstanceLock._(this._handle);
  final RandomAccessFile _handle;
  static Future<SingleInstanceLock> acquire(LocalPaths paths) async {
    await paths.root.create(recursive: true);
    final file = File(p.join(paths.root.path, 'desktop.lock'));
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.exclusive, 0, 1);
      return SingleInstanceLock._(handle);
    } catch (_) {
      await handle.close();
      throw StateError('البرنامج مفتوح بالفعل. ارجع للنافذة المفتوحة.');
    }
  }

  Future<void> release() async {
    await _handle.unlock(0, 1);
    await _handle.close();
  }
}
