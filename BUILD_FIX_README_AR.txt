مشروع واتساب سريع - نسخة إصلاح بناء Android

تم تعديل إعدادات Android لتجنب مشكلة البناء التي ظهرت مع Flutter 3.47.x على Windows عند استخدام AGP 9.1.0 وGradle 9.3.1.

إعدادات البناء في هذه النسخة:
- Android Gradle Plugin: 8.13.2
- Gradle: 8.14.3
- Kotlin Gradle Plugin: 2.3.20
- Java target: 17
- ملفات Gradle تم تحويلها إلى Groovy (.gradle) بدل Kotlin DSL (.gradle.kts)

لإنشاء APK:
1) افتح المشروع.
2) شغّل:
   flutter clean
   flutter pub get
   flutter build apk --release

أو انقر مرتين على الملف:
   build_apk.bat

مكان ملف APK بعد النجاح:
   build\app\outputs\flutter-apk\app-release.apk

ملاحظات:
- نسخة release تستخدم توقيع debug مؤقتاً لتسهيل إنشاء APK وتثبيته مباشرة.
- قبل النشر في Google Play يجب إعداد release keystore حقيقي.
- ملف local.properties بقي كما كان في المشروع المرفوع لأنه يحتوي مسارات Flutter وAndroid SDK على جهازك.
