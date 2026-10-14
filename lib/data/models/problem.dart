import 'dart:convert';

import 'model_utils.dart';

/// سطوح سه‌گانه‌ی حل مسئله در گره‌گشا.
class ProblemLevel {
  ProblemLevel._();

  static const int quickFix = 1; // حل سریع
  static const int team = 2; // متوسط و تیمی
  static const int strategic = 3; // گسترده و استراتژیک

  static const Map<int, String> faLabels = {
    quickFix: 'حل سریع',
    team: 'متوسط و تیمی',
    strategic: 'گسترده و استراتژیک',
  };
}

/// وضعیت‌های چرخه‌ی عمر مسئله.
class ProblemStatus {
  ProblemStatus._();

  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';

  static const Map<String, String> faLabels = {
    open: 'باز',
    inProgress: 'در حال انجام',
    resolved: 'حل‌شده',
    closed: 'بسته',
  };
}

/// مدل مسئله — هسته‌ی مرکزی داده در گره‌گشا.
class Problem {
  const Problem({
    this.id,
    this.code,
    required this.title,
    this.description,
    required this.level,
    this.status = ProblemStatus.open,
    this.priority = 'medium',
    this.ownerId,
    this.createdBy,
    this.methodology,
    this.dueDate,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  final int? id;
  final String? code;
  final String title;
  final String? description;

  /// ۱ = حل سریع، ۲ = متوسط و تیمی، ۳ = گسترده و استراتژیک
  final int level;
  final String status;
  final String priority;
  final int? ownerId;
  final int? createdBy;

  /// متدولوژی حل (فازهای بعد): PDCA | 8D | DMAIC | ...
  final String? methodology;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  String get levelFa => ProblemLevel.faLabels[level] ?? 'نامشخص';
  String get statusFa => ProblemStatus.faLabels[status] ?? status;

  factory Problem.fromMap(Map<String, dynamic> m) => Problem(
        id: m['id'] as int?,
        code: m['code'] as String?,
        title: m['title'] as String,
        description: m['description'] as String?,
        level: m['level'] as int,
        status: m['status'] as String? ?? ProblemStatus.open,
        priority: m['priority'] as String? ?? 'medium',
        ownerId: m['owner_id'] as int?,
        createdBy: m['created_by'] as int?,
        methodology: m['methodology'] as String?,
        dueDate: parseDbDate(m['due_date']),
        resolvedAt: parseDbDate(m['resolved_at']),
        createdAt: parseDbDate(m['created_at']),
        updatedAt: parseDbDate(m['updated_at']),
        metadata: decodeJsonMap(m['metadata']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'title': title,
        'description': description,
        'level': level,
        'status': status,
        'priority': priority,
        'owner_id': ownerId,
        'created_by': createdBy,
        'methodology': methodology,
        'due_date': dueDate?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'metadata': jsonEncode(metadata),
      };
}
