import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  // لازم نضمن تهيئة الـ binding قبل أي await قبل runApp
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة بيانات تنسيق التاريخ لللغة العربية (مصر) - من غيرها أي
  // DateFormat بيحدد locale صراحةً زي DateFormat('yyyy-MM-dd', 'ar_EG')
  // بيرمي LocaleDataException وبيوقف رندر الشاشة كلها (شاشة رمادية فاضية)
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
      title: 'ورشة التنجيد والأثاث - سطح المكتب',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const _AuthGate(),
    );
  }
}

/// بيقرر يعرض إيه أول ما التطبيق يفتح: لو الحماية بكلمة مرور مفعّلة
/// ومفيش تسجيل دخول لسه في الجلسة دي، يعرض شاشة الدخول، وإلا يروح
/// على الشاشة الأساسية على طول
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authSettingsProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return authAsync.when(
      data: (settings) {
        if (settings.enabled && !isLoggedIn) return const LoginScreen();
        return const AppShell();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const AppShell(),
    );
  }
}
