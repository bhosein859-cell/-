/// یک سطر داده‌ی نمودار پارتو (علت + فراوانی).
class ParetoEntry {
  const ParetoEntry({
    this.id,
    required this.problemId,
    required this.cause,
    required this.frequency,
    this.cumulativePercent = 0,
    this.sortOrder = 0,
  });

  final int? id;
  final int problemId;
  final String cause;
  final double frequency;

  /// درصد تجمعی — به‌صورت خودکار محاسبه می‌شود (قانون ۸۰/۲۰)
  final double cumulativePercent;
  final int sortOrder;

  factory ParetoEntry.fromMap(Map<String, dynamic> m) => ParetoEntry(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        cause: m['cause'] as String,
        frequency: (m['frequency'] as num).toDouble(),
        cumulativePercent: (m['cumulative_percent'] as num?)?.toDouble() ?? 0,
        sortOrder: m['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'cause': cause,
        'frequency': frequency,
        'cumulative_percent': cumulativePercent,
        'sort_order': sortOrder,
      };

  ParetoEntry copyWith({double? cumulativePercent, int? sortOrder}) =>
      ParetoEntry(
        id: id,
        problemId: problemId,
        cause: cause,
        frequency: frequency,
        cumulativePercent: cumulativePercent ?? this.cumulativePercent,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// محاسبه‌ی خودکار درصد تجمعی پس از مرتب‌سازی نزولی فراوانی‌ها.
List<ParetoEntry> computePareto(List<ParetoEntry> entries) {
  final sorted = List<ParetoEntry>.of(entries)
    ..sort((a, b) => b.frequency.compareTo(a.frequency));
  final total = sorted.fold<double>(0, (s, e) => s + e.frequency);
  var acc = 0.0;
  return [
    for (var i = 0; i < sorted.length; i++)
      sorted[i].copyWith(
        sortOrder: i,
        cumulativePercent: total <= 0
            ? 0
            : (acc += sorted[i].frequency) / total * 100,
      ),
  ];
}
