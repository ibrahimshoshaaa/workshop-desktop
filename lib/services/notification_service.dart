import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// نفس خدمة الإشعارات المحلية بتاعة نسخة الموبايل بالظبط (نفس الأسماء
/// والتوقيعات)، لكن متظبطة لويندوز بدل أندرويد: تنبيهات التسليمات القريبة
/// والمديونيات. دعم ويندوز في مكتبة flutter_local_notifications أحدث
/// وأقل اختبارًا من دعم أندرويد، فكل دالة هنا (زي الموبايل بالظبط) محمية
/// بـ try/catch عشان أي مشكلة في الإشعارات متأثرش على حفظ طلب أو دفعة.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _debtNotificationId = 999999;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      // appUserModelId و guid لازم يفضلوا ثابتين بين كل نسخة من التطبيق
      // (متغيّرش القيم دي بعد النشر) عشان ويندوز يعرف يربط الإشعارات
      // بنفس التطبيق في كل مرة
      const windowsSettings = WindowsInitializationSettings(
        appName: 'Tahoun Royal Home',
        appUserModelId: 'Com.TahounRoyalHome.Desktop',
        guid: 'a2e397de-905d-4386-b8a2-e8c00aef6bc5',
      );
      const settings = InitializationSettings(windows: windowsSettings);
      await _plugin.initialize(settings);

      _initialized = true;
    } catch (e, st) {
      debugPrint('⚠️ تعذّرت تهيئة الإشعارات: $e');
      debugPrint('$st');
    }
  }

  int _reminderIdFor(String orderId, int offset) =>
      (orderId.hashCode & 0x7FFFFFFF) + offset;

  Future<void> scheduleOrderDeliveryReminders({
    required String orderId,
    required String customerName,
    required String itemType,
    required DateTime deliveryDate,
  }) async {
    try {
      await cancelOrderReminders(orderId);

      final dayBefore = tz.TZDateTime.from(
        DateTime(
            deliveryDate.year, deliveryDate.month, deliveryDate.day - 1, 9, 0),
        tz.local,
      );
      final onDay = tz.TZDateTime.from(
        DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day, 9, 0),
        tz.local,
      );
      final now = tz.TZDateTime.now(tz.local);

      const details = NotificationDetails();

      if (dayBefore.isAfter(now)) {
        await _plugin.zonedSchedule(
          _reminderIdFor(orderId, 1),
          'تسليم غدًا',
          '$customerName - $itemType مطلوب تسليمه غدًا',
          dayBefore,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      if (onDay.isAfter(now)) {
        await _plugin.zonedSchedule(
          _reminderIdFor(orderId, 2),
          'موعد التسليم اليوم',
          '$customerName - $itemType مطلوب تسليمه اليوم',
          onDay,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e, st) {
      debugPrint('⚠️ تعذّرت جدولة تنبيهات التسليم: $e');
      debugPrint('$st');
    }
  }

  Future<void> cancelOrderReminders(String orderId) async {
    try {
      await _plugin.cancel(_reminderIdFor(orderId, 1));
      await _plugin.cancel(_reminderIdFor(orderId, 2));
    } catch (e) {
      debugPrint('⚠️ تعذّر إلغاء تنبيهات الطلب: $e');
    }
  }

  Future<void> scheduleDebtReminder(double totalDebts, int debtorsCount) async {
    try {
      await _plugin.cancel(_debtNotificationId);
      if (totalDebts <= 0) return;

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final scheduledTime = tz.TZDateTime.from(
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
        tz.local,
      );

      const details = NotificationDetails();

      await _plugin.zonedSchedule(
        _debtNotificationId,
        'عندك مديونيات مستحقة',
        'إجمالي ${totalDebts.toStringAsFixed(0)} ج.م من $debtorsCount عميل - راجع صفحة المديونيات',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('⚠️ تعذّرت جدولة تنبيه المديونيات: $e');
    }
  }
}
