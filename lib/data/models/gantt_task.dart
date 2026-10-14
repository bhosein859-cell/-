import 'model_utils.dart';

/// وضعیت‌های گانت چارت.
class GanttStatus {
  GanttStatus._();

  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String done = 'done';
  static const String canceled = 'canceled';

  static const Map<String, String> faLabels = {
    notStarted: 'شروع نشده',
    inProgress: 'در حال انجام',
    done: 'انجام شده',
    canceled: 'لغو شده',
  };
}

/// یک نوار گانت چارت (زمان‌بندی اقدام).
class GanttTask {
  const GanttTask({
    this.id,
    required this.problemId,
    this.actionId,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.dependsOn,
    this.progress = 0,
    this.status = GanttStatus.notStarted,
    this.metadata = const {},
  });

  final int? id;
  final int problemId;

  /// اتصال اختیاری به جدول Actions (جدول 5W2H)
  final int? actionId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// وابستگی بهTask قبلی
  final int? dependsOn;
  final int progress;
  final String status;
  final Map<String, dynamic> metadata;

  factory GanttTask.fromMap(Map<String, dynamic> m) => GanttTask(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        actionId: m['action_id'] as int?,
        title: m['title'] as String,
        startDate: parseDbDate(m['start_date']) ?? DateTime.now(),
        endDate: parseDbDate(m['end_date']) ?? DateTime.now(),
        dependsOn: m['depends_on'] as int?,
        progress: m['progress'] as int? ?? 0,
        status: m['status'] as String? ?? GanttStatus.notStarted,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'action_id': actionId,
        'title': title,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'depends_on': dependsOn,
        'progress': progress,
        'status': status,
      };

  GanttTask copyWith({int? progress, String? status}) => GanttTask(
        id: id,
        problemId: problemId,
        actionId: actionId,
        title: title,
        startDate: startDate,
        endDate: endDate,
        dependsOn: dependsOn,
        progress: progress ?? this.progress,
        status: status ?? this.status,
      );
}
