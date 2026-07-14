/// رابط قاعدة بيانات Firebase - نفس المشروع اللي شغال عليه تطبيق الموبايل بالظبط.
/// نقلناه هنا في ملف مستقل (بدل ما يكون جوه sync_provider.dart) عشان auth_provider.dart
/// محتاج يستخدمه برضو من غير ما يعمل استيراد دائري (circular import) مع sync_provider.dart
const String firebaseDatabaseUrl = 'https://workshopmanage-e7555-default-rtdb.firebaseio.com';
