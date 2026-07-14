import 'package:flutter_riverpod/flutter_riverpod.dart';

/// يتحكم في التاب المختار حاليًا في NavigationRail بتاع AppShell.
/// بنستخدمه عشان أي صفحة تقدر "تنقل" لصفحة تانية عن طريق تغيير التاب
/// (بدل استخدام Navigator.push اللي بيفتح صفحة فوق الحالية).
///
/// ترتيب الفهارس مطابق لترتيب _destinations / _screens في app_shell.dart:
/// 0: الرئيسية, 1: العملاء, 2: الطلبات, 3: المديونيات, 4: المصروفات,
/// 5: المخزون, 6: التقارير
final selectedTabProvider = StateProvider<int>((ref) => 0);
