@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ==================================================
echo   Raqm Mubasher - Create Google Play Upload Key
echo ==================================================
echo.

set "KEYTOOL="

rem 1) keytool already in PATH
for /f "delims=" %%I in ('where keytool 2^>nul') do (
  if not defined KEYTOOL set "KEYTOOL=%%I"
)

rem 2) JAVA_HOME
if not defined KEYTOOL if defined JAVA_HOME (
  if exist "%JAVA_HOME%\bin\keytool.exe" (
    set "KEYTOOL=%JAVA_HOME%\bin\keytool.exe"
  )
)

rem 3) Android Studio bundled JDK - common locations
if not defined KEYTOOL if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
  set "KEYTOOL=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
)

if not defined KEYTOOL if exist "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe" (
  set "KEYTOOL=C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
)

if not defined KEYTOOL if exist "D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
  set "KEYTOOL=D:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
)

if not defined KEYTOOL if exist "D:\Android\Android Studio\jbr\bin\keytool.exe" (
  set "KEYTOOL=D:\Android\Android Studio\jbr\bin\keytool.exe"
)

rem 4) Common JDK 17 locations
if not defined KEYTOOL if exist "C:\Program Files\Java\jdk-17\bin\keytool.exe" (
  set "KEYTOOL=C:\Program Files\Java\jdk-17\bin\keytool.exe"
)

if not defined KEYTOOL if exist "D:\Dev\Java\jdk-17\bin\keytool.exe" (
  set "KEYTOOL=D:\Dev\Java\jdk-17\bin\keytool.exe"
)

if not defined KEYTOOL (
  echo ERROR: keytool could not be found automatically.
  echo.
  echo Run this command in PowerShell and send me the result:
  echo flutter doctor -v
  echo.
  pause
  exit /b 1
)

echo Found keytool:
echo %KEYTOOL%
echo.

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
echo - Choose a strong password and keep it safely.
echo - You will type the password directly into keytool.
echo - Do NOT send the password to anyone.
echo - Do NOT upload the keystore or key.properties to GitHub.
echo.
pause

"%KEYTOOL%" -genkeypair -v ^
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
echo 4. Do NOT commit key.properties or the keystore.
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
