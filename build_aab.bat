@echo off
setlocal
cd /d "%~dp0"

echo ==================================================
echo   Raqm Mubasher - Google Play AAB Build
echo ==================================================
echo.

if not exist "android\key.properties" (
  echo ERROR: android\key.properties was not found.
  echo.
  echo This script intentionally refuses to create a Play Store bundle
  echo with the debug signing key.
  echo.
  echo 1. Create your upload keystore.
  echo 2. Copy android\key.properties.example to android\key.properties.
  echo 3. Fill in the real values locally.
  echo 4. Never commit the keystore or key.properties to GitHub.
  echo.
  pause
  exit /b 1
)

echo [1/5] Stopping Gradle daemon...
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop >nul 2>&1
  popd
)

echo [2/5] Cleaning Flutter project...
call flutter clean
if errorlevel 1 goto :error

echo [3/5] Getting packages...
call flutter pub get
if errorlevel 1 goto :error

echo [4/5] Running analyzer...
call flutter analyze --no-fatal-warnings --no-fatal-infos
if errorlevel 1 goto :error

echo [5/5] Building signed release AAB...
call flutter build appbundle --release --android-skip-build-dependency-validation
if errorlevel 1 goto :error

echo.
echo ==================================================
echo BUILD SUCCESSFUL
echo AAB: build\app\outputs\bundle\release\app-release.aab
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
