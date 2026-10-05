WatsapSeed - Android build fix

This project was adjusted for Flutter 3.47.x on Windows to avoid the AGP 9.1 / Gradle 9.3.1 build problem.

Android build stack used in this copy:
- Android Gradle Plugin: 8.13.2
- Gradle: 8.14.3
- Kotlin Gradle Plugin: 2.3.20
- Java target: 17
- Gradle scripts: Groovy (.gradle), not Kotlin DSL (.gradle.kts)

Build commands:
  flutter clean
  flutter pub get
  flutter build apk --release

Or double-click build_apk.bat from the project folder.

APK output:
  build\app\outputs\flutter-apk\app-release.apk

Notes:
- The release build currently uses the debug signing key so you can create/install the APK immediately.
- Before publishing to Google Play, configure a real release keystore.
- local.properties keeps the original machine paths from the uploaded project.
