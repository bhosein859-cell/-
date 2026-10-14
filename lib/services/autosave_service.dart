import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════
/// ذخیره‌ی خودکار و بازیابی پس از کرش
/// آخرین وضعیت جلسه (پروژه باز، گام فعلی، متن‌های در حال تایپ)
/// هر چند ثانیه در SharedPreferences نوشته می‌شود؛ اگر برنامه
/// ناگهانی بسته شود، در شروع بعدی خودکار پیشنهاد بازیابی می‌دهد.
/// ═══════════════════════════════════════════════════════════════
class AutosaveService {
  static const String _sessionKey = 'gg_session_snapshot';
  static const String _cleanExitKey = 'gg_clean_exit';

  /// ذخیره‌ی وضعیت جلسه
  static Future<void> snapshot({
    required String screen,
    int? problemId,
    int step = 0,
    Map<String, String> drafts = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'screen': screen,
        'problem_id': problemId,
        'step': step,
        'drafts': drafts,
        'at': DateTime.now().toIso8601String(),
      }),
    );
    await prefs.setBool(_cleanExitKey, false);
  }

  /// هنگام خروج عادی صدا زده می‌شود
  static Future<void> markCleanExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleanExitKey, true);
  }

  /// آیا اجرای قبلی با کرش/قطع ناگهانی تمام شده؟
  static Future<RecoveryInfo?> detectCrash() async {
    final prefs = await SharedPreferences.getInstance();
    final clean = prefs.getBool(_cleanExitKey) ?? true;
    final raw = prefs.getString(_sessionKey);
    if (clean || raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return RecoveryInfo(
        screen: j['screen'] as String? ?? '',
        problemId: j['problem_id'] as int?,
        step: j['step'] as int? ?? 0,
        drafts: Map<String, String>.from(j['drafts'] as Map? ?? const {}),
        at: DateTime.tryParse(j['at'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// پاک‌سازی پس از بازیابی موفق
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.setBool(_cleanExitKey, true);
  }
}

class RecoveryInfo {
  const RecoveryInfo({
    required this.screen,
    required this.problemId,
    required this.step,
    required this.drafts,
    required this.at,
  });

  final String screen;
  final int? problemId;
  final int step;
  final Map<String, String> drafts;
  final DateTime? at;
}

final autosaveProvider = Provider<AutosaveService>((_) => AutosaveService());
