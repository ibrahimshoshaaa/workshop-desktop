import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/database_provider.dart';

void main() {
  runApp(const ProviderScope(child: WorkshopDesktopApp()));
}

class WorkshopDesktopApp extends StatelessWidget {
  const WorkshopDesktopApp({super.key});

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

/// شاشة تأكيد مؤقتة - بتتأكد إن قاعدة البيانات المحلية اتفتحت صح، هتتستبدل
/// بالداشبورد الحقيقي في مرحلة الواجهات
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
                  'قاعدة البيانات المحلية جاهزة ✅ (${snapshot.data?.length ?? 0} عميل محليًا)',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
