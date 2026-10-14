#!/usr/bin/env bash
# ساخت فایل نصبی گره‌گشا با یک کلیک — حسین بختیاری
set -e
cd "$(dirname "$0")"

echo "============================================"
echo "  ساخت فایل نصبی گره‌گشا — حسین بختیاری"
echo "============================================"

# ۱. بررسی فلاتر
if ! command -v flutter >/dev/null; then
  echo "[خطا] فلاتر نصب نیست: https://docs.flutter.dev/get-started/install"
  exit 1
fi

# ۲. ساخت اسکلت اندروید (فقط بار اول)
if [ ! -d android ]; then
  echo "[۱/۵] ساخت اسکلت اندروید..."
  flutter create --platforms=android --org ir.bakhtiari --project-name gereh_gosha .
fi

# ۳. نام فارسی اپ + مجوز میکروفون
echo "[۲/۵] تنظیم مانیفست اندروید..."
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i 's/android:label="gereh_gosha"/android:label="گره‌گشا"/' "$MANIFEST"
if ! grep -q "RECORD_AUDIO" "$MANIFEST"; then
  sed -i 's|<application|<uses-permission android:name="android.permission.RECORD_AUDIO"/>\n    <application|' "$MANIFEST"
fi

# ۴. وابستگی‌ها و آیکون
echo "[۳/۵] دریافت وابستگی‌ها..."
flutter pub get
echo "[۴/۵] ساخت آیکون اپ..."
dart run flutter_launcher_icons

# ۵. ساخت نسخه‌ی انتشار
echo "[۵/۵] ساخت فایل نصبی..."
flutter build apk --release

mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/GerehGosha-1.0.0.apk

echo
echo "============================================"
echo "  فایل نصبی آماده شد:"
echo "  dist/GerehGosha-1.0.0.apk"
echo "============================================"
