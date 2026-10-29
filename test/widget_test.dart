import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:workshop_desktop/core/safe_save_button.dart';
import 'package:workshop_desktop/providers/backup_provider.dart';
import 'package:workshop_desktop/providers/data_providers.dart';
import 'package:workshop_desktop/providers/navigation_provider.dart';
import 'package:workshop_desktop/screens/app_shell.dart';
import 'package:workshop_desktop/services/backup_service.dart';
import 'package:workshop_desktop/services/local_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_desktop/core/theme.dart';
import 'package:workshop_desktop/data/database.dart';
import 'package:workshop_desktop/data/local_repository.dart';
import 'package:workshop_desktop/providers/auth_provider.dart';
import 'package:workshop_desktop/providers/database_provider.dart';
import 'package:workshop_desktop/screens/login_screen.dart';
import 'package:workshop_desktop/services/local_account_service.dart';

void main() {
  testWidgets(
    'local first-run login rejects a short password without altering existing business data',
    (tester) async {
      final db = AppDatabase.withExecutor(NativeDatabase.memory());
      await LocalRepository(
        db,
      ).addCustomer(name: 'بيانات موجودة', phone: '1', address: '');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ownerExistsProvider.overrideWith((ref) async => false),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('إنشاء الحساب المحلي'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'manager');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.ensureVisible(find.text('إنشاء الحساب المحلي'));
      await tester.tap(find.text('إنشاء الحساب المحلي'));
      await tester.pumpAndSettle();
      expect(find.textContaining('8 حروف'), findsOneWidget);
      expect(await LocalAccountService(db).hasOwner(), isFalse);
      expect(
        (await db.select(db.customers).get()).single.name,
        'بيانات موجودة',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    },
  );
  testWidgets(
    'save blocks repeated submissions and releases the UI after completion',
    (tester) async {
      final completion = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeSaveButton(
              onPressed: () async {
                calls++;
                await completion.future;
              },
              child: const Text('حفظ'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('حفظ'));
      await tester.pump();
      await tester.tap(find.text('حفظ'), warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ModalBarrier), findsNothing);
    },
  );
  testWidgets('save errors are visible and the form can be used again', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeSaveButton(
            onPressed: () {
              throw StateError('خطأ اختبار');
            },
            child: const Text('حفظ'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('خطأ اختبار'), findsOneWidget);
    expect(find.byType(ModalBarrier), findsNothing);
  });
  for (final permissions in [
    <String, bool>{},
    {'orders': true},
    {'orders': true, 'customers': true},
  ]) {
    testWidgets(
      'navigation handles ${permissions.length} permitted screens without exposing other screens',
      (tester) async {
        final temp = await Directory.systemTemp.createTemp('navigation-test-');
        final db = AppDatabase.withExecutor(NativeDatabase.memory());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              sessionProvider.overrideWith(
                (ref) async => SessionUser(
                  username: 'worker',
                  isAdmin: false,
                  permissions: permissions,
                ),
              ),
              selectedTabProvider.overrideWith((ref) => AppTab.orders),
              ordersProvider.overrideWith((ref) => Stream.value([])),
              customersProvider.overrideWith((ref) => Stream.value([])),
              backupServiceProvider.overrideWith(
                (ref) => BackupService(db, LocalPaths(temp)),
              ),
            ],
            child: const MaterialApp(home: AppShell()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('الإعدادات'), findsNothing);
        expect(find.text('الرئيسية'), findsNothing);
        if (permissions.isEmpty)
          expect(find.textContaining('لا توجد شاشات مسموحة'), findsOneWidget);
        else
          expect(find.text('الطلبات'), findsWidgets);
        if (permissions.length == 2) {
          expect(
            tester
                .widget<NavigationRail>(find.byType(NavigationRail))
                .selectedIndex,
            1,
          );
          await tester.tap(find.text('العملاء'));
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(AppShell)),
            listen: false,
          );
          expect(container.read(selectedTabProvider), AppTab.customers);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await db.close();
        await temp.delete(recursive: true);
      },
    );
  }
}
