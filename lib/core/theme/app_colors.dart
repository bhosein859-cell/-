import 'package:flutter/material.dart';

/// پالت رنگ برند «گره‌گشا».
///
/// رنگ‌های اصلی هویت بصری: آبی نفتی (#1E3A8A) و نارنجی (#F97316).
class AppColors {
  AppColors._();

  /// آبی نفتی — رنگ اصلی برند (اعتماد، عمق، تحلیل)
  static const Color navyBlue = Color(0xFF1E3A8A);

  /// آبی نفتی روشن‌تر برای گرادینت‌ها
  static const Color navyBlueLight = Color(0xFF3B5BC0);

  /// نارنجی — رنگ اقدام، تأکید و انرژی
  static const Color orange = Color(0xFFF97316);

  /// سبز موفقیت
  static const Color success = Color(0xFF10B981);

  /// رنگ‌های سطوح سه‌گانه‌ی حل مسئله
  static const Color level1 = Color(0xFF0EA5E9); // سطح ۱ — حل سریع
  static const Color level2 = Color(0xFFF59E0B); // سطح ۲ — متوسط و تیمی
  static const Color level3 = Color(0xFFDC2626); // سطح ۳ — گسترده و استراتژیک

  /// سطح‌های خنثی
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF0B1220);
  static const Color darkCard = Color(0xFF121D33);
}
