@echo off
setlocal
cd /d "%~dp0"
echo ==================================================
echo   WhatsApp Fast - Clean Release APK Build
echo ==================================================
echo.

echo [1/5] Stopping any Gradle daemon...
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop >nul 2>&1
  popd
)

echo [2/5] Removing project build caches...
if exist "build" rmdir /s /q "build"
if exist "android\.gradle" rmdir /s /q "android\.gradle"
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo [3/5] Flutter clean...
call flutter clean
if errorlevel 1 goto :error

echo [4/5] Getting packages...
call flutter pub get
if errorlevel 1 goto :error

echo [5/5] Building release APK...
call flutter build apk --release --android-skip-build-dependency-validation
if errorlevel 1 goto :error

echo.
echo ==================================================
echo BUILD SUCCESSFUL
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo ==================================================
pause
exit /b 0

:error
echo.
echo ==================================================
echo BUILD FAILED - copy the FIRST error shown above.
echo ==================================================
pause
exit /b 1
