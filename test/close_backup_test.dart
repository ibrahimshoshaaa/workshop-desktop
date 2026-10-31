import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_desktop/data/database.dart';
import 'package:workshop_desktop/providers/mutation_provider.dart';
import 'package:workshop_desktop/screens/close_backup_dialog.dart';
import 'package:workshop_desktop/services/backup_service.dart';
import 'package:workshop_desktop/services/desktop_close_guard.dart';
import 'package:workshop_desktop/services/local_paths.dart';

class FakeBackup extends BackupService {
  FakeBackup(super.db, super.paths);
  int calls = 0;
  bool failLocal = false;
  bool failSecondary = false;
  Completer<void>? gate;

  @override
  Future<File> createBackup() async {
    calls++;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (gate != null) await gate!.future;
      if (failLocal) throw StateError('قرص غير متاح');
      lastBackup = '${paths.root.path}/current.wbackup';
      if (failSecondary) error = 'النسخة المحلية محفوظة، وتعذر النسخ للمجلد الإضافي';
      return File(lastBackup!);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

class FakeCloseBridge extends DesktopCloseBridge {
  final decisions = <bool>[];
  @override
  Future<void> initialize(Future<void> Function(bool) onRequest) async {}
  @override
  Future<void> finish(bool close) async => decisions.add(close);
  @override
  void dispose() {}
}

void main() {
  late AppDatabase db;
  late Directory temp;
  late FakeBackup backup;
  late MutationState mutations;
  setUp(() {
    temp = Directory.systemTemp.createTempSync('close-backup-test-');
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    backup = FakeBackup(db, LocalPaths(temp));
    mutations = MutationState();
  });
  tearDown(() async {
    backup.dispose();
    mutations.dispose();
    await db.close();
    temp.deleteSync(recursive: true);
  });
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  }
  Future<void> openPrompt(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(body: TextButton(
        onPressed: () => showDialog<bool>(context: context, barrierDismissible: false,
          builder: (_) => CloseBackupDialog(backup: backup, mutations: mutations)),
        child: const Text('خروج')));
    })));
    await tester.tap(find.text('خروج'));
    await settle(tester);
  }
  testWidgets('returning to the app cancels exit without changing backups', (tester) async {
    await openPrompt(tester);
    await tester.tap(find.text('رجوع للبرنامج'));
    await settle(tester);
    expect(find.text('قبل إغلاق البرنامج'), findsNothing);
    expect(backup.calls, 0);
  });
  testWidgets('closing without a new backup requires a separate confirmation', (tester) async {
    await openPrompt(tester);
    await tester.tap(find.text('إغلاق بدون نسخة جديدة'));
    await settle(tester);
    expect(find.text('إغلاق بدون نسخة احتياطية جديدة؟'), findsOneWidget);
    await tester.tap(find.text('رجوع'));
    await settle(tester);
    expect(find.text('قبل إغلاق البرنامج'), findsOneWidget);
    expect(backup.calls, 0);
  });
  testWidgets('save is single submission and closing waits for backup completion', (tester) async {
    backup.gate = Completer<void>();
    await openPrompt(tester);
    await tester.tap(find.text('نسخ احتياطي الآن'));
    await tester.pump();
    await tester.tap(find.text('نسخ احتياطي الآن'), warnIfMissed: false);
    expect(backup.calls, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    backup.gate!.complete();
    await settle(tester);
    expect(find.text('تم حفظ نسخة محلية وفحص سلامتها.'), findsOneWidget);
    await tester.tap(find.text('إغلاق البرنامج'));
    await settle(tester);
    expect(find.text('قبل إغلاق البرنامج'), findsNothing);
  });
  testWidgets('a folder copy does not claim cloud upload and needs user acknowledgement', (tester) async {
    backup.secondaryFolder = 'Drive folder';
    await openPrompt(tester);
    await tester.tap(find.text('نسخ احتياطي الآن'));
    await settle(tester);
    expect(find.textContaining('لا يستطيع تأكيد الرفع'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await settle(tester);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    await tester.tap(find.text('إغلاق البرنامج'));
    await settle(tester);
    expect(find.text('قبل إغلاق البرنامج'), findsNothing);
  });
  testWidgets('secondary copy failure retains the local result and offers retry', (tester) async {
    backup.secondaryFolder = 'Drive folder';
    backup.failSecondary = true;
    await openPrompt(tester);
    await tester.tap(find.text('نسخ احتياطي الآن'));
    await settle(tester);
    expect(find.textContaining('تعذر النسخ للمجلد'), findsOneWidget);
    expect(find.text('إغلاق البرنامج'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    backup.failSecondary = false;
    await tester.tap(find.text('نسخ احتياطي الآن'));
    await settle(tester);
    expect(backup.calls, 2);
    expect(find.byType(Checkbox), findsOneWidget);
  });
  testWidgets('local backup failure keeps the window open with a visible error', (tester) async {
    backup.lastBackup = 'previous.wbackup';
    backup.failLocal = true;
    await openPrompt(tester);
    await tester.tap(find.text('نسخ احتياطي الآن'));
    await settle(tester);
    expect(find.textContaining('قرص غير متاح'), findsOneWidget);
    expect(backup.lastBackup, 'previous.wbackup');
    expect(find.text('إغلاق البرنامج'), findsNothing);
    expect(find.text('قبل إغلاق البرنامج'), findsOneWidget);
  });
  testWidgets('exit controls wait for a committed repository write', (tester) async {
    mutations.changed(true);
    await openPrompt(tester);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.textContaining('انتظر انتهاء الحفظ'), findsOneWidget);
    mutations.changed(false);
    await settle(tester);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });
  testWidgets('native repeated close requests share one prompt and cancellation resets the bridge', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final bridge = FakeCloseBridge();
    final guard = DesktopCloseGuard(navigatorKey: key, backup: backup, mutations: mutations, bridge: bridge);
    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
    final pending = guard.requestClose(true);
    await settle(tester);
    await guard.requestClose(false);
    expect(find.text('قبل إغلاق البرنامج'), findsOneWidget);
    expect(find.textContaining('ويندوز طلب الإغلاق'), findsOneWidget);
    await tester.tap(find.text('رجوع للبرنامج'));
    await settle(tester);
    await pending;
    expect(bridge.decisions, [false]);
    guard.dispose();
  });
  testWidgets('staged restore may close using its already-created recovery backup', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final bridge = FakeCloseBridge();
    final guard = DesktopCloseGuard(navigatorKey: key, backup: backup, mutations: mutations, bridge: bridge);
    backup.restorePending = true;
    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
    await guard.requestClose(false);
    expect(bridge.decisions, [true]);
    expect(backup.calls, 0);
    expect(find.text('قبل إغلاق البرنامج'), findsNothing);
    guard.dispose();
  });
}
