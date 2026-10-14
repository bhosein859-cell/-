import 'model_utils.dart';

/// دسته‌های شش‌گانه‌ی استخوان‌ماهی (6M).
class FishboneCategory {
  FishboneCategory._();

  static const List<Map<String, String>> all = [
    {'key': 'man', 'fa': 'انسان'},
    {'key': 'machine', 'fa': 'ماشین'},
    {'key': 'material', 'fa': 'مواد'},
    {'key': 'method', 'fa': 'روش'},
    {'key': 'environment', 'fa': 'محیط'},
    {'key': 'management', 'fa': 'مدیریت'},
  ];

  static String faOf(String key) =>
      all.firstWhere((c) => c['key'] == key, orElse: () => {'fa': key})['fa']!;
}

/// گره نمودار استخوان‌ماهی (اییشیکاوا).
class FishboneNode {
  const FishboneNode({
    this.id,
    required this.problemId,
    this.parentId,
    required this.title,
    this.category, // فقط برای شاخه‌های ریشه (سطح ۰)
    this.level = 0,
    this.sortOrder = 0,
    this.isRootCause = false,
    this.metadata = const {},
  });

  final int? id;
  final int problemId;
  final int? parentId;
  final String title;
  final String? category;
  final int level;
  final int sortOrder;

  /// علامت‌گذاری به‌عنوان ریشه‌ی اصلی (قابل اتصال به درخت ۵ چرا)
  final bool isRootCause;
  final Map<String, dynamic> metadata;

  bool get isCategory => level == 0;

  factory FishboneNode.fromMap(Map<String, dynamic> m) => FishboneNode(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        parentId: m['parent_id'] as int?,
        title: m['title'] as String,
        category: m['category'] as String?,
        level: m['level'] as int? ?? 0,
        sortOrder: m['sort_order'] as int? ?? 0,
        isRootCause: (m['is_root_cause'] as int?) == 1,
        metadata: const {},
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'parent_id': parentId,
        'title': title,
        'category': category,
        'level': level,
        'sort_order': sortOrder,
        'is_root_cause': isRootCause ? 1 : 0,
      };

  FishboneNode copyWith({
    String? title,
    int? sortOrder,
    bool? isRootCause,
  }) =>
      FishboneNode(
        id: id,
        problemId: problemId,
        parentId: parentId,
        title: title ?? this.title,
        category: category,
        level: level,
        sortOrder: sortOrder ?? this.sortOrder,
        isRootCause: isRootCause ?? this.isRootCause,
        metadata: metadata,
      );
}
