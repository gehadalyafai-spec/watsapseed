# إنشاء Upload Key لتطبيق رقم مباشر

اسم الحزمة النهائي:
`com.alyafai.raqmmubasher`

## الطريقة الأسهل
من مجلد المشروع شغّل:

```powershell
generate_upload_key.bat
```

سيتم إنشاء:

```text
android\upload-keystore.jks
```

ثم سيُنسخ القالب:

```text
android\key.properties.example
```

إلى:

```text
android\key.properties
```

افتح `android/key.properties` واستبدل `CHANGE_ME` بكلمات المرور التي اخترتها أثناء إنشاء المفتاح.

يجب أن يبقى:

```properties
keyAlias=upload
storeFile=upload-keystore.jks
```

## مهم جدًا
- لا ترفع `upload-keystore.jks` إلى GitHub.
- لا ترفع `key.properties` إلى GitHub.
- احتفظ بنسخة احتياطية آمنة من keystore وكلمات المرور.
- مفتاح Upload Key ليس هو Play App Signing key؛ Google Play يدير مفتاح توقيع التطبيق عند تفعيل Play App Signing.
- عند فقدان Upload Key يمكن عادةً طلب إعادة تعيين Upload Key من Play Console، لكن الأفضل الاحتفاظ به جيدًا.

## بعد إعداد المفتاح
شغّل:

```powershell
build_aab.bat
```

المسار الناتج:

```text
build\app\outputs\bundle\release\app-release.aab
```
