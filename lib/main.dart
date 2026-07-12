import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      home: const _PlaceholderHome(),
    );
  }
}

/// شاشة مؤقتة بس للتأكد إن المشروع بيتبني صح على ويندوز - هتتستبدل
/// بالداشبورد الحقيقي في المرحلة 4
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chair_alt_rounded, size: 64, color: Color(0xFF8B5E34)),
            SizedBox(height: 16),
            Text('ورشة التنجيد والأثاث', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('نسخة سطح المكتب - جاري البناء', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
