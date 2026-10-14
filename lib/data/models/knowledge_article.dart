import 'dart:convert';

import 'model_utils.dart';

/// مدل مقاله‌ی بانک دانش — آرشیو راه‌حل‌های مسائل حل‌شده.
class KnowledgeArticle {
  const KnowledgeArticle({
    this.id,
    this.problemId,
    required this.title,
    this.summary,
    this.solution,
    this.tags = const [],
    this.category,
    this.authorId,
    this.createdAt,
    this.metadata = const {},
  });

  final int? id;

  /// مسئله‌ی مبدأ (اختیاری؛ مقالات می‌توانند مستقل هم باشند)
  final int? problemId;
  final String title;

  /// خلاصه‌ی راه‌حل
  final String? summary;

  /// شرح کامل راه‌حل
  final String? solution;
  final List<String> tags;
  final String? category;
  final int? authorId;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  factory KnowledgeArticle.fromMap(Map<String, dynamic> m) => KnowledgeArticle(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int?,
        title: m['title'] as String,
        summary: m['summary'] as String?,
        solution: m['solution'] as String?,
        tags: decodeJsonList(m['tags']),
        category: m['category'] as String?,
        authorId: m['author_id'] as int?,
        createdAt: parseDbDate(m['created_at']),
        metadata: decodeJsonMap(m['metadata']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'title': title,
        'summary': summary,
        'solution': solution,
        'tags': jsonEncode(tags),
        'category': category,
        'author_id': authorId,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'metadata': jsonEncode(metadata),
      };
}
