import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/splash_screen.dart';

/// ریشه‌ی اپلیکیشن «گره‌گشا».
///
/// زبان پیش‌فرض: فارسی | جهت: راست‌به‌چپ (با تکیه بر [GlobalWidgetsLocalizations]
/// و [locale] کل درخت ویجت به‌صورت خودکار RTL می‌شود).
class GerehGoshaApp extends ConsumerWidget {
  const GerehGoshaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'گره‌گشا',
      debugShowCheckedModeBanner: false,

      // 🔒 زبان و جهت پیش‌فرض — فارسی و راست‌به‌چپ
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,

      home: const SplashScreen(),
    );
  }
}
