import 'package:image_picker/image_picker.dart';

/// وضعیت سراسری ویزارد سطح ۱ (حل سریع).
///
/// اصل «سادگی مطلق»: تنها حداقل داده‌های لازم برای ۴ مرحله نگه داشته می‌شود.
class Level1WizardState {
  Level1WizardState({
    this.step = 0,
    this.title = '',
    this.description = '',
    this.location = '',
    this.priority = 'medium',
    List<XFile>? pendingAttachments,
    List<String>? whys,
    this.actionTitle = '',
    this.actionBy = '',
    DateTime? actionAt,
    this.actionStatus = 'done',
    this.verified = false,
    this.retryNotice,
    this.problemId,
    this.actionId,
    this.busy = false,
  })  : pendingAttachments = pendingAttachments ?? [],
        whys = whys ?? List.filled(5, ''),
        actionAt = actionAt ?? DateTime.now();

  /// شماره‌ی مرحله‌ی جاری: ۰ تا 
  final int step;

  // ── مرحله ۱: ثبت مشکل ──
  final String title;
  final String description;
  final String location; // محل / دپارتمان
  final String priority; // low | medium | high
  final List<XFile> pendingAttachments; // عکس‌های انتخاب‌شده قبل از ذخیره

  // ── مرحله ۲: پنج چرا ──
  final List<String> whys; // همیشه ۵ عضو

  // ── مرحله ۳: اقدام فوری ──
  final String actionTitle; // چه کاری انجام شد؟
  final String actionBy; // چه کسی انجام داد؟
  final DateTime actionAt; // چه زمانی؟
  final String actionStatus; // in_progress | done

  // ── مرحله ۴: بستن و تایید ──
  final bool verified; // آیا مشکل برطرف شد؟

  /// پیام راهنما هنگام بازگشت خودکار به مرحله ۲
  final String? retryNotice;

  /// شناسه‌های رکوردهای ساخته‌شده در دیتابیس
  final int? problemId;
  final int? actionId;

  final bool busy;

  Level1WizardState copyWith({
    int? step,
    String? title,
    String? description,
    String? location,
    String? priority,
    List<XFile>? pendingAttachments,
    List<String>? whys,
    String? actionTitle,
    String? actionBy,
    DateTime? actionAt,
    String? actionStatus,
    bool? verified,
    String? retryNotice,
    bool clearRetryNotice = false,
    int? problemId,
    int? actionId,
    bool? busy,
  }) =>
      Level1WizardState(
        step: step ?? this.step,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        priority: priority ?? this.priority,
        pendingAttachments:
            pendingAttachments ?? List<XFile>.of(this.pendingAttachments),
        whys: whys ?? List<String>.of(this.whys),
        actionTitle: actionTitle ?? this.actionTitle,
        actionBy: actionBy ?? this.actionBy,
        actionAt: actionAt ?? this.actionAt,
        actionStatus: actionStatus ?? this.actionStatus,
        verified: verified ?? this.verified,
        retryNotice: clearRetryNotice ? null : (retryNotice ?? this.retryNotice),
        problemId: problemId ?? this.problemId,
        actionId: actionId ?? this.actionId,
        busy: busy ?? this.busy,
      );
}

/// برچسب‌های فارسی اولویت برای منوی کشویی
class Level1Priorities {
  Level1Priorities._();

  static const Map<String, String> faLabels = {
    'low': 'کم',
    'medium': 'متوسط',
    'high': 'زیاد',
  };
}
