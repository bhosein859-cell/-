import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';

/// مدیریت حالت نمایش (روشن/تیره/سیستم) با ذخیره‌ی محلی.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final SettingsService _settings = SettingsService();

  @override
  ThemeMode build() => ThemeMode.system;

  /// بارگذاری حالت ذخیره‌شده — هنگام شروع اپ فراخوانی می‌شود.
  Future<void> load() async {
    state = await _settings.loadThemeMode();
  }

  /// تغییر حالت نمایش و ذخیره‌ی آن.
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _settings.saveThemeMode(mode);
  }

  /// جابه‌جایی سریع بین روشن و تیره.
  Future<void> toggleDarkMode() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

/// ارائه‌دهنده‌ی سراسری حالت نمایش
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
