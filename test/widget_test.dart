import 'package:drift/native.dart';
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
}
