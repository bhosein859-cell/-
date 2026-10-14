/// ثابت‌های سراسری اپلیکیشن «گره‌گشا».
///
/// هر متنی که برند، نام سازنده یا شماره نسخه را نشان می‌دهد
/// باید از همین کلاس خوانده شود تا در همه‌جا یکسان باشد.
class AppConstants {
  AppConstants._();

  /// نام فارسی محصول
  static const String appName = 'گره‌گشا';

  /// نام انگلیسی محصول (برای لاگ‌ها و نام فایل‌ها)
  static const String appNameEn = 'Gereh-Gosha';

  /// سازنده و مالک — در صفحه شروع، درباره ما و تمام گزارش‌ها درج می‌شود
  static const String creator = 'حسین بختیاری';

  /// شعار محصول
  static const String tagline = 'از گره تا راه‌حل؛ قدم‌به‌قدم، آفلاین و امن';

  /// نسخه فعلی (فاز صفر: زیرساخت)
  static const String appVersion = '۰٫۱٫۰';
  static const String appVersionEn = '0.1.0';
  static const String phaseName = 'فاز صفر — زیرساخت';

  /// نسخه‌ی اسکیمای دیتابیس (برای مهاجرت‌های آینده)
  static const int schemaVersion = 1;

  /// نسخه‌ی فرمت فایل پروژه (.psp)
  static const int pspFormatVersion = 1;

  /// تعداد کل ویژگی‌های نقشه راه (۳۳ استاندارد جهانی + ۳۳ نوآورانه)
  static const int roadmapTotalFeatures = 66;
}
