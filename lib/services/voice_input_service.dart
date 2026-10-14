import 'package:speech_to_text/speech_to_text.dart';

/// ═══════════════════════════════════════════════════════════════
/// تبدیل گفتار به متن — بدون نیاز به تایپ
/// از موتور گفتار سیستم‌عامل (اندروید/ویندوز) استفاده می‌کند که
/// می‌تواند به حالت آفلاین پیکربندی شود؛ در صورت در دسترس نبودن،
/// پیام راهنما می‌دهد و اپ هرگز متوقف نمی‌شود.
/// ═══════════════════════════════════════════════════════════════
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  /// آماده‌سازی؛ در صورت پشتیبانی نکردن دستگاه `false` برمی‌گرداند
  Future<bool> init() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onStatus: (_) {},
        onError: (_) {},
      );
    } catch (_) {
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  bool get isAvailable => _available;

  /// شروع گوش دادن؛ هر تکه متن که تشخیص داده شد به [onPartial] می‌رسد
  Future<void> listen({
    required void Function(String text) onPartial,
    String locale = 'fa_IR',
  }) async {
    if (!await init()) {
      throw const VoiceUnavailableException(
          'تشخیص گفتار روی این دستگاه در دسترس نیست.');
    }
    await _speech.listen(
      onResult: (r) => onPartial(r.recognizedWords),
      localeId: locale,
      listenMode: ListenMode.dictation,
      partialResults: true,
    );
  }

  bool get isListening => _speech.isListening;

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {}
  }
}

class VoiceUnavailableException implements Exception {
  const VoiceUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
