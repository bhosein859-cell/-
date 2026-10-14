# 🚀 برنامه انتشار گره‌گشا — نسخه ۱٫۰٫۰

سازنده: **حسین بختیاری** | پلتفرم‌ها: ویندوز (.exe/.msix) و اندروید (.apk)

## ۱. ساخت فایل‌های نصبی

### ویندوز

```bash
# روش اول: بسته‌ی ام‌اس‌آی‌اکس (توصیه‌شده؛ امضا و تنظیمات در pubspec است)
flutter pub get
dart run msix:create --release
# خروجی: build/windows/x64/runner/Release/gereh_gosha.msix

# روش دوم: نصب‌کننده‌ی سنتی .exe با اینو ستاپ
flutter build windows --release
# سپس کامپایل اسکریپت زیر با Inno Setup:
```

اسکریپت اینو ستاپ (`installer.iss`):

```
[Setup]
AppName=گره‌گشا
AppVersion=1.0.0
AppPublisher=Hossein Bakhtiari
AppPublisherURL=https://gerehgosha.ir
DefaultDirName={autopf}\GerehGosha
DefaultGroupName=گره‌گشا
OutputBaseFilename=GerehGosha-Setup-1.0.0
SetupIconFile=assets\images\logo.ico
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern rtl

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
Source: "assets\images\logo.png"; DestDir: "{app}"

[Icons]
Name: "{group}\گره‌گشا"; Filename: "{app}\gereh_gosha.exe"

[Run]
Filename: "{app}\gereh_gosha.exe"; Description: "اجرای گره‌گشا"; Flags: nowait postinstall
```

### اندروید

```bash
flutter build apk --release \
  --split-per-abi \
  --split-debug-info=build/debug-info \
  --obfuscate
# خروجی: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## ۲. امضای دیجیتال

### اندروید (یک‌بار ساخت کی‌استور)

```bash
keytool -genkey -v -keystore gerehgosha-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias gerehgosha
```

در `android/key.properties`:

```
storePassword=<رمز>
keyPassword=<رمز>
keyAlias=gerehgosha
storeFile=<مسیر>/gerehgosha-release.jks
```

قطعه‌ی امضای `android/app/build.gradle` (پوشه‌های پلتفرمی با `flutter create .` ساخته می‌شوند):

```gradle
def keystoreProperties = new Properties()
def keystoreFile = rootProject.file('key.properties')
if (keystoreFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystoreFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### ویندوز

- برای توزیع بدون هشدار اسمارت‌اسکرین: گواهی کد‌ساین از مرجع معتبر تهیه و روی `.msix`/`.exe` اعمال شود:
  `signtool sign /fd SHA256 /a GerehGosha-Setup-1.0.0.exe`

## ۳. کانال‌های انتشار

| کانال | اقدام |
|-------|-------|
| وب‌سایت رسمی | آپلود نسخه ویندوز + اندروید با لینک مستقیم و هش شِی-۲۵۶ |
| کافه‌بازار | ثبت اپ با شرح فارسی، اسکرین‌شات و دسته «بهره‌وری» |
| مایکت | مشابه بازار؛ همان فایل ای‌پی‌کی امضاشده |
| لینکدین/اینستاگرام | معرفی با ویدیوی ۶۰ ثانیه‌ای از سه سطح ویزارد |

## ۴. صفحه فرود

یک صفحه تک‌فایلی (اچ‌تی‌ام‌ال) با همان سبک گزارش تعاملی پروژه:
لوگو، شعار «هر گره، راهی دارد»، سه سطح محصول، لینک دانلود و نام سازنده.

## ۵. پشتیبانی پس از انتشار

- دکمه «ارسال بازخورد» در صفحه درباره‌ی ما (نوشتن در پوشه محلی و ایمیل)
- نسخه‌بندی معنایی: هر ماه یک مینور؛ اصلاح فوری پچ
- پاسخ به تیکت‌ها حداکثر تا ۴۸ ساعت کاری

## ۶. معیارهای آمادگی انتشار

- [ ] قبول کامل چک‌لیست ۶۶ ویژگی (`docs/QA_CHECKLIST.md`)
- [ ] صفر باگ بحرانی/بالا
- [ ] تست نصب تمیز روی ویندوز خام و گوشی خام
- [ ] بررسی حجم: ای‌پی‌کی < ۶۰ مگابایت، نصبی ویندوز < ۱۰۰ مگابایت
