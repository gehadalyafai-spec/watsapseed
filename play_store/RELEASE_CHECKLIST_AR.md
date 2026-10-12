# قائمة تجهيز رقم مباشر للنشر على Google Play

## الحالة الحالية
- [x] اسم التطبيق داخل Android: رقم مباشر.
- [x] إصدار المستخدم: 1.1.0.
- [x] Android targetSdk: API 36.
- [x] سكربت بناء AAB آمن موجود: build_aab.bat.
- [x] دعم مفتاح Release عبر android/key.properties.
- [x] سياسة خصوصية داخل التطبيق.
- [x] مسودة سياسة خصوصية خارجية.
- [x] مسودة صفحة متجر عربية.
- [x] اعتماد package name النهائي: com.alyafai.raqmmubasher.
- [ ] إنشاء Upload Key حقيقي باستخدام `generate_upload_key.bat`.
- [ ] إنشاء android/key.properties محليًا.
- [ ] نشر سياسة الخصوصية على رابط HTTPS عام.
- [ ] تجهيز أيقونة 512×512 وFeature Graphic 1024×500.
- [ ] أخذ لقطات شاشة حقيقية.
- [ ] إنشاء التطبيق في Play Console.
- [ ] إكمال App content وContent rating.
- [ ] إكمال Data safety بما يطابق التطبيق والسياسة.
- [ ] رفع app-release.aab إلى مسار الاختبار المناسب.
- [ ] اختبار النسخة التي يوقعها Google Play قبل النشر العام.

## متطلبات Google Play الحالية المهمة — أكتوبر 2026
1. التطبيقات الجديدة والتحديثات على الهاتف يجب أن تستهدف Android 16 / API 36 أو أعلى.
2. يجب زيادة versionCode مع كل حزمة جديدة ترفع إلى Play Console.
3. التطبيقات المنشورة تحتاج نموذج Data safety دقيقًا ومتوافقًا مع سياسة الخصوصية.
4. يجب توفير سياسة خصوصية داخل التطبيق وكذلك رابط سياسة خصوصية في Play Console.
5. للتطبيقات الجديدة، Play App Signing هو المسار القياسي، بينما يحتفظ المطور بمفتاح Upload Key لتوقيع الـAAB قبل الرفع.
6. متطلبات Android developer verification تتضمن تسجيل package names على Google Play ابتداءً من 30 سبتمبر 2026؛ Play قد يسجل التطبيقات المؤهلة تلقائيًا، ويجب مراجعة حالة الحساب والحزمة في Play Console.

## قبل اختيار package name
اسم الحزمة النهائي المعتمد:
com.alyafai.raqmmubasher

تم تثبيته في namespace وapplicationId ومسار MainActivity. لا تغيّره بعد أول رفع إلى Google Play.

## طريقة إنشاء AAB بعد إعداد التوقيع
شغل:
build_aab.bat

الملف الناتج:
build\app\outputs\bundle\release\app-release.aab


## إنشاء Upload Key
استخدم:
`generate_upload_key.bat`

ثم راجع:
`play_store/UPLOAD_KEY_GUIDE_AR.md`
