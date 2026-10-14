import 'package:intl/intl.dart';

/// ابزارهای نمایش اعداد و تاریخ فارسی.
///
/// برای تقویم شمسی کافی است در [main] فراخوانی شود:
/// `await initializeDateFormatting('fa');`
class PersianUtils {
  PersianUtils._();

  static const List<String> _faDigits = [
    '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹',
  ];

  /// تبدیل ارقام لاتین یک رشته به ارقام فارسی (مثلاً برای شمارنده‌ها).
  static String faDigits(String input) => input.splitMapJoin(
        RegExp(r'[0-9]'),
        onMatch: (m) => _faDigits[int.parse(m.group(0)!)],
      );

  /// تاریخ کوتاه شمسی — مانند «۱۴۰۵/۷/۱۵».
  static String faDate(DateTime dateTime) =>
      DateFormat.yMd('fa').format(dateTime);

  /// تاریخ و زمان شمسی — مانند «۱۴۰۵/۷/۱۵ - ۱۴:۳۰».
  static String faDateTime(DateTime dateTime) =>
      DateFormat('y/M/d  H:m', 'fa').format(dateTime);
}
