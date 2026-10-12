@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ==================================================
echo   Raqm Mubasher - Google Play Preflight Check
echo ==================================================
echo.

set FAIL=0

echo [1/8] Checking Flutter...
where flutter >nul 2>&1
if errorlevel 1 (
  echo FAIL: Flutter was not found in PATH.
  set FAIL=1
) else (
  echo OK
)

echo.
echo [2/8] Checking Java keytool...
set "KEYTOOL_OK="
where keytool >nul 2>&1 && set "KEYTOOL_OK=1"
if not defined KEYTOOL_OK if defined JAVA_HOME if exist "%JAVA_HOME%\bin\keytool.exe" set "KEYTOOL_OK=1"
if not defined KEYTOOL_OK if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" set "KEYTOOL_OK=1"
if not defined KEYTOOL_OK if exist "D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" set "KEYTOOL_OK=1"
if not defined KEYTOOL_OK if exist "C:\Program Files\Java\jdk-17\bin\keytool.exe" set "KEYTOOL_OK=1"
if not defined KEYTOOL_OK if exist "D:\Dev\Java\jdk-17\bin\keytool.exe" set "KEYTOOL_OK=1"

if not defined KEYTOOL_OK (
  echo FAIL: keytool could not be found.
  set FAIL=1
) else (
  echo OK
)

echo.
echo [3/8] Checking final package name...
findstr /C:"applicationId "com.alyafai.raqmmubasher"" android\app\build.gradle >nul
if errorlevel 1 (
  echo FAIL: Final applicationId was not found.
  set FAIL=1
) else (
  echo OK: com.alyafai.raqmmubasher
)

echo.
echo [4/8] Checking API 36...
findstr /C:"compileSdk 36" android\app\build.gradle >nul
if errorlevel 1 (
  echo FAIL: compileSdk 36 not found.
  set FAIL=1
) else (
  findstr /C:"targetSdk 36" android\app\build.gradle >nul
  if errorlevel 1 (
    echo FAIL: targetSdk 36 not found.
    set FAIL=1
  ) else (
    echo OK
  )
)

echo.
echo [5/8] Checking release key properties...
if not exist "android\key.properties" (
  echo FAIL: android\key.properties is missing.
  echo       Run generate_upload_key.bat first.
  set FAIL=1
) else (
  findstr /C:"CHANGE_ME" android\key.properties >nul
  if not errorlevel 1 (
    echo FAIL: android\key.properties still contains CHANGE_ME.
    set FAIL=1
  ) else (
    echo OK
  )
)

echo.
echo [6/8] Checking upload keystore...
if not exist "android\upload-keystore.jks" (
  echo FAIL: android\upload-keystore.jks is missing.
  set FAIL=1
) else (
  echo OK
)

echo.
echo [7/8] Getting Flutter packages...
if %FAIL%==0 (
  call flutter pub get
  if errorlevel 1 (
    echo FAIL: flutter pub get failed.
    set FAIL=1
  ) else (
    echo OK
  )
) else (
  echo SKIPPED until previous checks are fixed.
)

echo.
echo [8/8] Static analysis...
if %FAIL%==0 (
  call flutter analyze --no-fatal-warnings --no-fatal-infos
  if errorlevel 1 (
    echo FAIL: flutter analyze found blocking errors.
    set FAIL=1
  ) else (
    echo OK
  )
) else (
  echo SKIPPED until previous checks are fixed.
)

echo.
echo ==================================================
if %FAIL%==0 (
  echo PLAY PREFLIGHT PASSED
  echo You can now run: build_aab.bat
) else (
  echo PLAY PREFLIGHT FAILED
  echo Fix the FAIL items above, then run this script again.
)
echo ==================================================
pause
exit /b %FAIL%
