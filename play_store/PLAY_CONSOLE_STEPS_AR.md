# خطوات رفع رقم مباشر على Google Play Console

اسم الحزمة النهائي:
`com.alyafai.raqmmubasher`

## المرحلة 1 — قبل Play Console
1. اسحب آخر تحديث من GitHub.
2. شغّل:
   `generate_upload_key.bat`
3. أكمل:
   `android/key.properties`
4. شغّل:
   `verify_play_ready.bat`
5. إذا نجح الفحص شغّل:
   `build_aab.bat`

ملف الرفع:
`build/app/outputs/bundle/release/app-release.aab`

## المرحلة 2 — إنشاء التطبيق
داخل Play Console:
1. Create app.
2. الاسم: **رقم مباشر**.
3. اللغة الافتراضية: العربية.
4. النوع: App.
5. مجاني أو مدفوع: اختر ما يناسب خطتك، والأفضل حاليًا مجاني بدون إعلانات إذا لم تكن هناك خطة ربح فورية.

## المرحلة 3 — صفحة المتجر
استخدم:
`play_store/STORE_LISTING_AR.md`

وأضف:
- أيقونة 512×512.
- Feature Graphic 1024×500.
- لقطات شاشة حقيقية من التطبيق.
- بريد دعم.
- رابط سياسة خصوصية عام HTTPS.

## المرحلة 4 — App content
استخدم:
`play_store/APP_CONTENT_AR.md`

الحالة الحالية:
- Ads: لا.
- App access: لا يوجد تسجيل دخول.
- لا توجد حسابات مستخدمين.
- التطبيق ليس موجهًا أساسًا للأطفال.
- أكمل IARC بدقة حسب محتوى التطبيق الفعلي.

## المرحلة 5 — Data Safety
راجع:
`play_store/DATA_SAFETY_AR.md`

مهم:
لا ترسل Data Safety النهائي قبل مراجعة سلوك google_fonts في AAB النهائي.

## المرحلة 6 — أول Release
1. اختر مسار الاختبار المطلوب في حسابك.
2. أنشئ Release.
3. ارفع app-release.aab.
4. فعّل Play App Signing عند الطلب.
5. أكمل Release notes.
6. راجع كل التحذيرات قبل الإرسال.

## المرحلة 7 — بعد رفع AAB
اختبر النسخة التي يوزعها Google Play، وليس APK المحلي فقط:
- فتح واتساب العادي.
- فتح واتساب الأعمال.
- الاتصال.
- SMS.
- QR.
- حفظ ومشاركة QR.
- المفضلة.
- الرسائل الجاهزة.
- الاستيراد من قائمة المشاركة.
- الوضع الداكن.
- Tajawal/Cairo/خط الجهاز.
- بطاقة الذكر وإخفاؤها من الإعدادات.

## ملاحظة package name
بعد أول رفع فعلي للحزمة `com.alyafai.raqmmubasher` إلى Play Console، اعتبر الاسم ثابتًا ولا تغيّره.
