# ورشة التنجيد والأثاث - نسخة سطح المكتب (Windows)

تطبيق Flutter لسطح المكتب، متزامن مع نفس بيانات تطبيق الموبايل (Firebase Realtime Database)
عن طريق قاعدة بيانات محلية (SQLite/Drift) ومزامنة دورية عبر REST API.

## الستاك التقني
- Flutter (Windows target)
- Drift (SQLite) - المصدر الأساسي للبيانات محليًا
- Firebase REST API - مزامنة مع نفس بيانات الموبايل
- Riverpod - إدارة الحالة
- PDF/Excel export

## طريقة التشغيل
كل push على main بيشغّل GitHub Actions تلقائيًا، وبيبني ملف .exe جاهز.
تابع من تبويب Actions، ولما يخلص ✅ نزّل الملف من Artifacts، فكّه، وشغّل
`workshop_desktop.exe` جوه المجلد.
