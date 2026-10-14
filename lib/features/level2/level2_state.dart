import '../../data/models/action_item.dart';
import '../../data/models/fishbone_node.dart';
import '../../data/models/gantt_task.dart';
import '../../data/models/level2_models.dart';
import '../../data/models/pareto_entry.dart';

/// وضعیت سراسری ویزارد سطح ۲ (۸ گام) — با ذخیره‌ی خودکار در هر گام.
class Level2State {
  const Level2State({
    this.step = 0,
    this.problemId,
    this.title = '',
    this.def = const Definition5W2H(),
    this.team = const [],
    this.kpis = const [],
    this.fishbone = const [],
    this.pareto = const [],
    this.whysTree = const [],
    this.actions = const [],
    this.gantt = const [],
    this.sopText = '',
    this.sopAttachmentName,
    this.sopReviewDate,
    this.lastSavedAt,
    this.busy = false,
  });

  final int step; // 0..7
  final int? problemId;
  final String title;

  // گام ۱
  final Definition5W2H def;
  final List<TeamMember> team;
  final List<Kpi> kpis;

  // گام ۲
  final List<FishboneNode> fishbone;
  final List<ParetoEntry> pareto; // با درصد تجمعی محاسبه‌شده

  // گام ۳
  final List<WhyTreeNode> whysTree;

  // گام ۴ و ۵
  final List<ActionItem> actions; // جدول 5W2H (متادیتای Actions)
  final List<GanttTask> gantt;

  // گام ۷
  final String sopText;
  final String? sopAttachmentName;
  final DateTime? sopReviewDate;

  /// مهر زمان آخرین ذخیره‌ی خودکار
  final DateTime? lastSavedAt;
  final bool busy;

  Level2State copyWith({
    int? step,
    int? problemId,
    String? title,
    Definition5W2H? def,
    List<TeamMember>? team,
    List<Kpi>? kpis,
    List<FishboneNode>? fishbone,
    List<ParetoEntry>? pareto,
    List<WhyTreeNode>? whysTree,
    List<ActionItem>? actions,
    List<GanttTask>? gantt,
    String? sopText,
    String? sopAttachmentName,
    bool clearSopAttachment = false,
    DateTime? sopReviewDate,
    bool clearSopReviewDate = false,
    DateTime? lastSavedAt,
    bool? busy,
  }) =>
      Level2State(
        step: step ?? this.step,
        problemId: problemId ?? this.problemId,
        title: title ?? this.title,
        def: def ?? this.def,
        team: team ?? this.team,
        kpis: kpis ?? this.kpis,
        fishbone: fishbone ?? this.fishbone,
        pareto: pareto ?? this.pareto,
        whysTree: whysTree ?? this.whysTree,
        actions: actions ?? this.actions,
        gantt: gantt ?? this.gantt,
        sopText: sopText ?? this.sopText,
        sopAttachmentName: clearSopAttachment
            ? null
            : (sopAttachmentName ?? this.sopAttachmentName),
        sopReviewDate:
            clearSopReviewDate ? null : (sopReviewDate ?? this.sopReviewDate),
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
        busy: busy ?? this.busy,
      );
}
