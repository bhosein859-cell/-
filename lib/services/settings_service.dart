import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ذخیره‌ی تنظیمات سبک (حالت نمایش، زبان) به‌صورت کاملاً محلی.
class SettingsService {
  static const String _kThemeMode = 'theme_mode';
  static const String _kLocale = 'locale';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_kThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  /// زبان رابط کاربری (پیش‌فرض همیشگی: فارسی)
  Future<String> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocale) ?? 'fa';
  }

  Future<void> saveLocale(String languageTag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, languageTag);
  }
}
