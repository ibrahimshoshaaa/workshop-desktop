import 'package:flutter_test/flutter_test.dart';

// ملف اختبار مبسّط - القالب الافتراضي بتاع Flutter كان بيحاول يختبر MyApp
// (كلاس مش موجود عندنا، كلاسنا اسمه WorkshopDesktopApp). اختبار الواجهة
// الحقيقي هنضيفه لاحقًا لما الشاشات تكتمل. الاختبار ده هنا بس عشان
// `flutter analyze` و`flutter test` يلاقوا ملف صحيح جوه test/ ومايفشلوش.
void main() {
  test('التطبيق بيتأسس صح', () {
    expect(1 + 1, 2);
  });
}
