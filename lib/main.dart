import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

/// نقطه‌ی شروع نرم‌افزار «گره‌گشا» — ساخته شده توسط حسین بختیاری.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بارگذاری داده‌های تقویم و زبان فارسی (تقویم شمسی) برای کتابخانه‌ی intl
  await initializeDateFormatting('fa');

  runApp(const ProviderScope(child: GerehGoshaApp()));
}
