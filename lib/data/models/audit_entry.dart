import 'model_utils.dart';

/// مدل رویداد تاریخچه‌ی تغییرات (صرفاً خواندنی؛ مستقیم درج می‌شود).
class AuditEntry {
  const AuditEntry({
    this.id,
    this.problemId,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.details,
    this.createdAt,
  });

  final int? id;
  final int? problemId;
  final int? userId;

  /// نوع رویداد: create | update | delete | export_psp | import_psp | ...
  final String action;
  final String? entityType;
  final int? entityId;

  /// جزئیات رویداد به‌صورت متن (معمولاً JSON)
  final String? details;
  final DateTime? createdAt;

  factory AuditEntry.fromMap(Map<String, dynamic> m) => AuditEntry(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int?,
        userId: m['user_id'] as int?,
        action: m['action'] as String,
        entityType: m['entity_type'] as String?,
        entityId: m['entity_id'] as int?,
        details: m['details'] as String?,
        createdAt: parseDbDate(m['created_at']),
      );
}
