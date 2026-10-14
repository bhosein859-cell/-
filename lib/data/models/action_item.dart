import 'dart:convert';

import 'model_utils.dart';

/// وضعیت‌های یک اقدام.
class ActionStatus {
  ActionStatus._();

  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String done = 'done';
  static const String blocked = 'blocked';

  static const Map<String, String> faLabels = {
    pending: 'در انتظار',
    inProgress: 'در حال انجام',
    done: 'انجام‌شده',
    blocked: 'مسدود',
  };
}

/// مدل اقدام اصلاحی (وابسته به یک مسئله).
class ActionItem {
  const ActionItem({
    this.id,
    required this.problemId,
    required this.title,
    this.description,
    this.phase,
    this.assigneeId,
    this.status = ActionStatus.pending,
    this.progress = 0,
    this.dueDate,
    this.completedAt,
    this.createdAt,
    this.metadata = const {},
  });

  final int? id;
  final int problemId;
  final String title;
  final String? description;

  /// فاز متدولوژی (مثل Plan / Do / Check / Act در PDCA)
  final String? phase;
  final int? assigneeId;
  final String status;
  final int progress;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  String get statusFa => ActionStatus.faLabels[status] ?? status;

  factory ActionItem.fromMap(Map<String, dynamic> m) => ActionItem(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        title: m['title'] as String,
        description: m['description'] as String?,
        phase: m['phase'] as String?,
        assigneeId: m['assignee_id'] as int?,
        status: m['status'] as String? ?? ActionStatus.pending,
        progress: m['progress'] as int? ?? 0,
        dueDate: parseDbDate(m['due_date']),
        completedAt: parseDbDate(m['completed_at']),
        createdAt: parseDbDate(m['created_at']),
        metadata: decodeJsonMap(m['metadata']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'title': title,
        'description': description,
        'phase': phase,
        'assignee_id': assigneeId,
        'status': status,
        'progress': progress,
        'due_date': dueDate?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'metadata': jsonEncode(metadata),
      };
}
