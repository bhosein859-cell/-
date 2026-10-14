import '../../data/models/fishbone_node.dart';
import '../../data/models/level2_models.dart';
import '../../data/models/level3_models.dart';

/// اقدام مهار (Containment) — گام ۲
class ContainmentAction {
  const ContainmentAction({
    required this.title,
    this.start,
    this.end,
    this.approved = false,
    this.approvedBy,
  });

  final String title;
  final DateTime? start;
  final DateTime? end;
  final bool approved; // تایید اثربخشی توسط مدیر
  final String? approvedBy;

  Map<String, dynamic> toJson() => {
        'title': title,
        'start': start?.toIso8601String(),
        'end': end?.toIso8601String(),
        'approved': approved,
        'approved_by': approvedBy,
      };

  factory ContainmentAction.fromJson(Map<String, dynamic> j) => ContainmentAction(
        title: j['title'] as String? ?? '',
        start: DateTime.tryParse(j['start'] as String? ?? ''),
        end: DateTime.tryParse(j['end'] as String? ?? ''),
        approved: j['approved'] as bool? ?? false,
        approvedBy: j['approved_by'] as String?,
      );
}

/// وضعیت سراسری ویزارد ۱۲ گامه‌ی سطح ۳.
class Level3State {
  const Level3State({
    this.step = 0,
    this.problemId,
    this.title = '',
    this.methodology = Methodology.d8,
    this.def = const Definition5W2H(),
    this.criticality = 3,
    this.priority = 'high',
    this.team = const [],
    this.kpis = const [],
    this.containment = const [],
    this.containmentApproved = false,
    this.stats = const {},
    this.usl = 0,
    this.lsl = 0,
    this.fmea = const [],
    this.fishbone = const [],
    this.whysTree = const [],
    this.kt = const KtAnalysis(),
    this.ideas = const [],
    this.pughSolutions = const [],
    this.pughWeights = const {
      'cost': 5, 'time': 5, 'effectiveness': 8, 'risk': 7,
    },
    this.pughCells = const [],
    this.risks = const [],
    this.pilots = const [],
    this.copq = const [],
    this.investment = 0,
    this.trainings = const [],
    this.resources = const [],
    this.sopText = '',
    this.sopReviewDate,
    this.updatedDocs = const [],
    this.lessons = const [],
    this.managerApproval = false,
    this.financeApproval = false,
    this.sponsorApproval = false,
    this.teamScore = 0,
    this.lastSavedAt,
    this.busy = false,
  });

  final int step; // 0..11
  final int? problemId;
  final String title;
  final Methodology methodology;

  // گام ۱
  final Definition5W2H def;
  final int criticality; // ۱ تا ۵
  final String priority;
  final List<TeamMemberL3> team;
  final List<Kpi> kpis;

  // گام ۲
  final List<ContainmentAction> containment;
  final bool containmentApproved;

  // گام ۳
  final Map<String, StatisticalData> stats;
  final double usl, lsl;

  // گام ۴
  final List<FmeaItem> fmea;

  // گام ۵
  final List<FishboneNode> fishbone;
  final List<WhyTreeNode> whysTree;
  final KtAnalysis kt;

  // گام ۶
  final List<String> ideas;
  final List<String> pughSolutions;
  final Map<String, int> pughWeights;
  final List<PughCell> pughCells;
  final List<Map<String, dynamic>> risks;

  // گام ۷
  final List<PilotResult> pilots;

  // گام ۸
  final List<CopqRow> copq;
  final double investment;
  final bool financeApproval;

  // گام ۹
  final List<Map<String, dynamic>> trainings;
  final List<Map<String, dynamic>> resources;

  // گام ۱۰
  final String sopText;
  final DateTime? sopReviewDate;
  final List<String> updatedDocs;

  // گام ۱۱
  final List<LessonLearned> lessons;

  // گام ۱۲
  final bool managerApproval;
  final bool sponsorApproval;
  final int teamScore;

