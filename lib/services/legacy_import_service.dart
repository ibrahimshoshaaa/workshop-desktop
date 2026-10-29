import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import '../data/database.dart';
import 'backup_service.dart';

class ImportRecord {
  ImportRecord(this.node, this.table, this.incoming, this.existing);
  final String node;
  final TableInfo table;
  final Map<String, dynamic> incoming;
  final Map<String, dynamic>? existing;
  bool useIncoming = false; // Conflicts preserve the laptop record by default.
  bool get isNew => existing == null;
  String get label =>
      '${incoming['name'] ?? incoming['customer_name'] ?? incoming['creditor_name'] ?? incoming['id']}';
}

class ImportPreview {
  ImportPreview(this.source, this.records, this.unchanged);
  final File source;
  final List<ImportRecord> records;
  final int unchanged;
  Iterable<ImportRecord> get conflicts => records.where((r) => !r.isNew);
  int get additions => records.where((r) => r.isNew).length;
}

/// A Firebase Console JSON export is read locally. Never calls Firebase and
/// never interprets remote absence as a deletion from the laptop database.
class LegacyImportService {
  LegacyImportService(this.db, this.backups);
  final AppDatabase db;
  final BackupService backups;
  static const nodeTables = {
    'customers': 'customers',
    'orders': 'orders',
    'transactions': 'payment_transactions',
    'expenses': 'expenses',
    'materials': 'material_items',
    'workers': 'workers',
    'workerPayments': 'worker_payments',
    'workshopDebts': 'workshop_debts',
    'cashTransfers': 'cash_transfers',
  };

  static String _snake(String key) =>
      key.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
  static bool _equal(Map<String, dynamic> a, Map<String, dynamic> b) => a.keys
      .where((k) => k != 'dirty' && k != 'updated_at')
      .every((k) => a[k] == b[k]);

  Future<ImportPreview> preview(File source) async {
    if (await source.length() > 128 * 1024 * 1024)
      throw const FormatException('ملف الاستيراد كبير جدًا');
    final decoded = jsonDecode(await source.readAsString());
    if (decoded is! Map || !nodeTables.keys.any(decoded.containsKey))
      throw const FormatException(
        'اختار تصدير JSON من جذر Firebase ويحتوي على جداول الورشة',
      );
    final records = <ImportRecord>[];
    var unchanged = 0;
    for (final spec in nodeTables.entries) {
      final raw = decoded[spec.key];
      if (raw == null) continue;
      if (raw is! Map) throw FormatException('صيغة جدول ${spec.key} غير صالحة');
      final table = db.allTables.firstWhere(
        (t) => t.actualTableName == spec.value,
      );
      final columns = await db
          .customSelect('PRAGMA table_info("${spec.value}")')
          .get();
      final existing = {
        for (final row
            in await db.customSelect('SELECT * FROM "${spec.value}"').get())
          row.data['id']: row.data,
      };
      for (final entry in raw.entries) {
        if (entry.value is! Map || entry.key.toString().isEmpty)
          throw FormatException('سجل تالف في ${spec.key}');
        final remote = Map<String, dynamic>.from(entry.value as Map);
        final id = entry.key.toString();
        if (remote['id'] != null && remote['id'] != id)
          throw FormatException('معرّف متعارض في ${spec.key}');
        final previous = existing[id];
        final values = <String, dynamic>{
          for (final e in remote.entries) _snake(e.key): e.value,
          'id': id,
        };
        values['updated_at'] ??=
            values['created_at'] ??
            values['payment_date'] ??
            values['date'] ??
            0;
        values['created_at'] ??= values['updated_at'];
        if (spec.key == 'orders' && remote.containsKey('images')) {
          final images = remote['images'];
          if (images != null && images is! Map && images is! List)
            throw const FormatException('قائمة صور غير صالحة');
          values['images_json'] = jsonEncode(
            images is Map ? images.values.toList() : images ?? [],
          );
        }
        final result = <String, dynamic>{};
        for (final column in columns) {
          final name = column.data['name'] as String;
          dynamic value = values[name];
          if (!values.containsKey(name)) {
            if (previous != null) {
              value = previous[name];
            } else if (column.data['dflt_value'] != null) {
              value =
                  (await db
                          .customSelect(
                            'SELECT ${column.data['dflt_value']} AS v',
                          )
                          .getSingle())
                      .data['v'];
            } else if (column.data['notnull'] == 1) {
              throw FormatException('الحقل $name ناقص في ${spec.key}/$id');
            }
          }
          final type = column.data['type'] as String;
          if (value is bool) value = value ? 1 : 0;
          if (value != null &&
              ((type == 'TEXT' && value is! String) ||
                  (type == 'INTEGER' && value is! int) ||
                  (type == 'REAL' && (value is! num || !value.isFinite))))
            throw FormatException('قيمة غير صالحة: ${spec.key}/$id/$name');
          if (value == null && column.data['notnull'] == 1)
            throw FormatException('قيمة مطلوبة: ${spec.key}/$id/$name');
          result[name] = value;
        }
        result['dirty'] = 0;
        if (previous != null && _equal(result, previous)) {
          unchanged++;
          continue;
        }
        records.add(ImportRecord(spec.key, table, result, previous));
      }
    }
    return ImportPreview(source, records, unchanged);
  }

