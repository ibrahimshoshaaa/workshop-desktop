import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import '../data/database.dart';
import 'local_media_service.dart';
import 'local_paths.dart';

class BackupService extends ChangeNotifier {
  BackupService(this.db, this.paths);
  final AppDatabase db;
  final LocalPaths paths;
  Timer? _timer;
  bool busy = false;
  bool restorePending = false;
  bool _disposed = false;
  String? lastBackup;
  String? error;
  String? secondaryFolder;
  static const requiredTables = [
    'customers',
    'orders',
    'payment_transactions',
    'expenses',
    'material_items',
    'workers',
    'worker_payments',
    'workshop_debts',
    'cash_transfers',
    'sync_meta',
  ];
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    secondaryFolder = await db.getMeta('backup_secondary_folder');
    lastBackup = await db.getMeta('last_local_backup');
    try {
      await createBackup();
    } catch (_) {
      /* The state exposes the failure. */
    }
    if (!_disposed)
      _timer = Timer.periodic(const Duration(hours: 1), (_) async {
        if (busy || restorePending) return;
        try {
          await createBackup();
        } catch (_) {
          /* Keep previous copies. */
        }
      });
  }

  Future<void> setSecondaryFolder(String? folder) async {
    secondaryFolder = folder;
    await db.setMeta('backup_secondary_folder', folder ?? '');
    _changed();
  }

  static Map<String, int> inspectDatabase(String file) {
    final sqlite = sqlite3.open(file, mode: OpenMode.readOnly);
    try {
      if (sqlite.select('PRAGMA quick_check').single.values.first != 'ok')
        throw const FormatException('قاعدة البيانات تالفة');
      final version =
          sqlite.select('PRAGMA user_version').single.values.first as int;
      if (version != 11)
        throw const FormatException('نسخة قاعدة البيانات غير متوافقة');
      final names = sqlite
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((r) => r['name'])
          .toSet();
      if (!requiredTables.every(names.contains))
        throw const FormatException('ملف قاعدة البيانات ناقص');
      return {
        for (final table in requiredTables)
          table:
              sqlite.select('SELECT COUNT(*) AS n FROM "$table"').single['n']
                  as int,
      };
    } finally {
      sqlite.dispose();
    }
  }

  Future<File> createBackup() async {
    if (busy || restorePending) throw StateError('عملية أخرى قيد التنفيذ');
    busy = true;
    error = null;
    _changed();
    Directory? staging;
    try {
      await paths.backups.create(recursive: true);
      staging = await paths.backups.createTemp('.snapshot-');
      final snapshot = File(p.join(staging.path, 'database.sqlite'));
      // SQLite makes a consistent snapshot, including committed WAL changes.
      await db.customSelect('SELECT 1').get();
      await db.customStatement('VACUUM INTO ?', [snapshot.path]);
      final sqlite = sqlite3.open(snapshot.path);
      try {
        sqlite.execute('PRAGMA secure_delete=ON');
        sqlite.execute(
          "DELETE FROM sync_meta WHERE key LIKE 'session_%' OR key = 'local_session_username'",
        );
        sqlite.execute('VACUUM');
      } finally {
        sqlite.dispose();
      }
      final counts = inspectDatabase(snapshot.path);
      final archive = Archive();
      final checksums = <String, String>{};
      Future<void> add(String name, File file) async {
        final bytes = await file.readAsBytes();
        checksums[name] = sha256.convert(bytes).toString();
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }

      await add('database.sqlite', snapshot);
      if (await paths.media.exists()) {
        await for (final entity in paths.media.list(followLinks: false)) {
          if (entity is File &&
              LocalMediaService.validName.hasMatch(p.basename(entity.path))) {
            await add('media/${p.basename(entity.path)}', entity);
          }
        }
      }
      final manifest = utf8.encode(
        jsonEncode({
          'format': 'workshop-local-backup',
          'version': 1,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'schemaVersion': 11,
          'counts': counts,
          'sha256': checksums,
        }),
      );
      archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest));
      final bytes = ZipEncoder().encode(archive)!;
      final name =
          'workshop-${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}-${DateTime.now().microsecondsSinceEpoch}.wbackup';
      final temporary = File(p.join(paths.backups.path, '$name.tmp'));
      await temporary.writeAsBytes(bytes, flush: true);
      await validateArchive(temporary);
      final result = await temporary.rename(p.join(paths.backups.path, name));
      lastBackup = result.path;
      await db.setMeta('last_local_backup', result.path);
      if (secondaryFolder != null && secondaryFolder!.isNotEmpty) {
        try {
          final folder = Directory(secondaryFolder!);
          if (!await folder.exists())
            throw StateError('مجلد النسخة الإضافية غير متاح');
          final copy = File(p.join(folder.path, '$name.tmp'));
          await copy.writeAsBytes(bytes, flush: true);
          await copy.rename(p.join(folder.path, name));
        } catch (e) {
          error = 'النسخة المحلية محفوظة، وتعذر النسخ للمجلد الإضافي: $e';
        }
      }
      // Only prune our own local snapshots after a validated new one exists.
      final copies = await paths.backups
          .list()
          .where(
            (f) =>
                f is File &&
                p.basename(f.path).startsWith('workshop-') &&
                f.path.endsWith('.wbackup'),
          )
          .cast<File>()
          .toList();
      copies.sort((a, b) => b.path.compareTo(a.path));
      for (final old in copies.skip(30)) {
        await old.delete();
      }
      return result;
    } catch (e) {
      error = 'فشل النسخ الاحتياطي: $e';
      rethrow;
    } finally {
      if (staging != null && await staging.exists())
        await staging.delete(recursive: true);
      busy = false;
      _changed();
    }
  }

  static Future<Archive> validateArchive(File file) async {
    if (await file.length() > 512 * 1024 * 1024)
      throw const FormatException('النسخة أكبر من الحد المدعوم 512 ميجابايت');
    final archive = ZipDecoder().decodeBytes(
      await file.readAsBytes(),
      verify: true,
    );
    final names = <String>{};
    var total = 0;
    for (final entry in archive) {
      final name = entry.name;
      final valid =
          name == 'manifest.json' ||
          name == 'database.sqlite' ||
          (name.startsWith('media/') &&
              LocalMediaService.validName.hasMatch(name.substring(6)));
      if (!entry.isFile || !valid || !names.add(name))
        throw const FormatException('ملف النسخة غير صالح');
      total += entry.size;
      if (total > 1024 * 1024 * 1024 || names.length > 10000)
        throw const FormatException('حجم النسخة غير مدعوم');
    }
    if (!names.containsAll(['manifest.json', 'database.sqlite']))
      throw const FormatException('النسخة ناقصة');
    final manifest =
        jsonDecode(
              utf8.decode(
                archive.findFile('manifest.json')!.content as List<int>,
              ),
            )
            as Map;
    if (manifest['format'] != 'workshop-local-backup' ||
        manifest['version'] != 1 ||
        manifest['schemaVersion'] != 11)
      throw const FormatException('صيغة النسخة غير متوافقة');
    final checksums = Map<String, dynamic>.from(manifest['sha256'] as Map);
    if (checksums.length != names.length - 1)
      throw const FormatException('سجل التحقق ناقص');
    for (final entry in archive.where((e) => e.name != 'manifest.json')) {
      if (sha256.convert(entry.content as List<int>).toString() !=
          checksums[entry.name])
        throw const FormatException('فشل التحقق من سلامة النسخة');
    }
    return archive;
  }

  Future<void> stageRestore(File source) async {
    if (busy || restorePending) throw StateError('عملية أخرى قيد التنفيذ');
    final archive = await validateArchive(source);
    // A fresh recovery copy is mandatory before scheduling a replacement.
    await createBackup();
    busy = true;
    _changed();
    try {
      final staging = paths.pendingRestore;
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);
      for (final entry in archive) {
        final file = File(p.join(staging.path, entry.name));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>, flush: true);
      }
      final counts = inspectDatabase(p.join(staging.path, 'database.sqlite'));
      final manifest =
          jsonDecode(
                await File(
                  p.join(staging.path, 'manifest.json'),
                ).readAsString(),
              )
              as Map;
      if (jsonEncode(counts) != jsonEncode(manifest['counts']))
        throw const FormatException('أعداد السجلات لا تطابق النسخة');
      await File(p.join(staging.path, 'ready')).writeAsString('1', flush: true);
      restorePending = true;
    } finally {
      busy = false;
      _changed();
    }
  }

  /// Called under the OS process lock, before any Drift connection is opened.
  static Future<void> applyPendingRestore(LocalPaths paths) async {
    final staging = paths.pendingRestore;
    if (!await File(p.join(staging.path, 'ready')).exists()) return;
    final candidate = File(p.join(staging.path, 'database.sqlite'));
    inspectDatabase(candidate.path);
    final manifest =
        jsonDecode(
              await File(p.join(staging.path, 'manifest.json')).readAsString(),
            )
            as Map;
    for (final entry in (manifest['sha256'] as Map).entries) {
      final name = entry.key as String;
      if (name != 'database.sqlite' &&
          !(name.startsWith('media/') &&
              LocalMediaService.validName.hasMatch(name.substring(6))))
        throw const FormatException('مسار استرجاع غير صالح');
      if (sha256
              .convert(await File(p.join(staging.path, name)).readAsBytes())
              .toString() !=
          entry.value)
        throw const FormatException('النسخة المجهزة تغيرت');
    }
    await paths.media.create(recursive: true);
    final savedMedia = Directory(p.join(staging.path, 'media'));
    if (await savedMedia.exists()) {
      await for (final entry in savedMedia.list(followLinks: false)) {
        if (entry is File)
          await entry.copy(p.join(paths.media.path, p.basename(entry.path)));
      }
    }
    final replacement = File('${paths.database.path}.replacement');
    await candidate.copy(replacement.path);
    final rollback = Directory(
      p.join(
        paths.backups.path,
        'before-restore-${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    await rollback.create(recursive: true);
    final moved = <String>[];
    try {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        final old = File('${paths.database.path}$suffix');
        if (await old.exists()) {
          await old.rename(p.join(rollback.path, 'database.sqlite$suffix'));
          moved.add(suffix);
        }
      }
      await replacement.rename(paths.database.path);
    } catch (_) {
      for (final suffix in moved) {
        await File(
          p.join(rollback.path, 'database.sqlite$suffix'),
        ).rename('${paths.database.path}$suffix');
      }
      rethrow;
    }
    await staging.delete(recursive: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
