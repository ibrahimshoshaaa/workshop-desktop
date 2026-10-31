import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'providers/backup_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/mutation_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/backup_service.dart';
import 'services/desktop_close_guard.dart';
import 'services/local_paths.dart';
import 'services/notification_service.dart';

// Keep the OS lock alive for the complete process lifetime.
SingleInstanceLock? instanceLock;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final paths = await LocalPaths.load();
    instanceLock = await SingleInstanceLock.acquire(paths);
    await BackupService.applyPendingRestore(paths);
    await paths.prepareLocalDatabase();
    await initializeDateFormatting('ar_EG', null);
    await NotificationService.instance.init();
    runApp(
      ProviderScope(
        overrides: [localPathsProvider.overrideWithValue(paths)],
        child: const WorkshopDesktopApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$e', textDirection: TextDirection.rtl),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkshopDesktopApp extends ConsumerStatefulWidget {
  const WorkshopDesktopApp({super.key});
  @override
  ConsumerState<WorkshopDesktopApp> createState() => _WorkshopDesktopAppState();
}

class _WorkshopDesktopAppState extends ConsumerState<WorkshopDesktopApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final DesktopCloseGuard _closeGuard;
  @override
  void initState() {
    super.initState();
    _closeGuard = DesktopCloseGuard(
      navigatorKey: _navigatorKey,
      backup: ref.read(backupServiceProvider),
      mutations: ref.read(mutationStateProvider),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_closeGuard.start());
      unawaited(ref.read(backupServiceProvider).start());
    });
  }

  @override
  void dispose() {
    _closeGuard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backup = ref.watch(backupServiceProvider);
    final saving = ref.watch(mutationStateProvider).busy;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tahoun Royal Home — محلي',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            AbsorbPointer(absorbing: backup.busy || saving, child: child!),
            if (backup.busy || saving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
      home: backup.restorePending
          ? const Scaffold(
              body: Center(
                child: Text(
                  'تم تجهيز الاسترجاع وحفظ نسخة رجوع.\nاقفل البرنامج وافتحه لإتمام الاسترجاع.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(sessionProvider)
      .when(
        data: (session) =>
            session == null ? const LoginScreen() : const AppShell(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(
          body: Center(
            child: Text('تعذر قراءة الحساب المحلي. راجع النسخة الاحتياطية.'),
          ),
        ),
      );
}