  Future<int> apply(ImportPreview preview) async {
    if (backups.restorePending)
      throw StateError('أعد تشغيل البرنامج لإتمام الاسترجاع أولًا');
    await backups.createBackup();
    final sources = Directory(
      p.join(backups.paths.backups.path, 'firebase-exports'),
    );
    await sources.create(recursive: true);
    await preview.source.copy(
      p.join(
        sources.path,
        'firebase-${DateTime.now().microsecondsSinceEpoch}.json',
      ),
    );
    var changed = 0;
    await db.transaction(() async {
      final touchedOrders = <String>{};
      for (final record in preview.records) {
        // Reject an out-of-date preview if any record changed while reviewing.
        final live = await db
            .customSelect(
              'SELECT * FROM "${record.table.actualTableName}" WHERE id = ?',
              variables: [Variable<String>(record.incoming['id'] as String)],
            )
            .getSingleOrNull();
        if ((record.existing == null && live != null) ||
            (record.existing != null &&
                (live == null ||
                    jsonEncode(live.data) != jsonEncode(record.existing))))
          throw StateError(
            'البيانات اتغيرت أثناء المراجعة. افتح الاستيراد من جديد.',
          );
        if (!record.isNew && !record.useIncoming) continue;
        final values = record.incoming;
        final names = values.keys.toList();
        final parameters = <Variable>[
          for (final name in names)
            values[name] is int
                ? Variable<int>(values[name] as int)
                : values[name] is num
                ? Variable<double>((values[name] as num).toDouble())
                : Variable<String>(values[name] as String?),
        ];
        String quote(String name) => '"${name.replaceAll('"', '""')}"';
        final columns = names.map(quote).join(', ');
        final placeholders = List.filled(names.length, '?').join(', ');
        final assignments = names
            .where((n) => n != 'id')
            .map((n) => '${quote(n)} = excluded.${quote(n)}')
            .join(', ');
        // TableInfo is selected at runtime. A RawValuesInsertable<dynamic>
        // fails the generated typed integrity checks. The preview validates
        // columns/types, SQLite enforces constraints, and updates notifies Drift.
        await db.customInsert(
          'INSERT INTO ${quote(record.table.actualTableName)} ($columns) '
          'VALUES ($placeholders) ON CONFLICT (id) DO UPDATE SET $assignments',
          variables: parameters,
          updates: {record.table},
        );
        if (record.node == 'orders') touchedOrders.add(values['id'] as String);
        if (record.node == 'transactions')
          touchedOrders.add(values['order_id'] as String);
        changed++;
      }
      for (final id in touchedOrders) {
        final order = await (db.select(
          db.orders,
        )..where((o) => o.id.equals(id))).getSingleOrNull();
        if (order == null) throw StateError('دفعة مرتبطة بطلب غير موجود: $id');
        if (!order.isDeleted &&
            (order.totalPaid - await db.sumPaymentsForOrder(id)).abs() > 0.01)
          throw StateError(
            'إجمالي دفعات طلب ${order.customerName} لا يطابق المدفوع. راجع اختيار الطلب ودفعاته معًا. لم يتم الاستيراد.',
          );
        if (!order.isDeleted) {
          final customer = await (db.select(
            db.customers,
          )..where((c) => c.id.equals(order.customerId))).getSingleOrNull();
          if (customer == null)
            throw StateError('عميل الطلب غير موجود: ${order.customerName}');
        }
      }
    });
    return changed;
  }
}
