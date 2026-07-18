import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_EG', null);
  runApp(const ProviderScope(child: WorkshopDesktopApp()));
}

class WorkshopDesktopApp extends ConsumerStatefulWidget {
  const WorkshopDesktopApp({super.key});
  @override
  ConsumerState<WorkshopDesktopApp> createState() => _WorkshopDesktopAppState();
}

class _WorkshopDesktopAppState extends ConsumerState<WorkshopDesktopApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startPeriodicSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tahoun Royal Home - سطح المكتب',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const _AuthGate(),
    );
  }
}

/// بيعرض شاشة الدخول لو مفيش جلسة محفوظة، أو الشاشة الأساسية لو فيه
/// مستخدم مسجّل دخول بالفعل (من مرة سابقة أو دلوقتي)
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);

    return sessionAsync.when(
      data: (session) => session == null ? const LoginScreen() : const AppShell(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(),
    );
  }
}
