import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart';
import 'providers/sync_provider.dart';

void main() {
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
    // ابدأ مزامنة دورية أول ما التطبيق يفتح (فورية الأول، وبعدين كل دقيقتين)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startPeriodicSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ورشة التنجيد والأثاث - سطح المكتب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8B5E34),
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const _DbCheckHome(),
    );
  }
}

/// شاشة تجريبية مؤقتة للتأكد إن قاعدة البيانات والمزامنة شغالين، هتتستبدل
/// بالداشبورد الحقيقي في مرحلة الواجهات الجاية
class _DbCheckHome extends ConsumerWidget {
  const _DbCheckHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chair_alt_rounded, size: 64, color: Color(0xFF8B5E34)),
            const SizedBox(height: 16),
            const Text('ورشة التنجيد والأثاث', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: db.watchCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('جاري فتح قاعدة البيانات...', style: TextStyle(color: Colors.grey));
                }
                return Text(
                  'عدد العملاء محليًا: ${snapshot.data?.length ?? 0}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 24),
            _SyncButton(),
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    await ref.read(syncServiceProvider).syncAll();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المزامنة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSyncing ? null : _sync,
      icon: _isSyncing
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync_rounded),
      label: const Text('مزامنة الآن'),
    );
  }
}
