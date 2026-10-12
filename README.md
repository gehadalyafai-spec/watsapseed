# رقم مباشر

تطبيق Flutter خفيف لأدوات التواصل السريع بدون الحاجة إلى حفظ الرقم في جهات الاتصال أولًا.

## الوظائف الحالية
- فتح واتساب العادي أو واتساب الأعمال.
- اتصال مباشر وSMS.
- دعم دول متعددة والبحث بمفتاح الدولة.
- لصق ذكي واستخراج الرقم من النص.
- استيراد الرقم من قائمة المشاركة وتحديد النص في Android.
- نسخ الرقم الدولي.
- إنشاء ونسخ ومشاركة رابط المحادثة.
- إنشاء QR وحفظه أو مشاركته كصورة.
- رسائل جاهزة مع بحث وترتيب.
- مفضلة بأرقام دولية مع بحث وترتيب.
- نسخة احتياطية محلية للرسائل والمفضلة.
- وضع داكن وخيارات Tajawal وCairo وخط النظام.
- بطاقة ذكر اختيارية في أسفل الصفحة الرئيسية.

## الخصوصية
لا يتطلب التطبيق حسابًا. الرسائل الجاهزة والمفضلة والإعدادات تُحفظ محليًا على الجهاز. راجع:
`play_store/PRIVACY_POLICY_AR.md`

## تشغيل المشروع
```powershell
flutter pub get
flutter run
```

## إنشاء APK للتجربة
```powershell
build_apk.bat
```

## إنشاء AAB لـ Google Play
قبل ذلك يجب إعداد Upload Key وملف:
`android/key.properties`

استخدم القالب:
`android/key.properties.example`

ثم شغّل:
```powershell
build_aab.bat
```

ملف AAB الناتج:
```text
build\app\outputs\bundle\release\app-release.aab
```

## مهم قبل أول نشر
- المشروع يستهدف Android 16 / API 36.
- اسم الحزمة الحالي `com.example.watsapseed` مؤقت ويجب تغييره قبل أول رفع إلى Google Play.
- لا ترفع ملف `android/key.properties` أو ملفات keystore إلى GitHub.
- راجع قائمة النشر في:
  `play_store/RELEASE_CHECKLIST_AR.md`
