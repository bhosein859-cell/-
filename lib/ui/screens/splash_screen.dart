import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../shell/home_shell.dart';

/// صفحه‌ی شروع — نمایش لوگوی «گره‌گشا» و هویت سازنده.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    // بارگذاری تم ذخیره‌شده‌ی کاربر در پس‌زمینه
    Future.microtask(() => ref.read(themeModeProvider.notifier).load());
    _timer = Timer(const Duration(milliseconds: 2800), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navyBlue, Color(0xFF0F1D4D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // لوگو روی زمینه‌ی سفید دایره‌ای
              Container(
                width: 172,
                height: 172,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 118,
                    height: 118,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                AppConstants.tagline,
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const Spacer(flex: 3),
              const Text(
                'ساخته شده توسط ${AppConstants.creator}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نسخه‌ی ${AppConstants.appVersion} • ${AppConstants.phaseName}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 26),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.orange,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