  final DateTime? lastSavedAt;
  final bool busy;

  Level3State copyWith({
    int? step, int? problemId, String? title, Methodology? methodology,
    Definition5W2H? def, int? criticality, String? priority,
    List<TeamMemberL3>? team, List<Kpi>? kpis,
    List<ContainmentAction>? containment, bool? containmentApproved,
    Map<String, StatisticalData>? stats, double? usl, double? lsl,
    List<FmeaItem>? fmea, List<FishboneNode>? fishbone, List<WhyTreeNode>? whysTree,
    KtAnalysis? kt, List<String>? ideas, List<String>? pughSolutions,
    Map<String, int>? pughWeights, List<PughCell>? pughCells,
    List<Map<String, dynamic>>? risks, List<PilotResult>? pilots,
    List<CopqRow>? copq, double? investment,
    List<Map<String, dynamic>>? trainings, List<Map<String, dynamic>>? resources,
    String? sopText, DateTime? sopReviewDate, List<String>? updatedDocs,
    List<LessonLearned>? lessons,
    bool? managerApproval, bool? financeApproval, bool? sponsorApproval,
    int? teamScore, DateTime? lastSavedAt, bool? busy,
  }) =>
      Level3State(
        step: step ?? this.step,
        problemId: problemId ?? this.problemId,
        title: title ?? this.title,
        methodology: methodology ?? this.methodology,
        def: def ?? this.def,
        criticality: criticality ?? this.criticality,
        priority: priority ?? this.priority,
        team: team ?? this.team,
        kpis: kpis ?? this.kpis,
        containment: containment ?? this.containment,
        containmentApproved: containmentApproved ?? this.containmentApproved,
        stats: stats ?? this.stats,
        usl: usl ?? this.usl,
        lsl: lsl ?? this.lsl,
        fmea: fmea ?? this.fmea,
        fishbone: fishbone ?? this.fishbone,
        whysTree: whysTree ?? this.whysTree,
        kt: kt ?? this.kt,
        ideas: ideas ?? this.ideas,
        pughSolutions: pughSolutions ?? this.pughSolutions,
        pughWeights: pughWeights ?? this.pughWeights,
        pughCells: pughCells ?? this.pughCells,
        risks: risks ?? this.risks,
        pilots: pilots ?? this.pilots,
        copq: copq ?? this.copq,
        investment: investment ?? this.investment,
        trainings: trainings ?? this.trainings,
        resources: resources ?? this.resources,
        sopText: sopText ?? this.sopText,
        sopReviewDate: sopReviewDate ?? this.sopReviewDate,
        updatedDocs: updatedDocs ?? this.updatedDocs,
        lessons: lessons ?? this.lessons,
        managerApproval: managerApproval ?? this.managerApproval,
        financeApproval: financeApproval ?? this.financeApproval,
        sponsorApproval: sponsorApproval ?? this.sponsorApproval,
        teamScore: teamScore ?? this.teamScore,
        lastSavedAt: lastSavedAt ?? this.lastSavedAt,
        busy: busy ?? this.busy,
      );

  // ── محاسبات خودکار ──

  /// امتیاز وزنی هر راه‌حل در ماتریس Pugh = Σ (امتیاز × وزن معیار)
  Map<String, int> pughTotals() {
    final totals = <String, int>{for (final s in pughSolutions) s: 0};
    for (final c in pughCells) {
      totals[c.solution] =
          (totals[c.solution] ?? 0) + c.score * (pughWeights[c.criterion] ?? 5);
    }
    return totals;
  }

  String? get bestPughSolution {
    final totals = pughTotals();
    if (totals.isEmpty) return null;
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double get copqBefore =>
      copq.fold(0, (s, r) => s + r.before);
  double get copqAfter => copq.fold(0, (s, r) => s + r.after);
  double get savings => copqBefore - copqAfter;
  double get roi => investment <= 0 ? 0 : savings / investment * 100;
}
