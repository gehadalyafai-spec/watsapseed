@echo off
setlocal
cd /d "%~dp0"

echo ==================================================
echo   Raqm Mubasher - Create Google Play Upload Key
echo ==================================================
echo.

where keytool >nul 2>&1
if errorlevel 1 (
  echo ERROR: keytool was not found.
  echo Make sure JDK 17 is installed and keytool is available in PATH.
  echo.
  pause
  exit /b 1
)

if exist "android\upload-keystore.jks" (
  echo ERROR: android\upload-keystore.jks already exists.
  echo This script will NOT overwrite an existing upload key.
  echo.
  pause
  exit /b 1
)

echo A new keystore will be created here:
echo android\upload-keystore.jks
echo.
echo IMPORTANT:
echo - Choose a strong password you can keep safely.
echo - Keep the same password available when filling android\key.properties.
echo - Do NOT upload the keystore or key.properties to GitHub.
echo.
pause

keytool -genkeypair -v ^
  -keystore "android\upload-keystore.jks" ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias upload

if errorlevel 1 goto :error

if not exist "android\key.properties" (
  copy /Y "android\key.properties.example" "android\key.properties" >nul
)

echo.
echo ==================================================
echo UPLOAD KEY CREATED
echo ==================================================
echo.
echo Next:
echo 1. Open android\key.properties
echo 2. Replace CHANGE_ME with the passwords you just used.
echo 3. Keep:
echo       keyAlias=upload
echo       storeFile=upload-keystore.jks
echo 4. Run build_aab.bat
echo.
echo IMPORTANT: Back up android\upload-keystore.jks safely.
echo.
pause
exit /b 0

:error
echo.
echo ==================================================
echo KEY CREATION FAILED
echo ==================================================
pause
exit /b 1
