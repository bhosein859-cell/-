import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database_helper.dart';
import '../services/psp_archive_service.dart';
import '../services/settings_service.dart';

/// دسترسی سراسری به دیتابیس محلی (تک‌نمونه).
final databaseProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

/// سرویس تنظیمات محلی (تم، زبان).
final settingsServiceProvider = Provider<SettingsService>((ref) => SettingsService());

/// سرویس فایل پروژه (.psp) — خروجی/ورودی.
final pspServiceProvider = Provider<PspArchiveService>(
  (ref) => PspArchiveService(database: ref.watch(databaseProvider)),
);
