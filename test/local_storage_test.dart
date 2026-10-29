import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_desktop/data/database.dart';
import 'package:workshop_desktop/data/local_repository.dart';
import 'package:workshop_desktop/services/backup_service.dart';
import 'package:workshop_desktop/services/legacy_import_service.dart';
import 'package:workshop_desktop/services/local_account_service.dart';
import 'package:workshop_desktop/services/local_media_service.dart';
import 'package:workshop_desktop/services/local_paths.dart';

void main() {
  late Directory temp;
  late LocalPaths paths;
  late AppDatabase db;
  late LocalRepository repo;
  late BackupService backups;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('workshop-test-');
    paths = LocalPaths(temp);
    db = AppDatabase.withExecutor(NativeDatabase(paths.database));
    repo = LocalRepository(db);
    backups = BackupService(db, paths);
  });
  tearDown(() async {
    backups.dispose();
    await db.close();
    await temp.delete(recursive: true);
  });
  Future<String> addOrder() async {
    await repo.addCustomer(
      name: 'عميل اختبار',
      phone: '01012345678',
      address: '',
    );
    final customer = (await db.select(db.customers).get()).single;
    return repo.addOrder(
      customerId: customer.id,
      customerName: customer.name,
      itemType: 'كنبة',
      details: '',
      totalAmount: 1000,
      deliveryDate: DateTime(2030),
    );
  }

  test(
    'first launch copies existing local data without changing the legacy file or replacing later work',
    () async {
      await db.close();
      if (await paths.database.exists()) await paths.database.delete();
      final legacy = AppDatabase.withExecutor(
        NativeDatabase(paths.legacyDatabase),
      );
      try {
        await LocalRepository(
          legacy,
        ).addCustomer(name: 'عميل قديم', phone: '1', address: '');
        final originalBytes = await paths.legacyDatabase.readAsBytes();
        await paths.prepareLocalDatabase();
        db = AppDatabase.withExecutor(NativeDatabase(paths.database));
        repo = LocalRepository(db);
        expect(await paths.legacyDatabase.readAsBytes(), originalBytes);
        expect((await db.select(db.customers).get()).single.name, 'عميل قديم');
        await repo.addCustomer(name: 'عميل جديد', phone: '2', address: '');
        await paths.prepareLocalDatabase();
        expect((await db.select(db.customers).get()).length, 2);
        expect((await legacy.select(legacy.customers).get()).length, 1);
      } finally {
        await legacy.close();
      }
    },
  );

  test(
    'offline owner and workers use salted hashes, reject wrong passwords, and retain permissions after reopen',
    () async {
      final accounts = LocalAccountService(db);
      await accounts.createOwner('manager', 'owner-password');
      expect(await accounts.login('manager', 'wrong-password'), isNotNull);
      expect(await accounts.login('manager', 'owner-password'), isNull);
      await accounts.addUser(
        'cashier',
        'worker-password',
        permissions: {'orders': true},
      );
      expect(
        await db.getMeta(LocalAccountService.usersKey),
        isNot(contains('owner-password')),
      );
      expect(
        await db.getMeta(LocalAccountService.usersKey),
        isNot(contains('worker-password')),
      );
      await accounts.logout();
      expect(await accounts.login('cashier', 'worker-password'), isNull);
      expect((await accounts.currentUser())!['permissions'], {'orders': true});
      await expectLater(
        accounts.addUser('unauthorized', 'new-password'),
        throwsStateError,
      );
      await db.close();
      db = AppDatabase.withExecutor(NativeDatabase(paths.database));
      expect(
        (await LocalAccountService(db).currentUser())!['username'],
        'cashier',
      );
    },
  );

  test(
    'concurrent payments are not lost and committed values survive restart',
    () async {
      final id = await addOrder();
      final order = await (db.select(
        db.orders,
      )..where((o) => o.id.equals(id))).getSingle();
      await Future.wait(
        [100.0, 200.0, 300.0].map(
          (amount) => repo.addPayment(
            orderId: id,
            customerId: order.customerId,
            amount: amount,
            paymentType: 'installment',
          ),
        ),
      );
      await repo.updateOrderStatus(id, 'تم التسليم');
      expect(await db.sumPaymentsForOrder(id), 600);
      expect(
        (await (db.select(
          db.orders,
        )..where((o) => o.id.equals(id))).getSingle()).totalPaid,
        600,
      );
      await db.close();
      db = AppDatabase.withExecutor(NativeDatabase(paths.database));
      final persisted = await (db.select(
        db.orders,
      )..where((o) => o.id.equals(id))).getSingle();
      expect(persisted.totalPaid, 600);
      expect(persisted.status, 'تم التسليم');
    },
  );

  test('failed dependent ledger update rolls back the payment', () async {
    final id = await addOrder();
    final order = await (db.select(
      db.orders,
    )..where((o) => o.id.equals(id))).getSingle();
    await db.customStatement(
      "CREATE TRIGGER reject_total BEFORE UPDATE OF total_paid ON orders BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      repo.addPayment(
        orderId: id,
        customerId: order.customerId,
        amount: 100,
        paymentType: 'installment',
      ),
      throwsA(anything),
    );
    expect(await db.select(db.paymentTransactions).get(), isEmpty);
  });

  test(
    'live backup and restore retain business rows and media but strip sessions and Firebase tokens',
    () async {
      await addOrder();
      await db.setMeta('session_refresh_token', 'must-not-leak');
      final accounts = LocalAccountService(db);
      await accounts.createOwner('manager', 'owner-password');
      await accounts.login('manager', 'owner-password');
      final media = LocalMediaService(paths);
      final ref = await media.save([1, 2, 3, 4]);
      final backup = await backups.createBackup();
      final archive = await BackupService.validateArchive(backup);
      expect(
        archive.findFile('media/${media.fileFor(ref).uri.pathSegments.last}'),
        isNotNull,
      );
      await repo.addCustomer(name: 'بعد النسخة', phone: '2', address: '');
      await backups.stageRestore(backup);
      await db.close();
      await BackupService.applyPendingRestore(paths);
      db = AppDatabase.withExecutor(NativeDatabase(paths.database));
      expect((await db.select(db.customers).get()).length, 1);
      expect(await db.getMeta('session_refresh_token'), isNull);
      expect(await LocalAccountService(db).currentUser(), isNull);
      expect(
        await LocalAccountService(db).login('manager', 'owner-password'),
        isNull,
      );
      expect(await media.fileFor(ref).readAsBytes(), [1, 2, 3, 4]);
      expect(
        await paths.backups
            .list()
            .where((f) => f is Directory && f.path.contains('before-restore-'))
            .length,
        1,
      );
    },
  );

  test('invalid backup checksum is rejected before any data changes', () async {
    await addOrder();
    final source = await backups.createBackup();
    final original = await BackupService.validateArchive(source);
    final damaged = Archive();
    for (final entry in original) {
      final bytes = entry.name == 'database.sqlite'
          ? <int>[0, 1, 2]
          : entry.content as List<int>;
      damaged.addFile(ArchiveFile(entry.name, bytes.length, bytes));
    }
    final file = File('${temp.path}/damaged.wbackup');
    await file.writeAsBytes(ZipEncoder().encode(damaged)!);
    await expectLater(backups.stageRestore(file), throwsFormatException);
    expect((await db.select(db.customers).get()).length, 1);
    expect(backups.restorePending, isFalse);
  });

  test(
    'Firebase import preserves laptop-only data and makes conflict choices explicit',
    () async {
      await repo.addCustomer(name: 'محلي', phone: '1', address: '');
      final local = (await db.select(db.customers).get()).single;
      final file = File('${temp.path}/firebase.json');
      await file.writeAsString(
        jsonEncode({
          'customers': {
            local.id: {
              'name': 'بعيد',
              'phone': '2',
              'createdAt': local.createdAt,
              'updatedAt': local.updatedAt + 1,
            },
            'remote-only': {
              'name': 'جديد',
              'phone': '3',
              'createdAt': 1,
              'updatedAt': 2,
            },
          },
        }),
      );
      final service = LegacyImportService(db, backups);
      final preview = await service.preview(file);
      expect(preview.additions, 1);
      expect(preview.conflicts.length, 1);
      await service.apply(preview);
      expect((await db.select(db.customers).get()).length, 2);
      expect(
        (await (db.select(
          db.customers,
        )..where((c) => c.id.equals(local.id))).getSingle()).name,
        'محلي',
      );
      final second = await service.preview(file);
      second.conflicts.single.useIncoming = true;
      await service.apply(second);
      expect(
        (await (db.select(
          db.customers,
        )..where((c) => c.id.equals(local.id))).getSingle()).name,
        'بعيد',
      );
    },
  );

  test(
    'stale Firebase review is rejected without losing the later local edit',
    () async {
      await repo.addCustomer(name: 'الأول', phone: '1', address: '');
      final local = (await db.select(db.customers).get()).single;
      final file = File('${temp.path}/firebase.json');
      await file.writeAsString(
        jsonEncode({
          'customers': {
            local.id: {
              'name': 'Firebase',
              'phone': '2',
              'createdAt': 1,
              'updatedAt': 2,
            },
          },
        }),
      );
      final service = LegacyImportService(db, backups);
      final preview = await service.preview(file);
      preview.conflicts.single.useIncoming = true;
      await repo.updateCustomer(
        local,
        name: 'تعديل أحدث',
        phone: '3',
        address: '',
      );
      await expectLater(service.apply(preview), throwsStateError);
      expect((await db.select(db.customers).get()).single.name, 'تعديل أحدث');
    },
  );
  test('inconsistent imported ledger rolls back the whole batch', () async {
    final orderId = await addOrder();
    final order = await (db.select(
      db.orders,
    )..where((o) => o.id.equals(orderId))).getSingle();
    final file = File('${temp.path}/bad-ledger.json');
    await file.writeAsString(
      jsonEncode({
        'transactions': {
          'tx-1': {
            'orderId': orderId,
            'customerId': order.customerId,
            'amountPaid': 100,
            'paymentDate': 10,
            'paymentType': 'installment',
            'updatedAt': 10,
          },
        },
      }),
    );
    final service = LegacyImportService(db, backups);
    final preview = await service.preview(file);
    await expectLater(service.apply(preview), throwsStateError);
    expect(await db.select(db.paymentTransactions).get(), isEmpty);
    expect((await db.select(db.orders).get()).single.totalPaid, 0);
  });

  test(
    'unavailable secondary folder retains the validated local backup',
    () async {
      await addOrder();
      await backups.setSecondaryFolder('${temp.path}/missing-secondary-folder');
      final copy = await backups.createBackup();
      expect(await copy.exists(), isTrue);
      await BackupService.validateArchive(copy);
      expect(backups.error, contains('النسخة المحلية محفوظة'));
    },
  );
}
