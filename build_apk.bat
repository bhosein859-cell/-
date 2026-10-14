@echo off
chcp 65001 >nul
title ساخت فایل نصبی گره‌گشا
cd /d %~dp0

echo ============================================
echo   ساخت فایل نصبی گره‌گشا - حسین بختیاری
echo ============================================
echo.

REM ── ۱. بررسی نصب بودن فلاتر ──
where flutter >nul 2>nul
if errorlevel 1 (
  echo [خطا] فلاتر پیدا نشد. ابتدا از آدرس زیر نصب کنید:
  echo        https://docs.flutter.dev/get-started/install/windows
  pause
  exit /b 1
)

REM ── ۲. ساخت پوشه‌های اندروید (فقط بار اول) ──
if not exist android (
  echo [۱/۵] ساخت اسکلت اندروید...
  call flutter create --platforms=android --org ir.bakhtiari --project-name gereh_gosha .
)

REM ── ۳. تنظیم نام فارسی اپ و مجوز میکروفون در مانیفست ──
echo [۲/۵] تنظیم مانیفست اندروید...
powershell -NoProfile -Command ^
  "$f='android\app\src\main\AndroidManifest.xml'; $c=Get-Content $f -Raw -Encoding UTF8;" ^
  "$c=$c -replace 'android:label=\"gereh_gosha\"','android:label=\"گره‌گشا\"';" ^
  "$c=$c -replace 'android:label=\"gereh_gosha\"','android:label=\"گره‌گشا\"';" ^
  "if ($c -notmatch 'RECORD_AUDIO') { $c=$c -replace '<application','<uses-permission android:name=\"android.permission.RECORD_AUDIO\"/>`n    <application' };" ^
  "Set-Content $f -Value $c -Encoding UTF8"

REM ── ۴. دریافت وابستگی‌ها و ساخت آیکون ──
echo [۳/۵] دریافت وابستگی‌ها...
call flutter pub get
echo [۴/۵] ساخت آیکون اپ...
call dart run flutter_launcher_icons

REM ── ۵. ساخت نسخه‌ی انتشار ──
echo [۵/۵] ساخت فایل نصبی... این مرحله چند دقیقه طول می‌کشد
call flutter build apk --release

if errorlevel 1 (
  echo.
  echo [خطا] ساخت ناموفق بود؛ متن خطا را بررسی کنید.
  pause
  exit /b 1
)

mkdir dist 2>nul
copy /y build\app\outputs\flutter-apk\app-release.apk dist\GerehGosha-1.0.0.apk >nul

echo.
echo ============================================
echo   فایل نصبی آماده شد:
echo   dist\GerehGosha-1.0.0.apk
echo ============================================
start dist
pause
