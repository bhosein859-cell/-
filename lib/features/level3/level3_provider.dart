import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/fishbone_node.dart';
import '../../data/models/level2_models.dart';
import '../../data/models/level3_models.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/level2_repository.dart';
import '../../data/repositories/level3_repository.dart';
import '../../data/repositories/problem_repository.dart';
import '../level1/level1_provider.dart' show problemsVersionProvider;
import 'level3_state.dart';

/// مدیریت حالت ویزارد ۱۲ گامه‌ی سطح ۳ — با ذخیره‌ی خودکار در هر تغییر.
class Level3WizardNotifier extends Notifier<Level3State> {
  @override
  Level3State build() => const Level3State();

  ProblemRepository get _repo => ref.read(problemRepositoryProvider);
  Level2Repository get _l2 => ref.read(level2RepositoryProvider);
  Level3Repository get _l3 => ref.read(level3RepositoryProvider);

  void _saved(Level3State s) =>
      state = s.copyWith(lastSavedAt: DateTime.now());

  Future<void> _meta(Map<String, dynamic> extra) =>
      _repo.mergeProblemMetadata(state.problemId!, extra);

  // ════════════════ ایجاد / بارگذاری ════════════════

  Future<String?> createProblem(String title, Methodology methodology) async {
    if (title.trim().isEmpty) return 'عنوان پروژه الزامی است.';
    state = state.copyWith(busy: true);
    try {
      final id = await _repo.insertProblem(Problem(
        title: title.trim(),
        level: 3, // 🔒 سطح ۳
        status: ProblemStatus.open,
        priority: 'high',
        methodology: methodology.label,
        ownerId: 1,
        createdBy: 1,
        metadata: const {
          'def_5w2h': {}, 'kpis': [], 'containment': [],
          'kt': {}, 'ideas': [], 'risks': [], 'trainings': [],
          'resources': [], 'updated_docs': [], 'sop': {},
          'approvals': {}, 'criticality': 3,
        },
      ));
      await _l2.seedFishboneCategories(id);
      ref.read(problemsVersionProvider.notifier).state++;
      await loadProblem(id, title: title.trim(), methodology: methodology);
      return null;
    } catch (e) {
      state = state.copyWith(busy: false);
      return 'خطا در ایجاد پروژه: $e';
    }
  }

  Future<void> loadProblem(int id,
      {String? title, Methodology? methodology}) async {
    final problem = await _repo.getProblem(id);
    if (problem == null) return;
    final m = problem.metadata;
    final stats = await _l3.stats(id);

    state = Level3State(
      problemId: id,
      title: title ?? problem.title,
      methodology: methodology ??
          Methodology.values.firstWhere(
              (x) => x.label == (problem.methodology ?? '8D'),
              orElse: () => Methodology.d8),
      def: Definition5W2H.fromJson(
          Map<String, dynamic>.from(m['def_5w2h'] as Map? ?? const {})),
      criticality: m['criticality'] as int? ?? 3,
      kpis: [
        for (final k in (m['kpis'] as List? ?? const []))
          Kpi.fromJson(Map<String, dynamic>.from(k as Map)),
      ],
      containment: [
        for (final c in (m['containment'] as List? ?? const []))
          ContainmentAction.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
      containmentApproved: m['containment_approved'] as bool? ?? false,
      stats: stats,
      usl: (m['usl'] as num?)?.toDouble() ?? 0,
      lsl: (m['lsl'] as num?)?.toDouble() ?? 0,
      fishbone: await _l2.fishboneNodes(id),
      whysTree: [
        for (final w in (m['whys_tree'] as List? ?? const []))
          WhyTreeNode.fromJson(Map<String, dynamic>.from(w as Map)),
      ],
      kt: KtAnalysis.fromJson(
          Map<String, dynamic>.from(m['kt'] as Map? ?? const {})),
      ideas: List<String>.from((m['ideas'] as List? ?? const [])
          .map((e) => e.toString())),
      pughSolutions: List<String>.from((m['pugh_solutions'] as List? ?? const [])
          .map((e) => e.toString())),
      pughWeights: Map<String, int>.from(
          (m['pugh_weights'] as Map? ?? const {'cost': 5, 'time': 5, 'effectiveness': 8, 'risk': 7})
              .map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
      pughCells: await _l3.pugh(id),
      risks: List<Map<String, dynamic>>.from((m['risks'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))),
      pilots: await _l3.pilots(id),
      copq: await _l3.copq(id),
      investment: (m['investment'] as num?)?.toDouble() ?? 0,
      trainings: List<Map<String, dynamic>>.from((m['trainings'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))),
      resources: List<Map<String, dynamic>>.from((m['resources'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))),
      sopText: (m['sop'] as Map? ?? const {})['text'] as String? ?? '',
      sopReviewDate: (m['sop'] as Map? ?? const {})['review_at'] != null
          ? DateTime.tryParse((m['sop'] as Map)['review_at'] as String)
          : null,
      updatedDocs: List<String>.from((m['updated_docs'] as List? ?? const [])
          .map((e) => e.toString())),
      lessons: await _l3.lessons(id),
      team: await _l3.team(id),
      fmea: await _l3.fmea(id),
      managerApproval: (m['approvals'] as Map? ?? const {})['manager'] as bool? ?? false,
      financeApproval: (m['approvals'] as Map? ?? const {})['finance'] as bool? ?? false,
      sponsorApproval: (m['approvals'] as Map? ?? const {})['sponsor'] as bool? ?? false,
      teamScore: m['team_score'] as int? ?? 0,
      lastSavedAt: DateTime.now(),
    );
  }

  void setStep(int step) => state = state.copyWith(step: step);

  // ════════ گام ۱ ════════

  Future<void> saveBasics(
      {Definition5W2H? def, int? criticality, String? priority}) async {
    _saved(state.copyWith(
        def: def, criticality: criticality, priority: priority));
    await _meta({
      if (def != null) 'def_5w2h': def.toJson(),
      if (criticality != null) 'criticality': criticality,
    });
  }

  Future<void> addTeamMemberL3(TeamMemberL3 m) async {
    await _l3.addTeamMember(m);
    _saved(state.copyWith(team: await _l3.team(state.problemId!)));
  }

  Future<void> removeTeamMemberL3(int id) async {
    await _l3.removeTeamMember(id);
    _saved(state.copyWith(team: await _l3.team(state.problemId!)));
  }

  Future<void> addKpiL3(Kpi k) async {
    final kpis = [...state.kpis, k];
    _saved(state.copyWith(kpis: kpis));
    await _meta({'kpis': [for (final k in kpis) k.toJson()]});
  }

  // ════════ گام ۲: Containment ════════

  Future<void> addContainment(ContainmentAction c) async {
    final list = [...state.containment, c];
    _saved(state.copyWith(containment: list));
    await _meta({'containment': [for (final x in list) x.toJson()]});
  }

  Future<void> approveContainment(String approvedBy) async {
    _saved(state.copyWith(containmentApproved: true));
    await _meta({
      'containment_approved': true,
      'containment_approver': approvedBy,
    });
  }

  // ════════ گام ۳: آمار ════════

  Future<void> saveStat(String type, List<double> values,
      [List<double> values2 = const []]) async {
    await _l3.saveStat(state.problemId!, type, values, values2);
    _saved(state.copyWith(stats: await _l3.stats(state.problemId!)));
  }

  Future<void> saveLimits(double lsl, double usl) async {
    _saved(state.copyWith(lsl: lsl, usl: usl));
    await _meta({'lsl': lsl, 'usl': usl});
  }

  // ════════ گام ۴: FMEA ════════

  Future<void> addFmea(FmeaItem f) async {
    await _l3.insertFmea(f);
    _saved(state.copyWith(fmea: await _l3.fmea(state.problemId!)));
  }

  Future<void> updateFmea(int id, Map<String, Object?> v) async {
    await _l3.updateFmea(id, v);
    _saved(state.copyWith(fmea: await _l3.fmea(state.problemId!)));
  }

  Future<void> deleteFmea(int id) async {
    await _l3.deleteFmea(id);
    _saved(state.copyWith(fmea: await _l3.fmea(state.problemId!)));
  }

  /// پیشنهاد خودکار اقدام اصلاحی برای RPN بالا
  String proposeAction(FmeaItem f) =>
      'بازنگری کنترل «${f.control.isEmpty ? '—' : f.control}» برای علت '
      '«${f.cause}» + افزودن بازرسی صددرصد موقت (RPN=${f.rpn})';

  // ════════ گام ۵: RCA جامع ════════

  Future<void> reloadFishbone() async =>
      _saved(state.copyWith(fishbone: await _l2.fishboneNodes(state.problemId!)));

  Future<void> addFishboneChildL3(int parentId, String title) async {
    final parent = state.fishbone.firstWhere((n) => n.id == parentId);
    await _l2.insertFishboneNode(FishboneNode(
        problemId: state.problemId!,
        parentId: parentId,
        title: title,
        level: parent.level + 1));
    await reloadFishbone();
  }

  Future<void> addWhyNodeL3(String text, String? parentId, int? fishId) async {
    final tree = [
      ...state.whysTree,
      WhyTreeNode(
          nodeId: 'w${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          parentId: parentId,
          fishboneNodeId: fishId),
    ];
    _saved(state.copyWith(whysTree: tree));
    await _meta({'whys_tree': [for (final w in tree) w.toJson()]});
  }

  Future<void> saveKt(KtAnalysis kt) async {
    _saved(state.copyWith(kt: kt));
    await _meta({'kt': kt.toJson()});
  }

  // ════════ گام ۶: راه‌حل و Pugh ════════

  Future<void> addIdea(String idea) async {
    final ideas = [...state.ideas, idea];
    _saved(state.copyWith(ideas: ideas));
    await _meta({'ideas': ideas});
  }

  Future<void> promoteIdeasToPugh() async {
    _saved(state.copyWith(pughSolutions: [...state.ideas]));
    await _meta({'pugh_solutions': state.ideas});
  }

  Future<void> setPughWeight(String criterion, int weight) async {
    final weights = {...state.pughWeights, criterion: weight};
    _saved(state.copyWith(pughWeights: weights));
    await _meta({'pugh_weights': weights});
  }

  Future<void> setPughScore(String solution, String criterion, int score) async {
    final cells = [...state.pughCells]
      ..removeWhere((c) => c.solution == solution && c.criterion == criterion);
    cells.add(PughCell(
        problemId: state.problemId!,
        solution: solution,
        criterion: criterion,
        score: score,
        weight: state.pughWeights[criterion] ?? 5));
    await _l3.replacePugh(state.problemId!, cells);
    _saved(state.copyWith(pughCells: cells));
  }

  Future<void> addRisk(Map<String, dynamic> risk) async {
    final risks = [...state.risks, risk];
    _saved(state.copyWith(risks: risks));
    await _meta({'risks': risks});
  }

  // ════════ گام ۷: Pilot ════════

  Future<void> addPilot(PilotResult p) async {
    await _l3.addPilot(p);
    _saved(state.copyWith(pilots: await _l3.pilots(state.problemId!)));
  }

  // ════════ گام ۸: COPQ ════════

  Future<void> saveCopq(List<CopqRow> rows, {double? investment}) async {
    await _l3.replaceCopq(state.problemId!, rows);
    _saved(state.copyWith(copq: rows, investment: investment));
    if (investment != null) await _meta({'investment': investment});
  }

  Future<void> setFinanceApproval(bool v) async {
    _saved(state.copyWith(financeApproval: v));
    await _meta({
      'approvals': {
        'manager': state.managerApproval,
        'finance': v,
        'sponsor': state.sponsorApproval,
      }
    });
  }

  // ════════ گام ۹ ════════

  Future<void> addTraining(Map<String, dynamic> t) async {
    final list = [...state.trainings, t];
    _saved(state.copyWith(trainings: list));
    await _meta({'trainings': list});
  }

  Future<void> addResource(Map<String, dynamic> r) async {
    final list = [...state.resources, r];
    _saved(state.copyWith(resources: list));
    await _meta({'resources': list});
  }

  // ════════ گام ۱۰ ════════

  Future<void> saveSopL3({String? text, DateTime? reviewDate, String? doc}) async {
    final docs = doc == null ? state.updatedDocs : [...state.updatedDocs, doc];
    _saved(state.copyWith(
        sopText: text, sopReviewDate: reviewDate, updatedDocs: docs));
    await _meta({
      'sop': {
        'text': text ?? state.sopText,
        'review_at': (reviewDate ?? state.sopReviewDate)?.toIso8601String(),
      },
      'updated_docs': docs,
    });
  }

  /// تولید خودکار پیش‌نویس SOP از راه‌حل برتر و ریشه‌ها
  String autoSopDraft() {
    final best = state.bestPughSolution ?? 'راه‌حل منتخب';
    final roots = state.fmea.where((f) => f.isCritical).map((f) => f.cause).toList();
    return 'دستورالعمل استاندارد — ${state.title}\n'
        '۱) راه‌حل مصوب: $best\n'
        '۲) پایش علل بحرانی: ${roots.isEmpty ? '—' : roots.join('، ')}\n'
        '۳) پایش دوره‌ای شاخص‌ها و ثبت روندها\n'
        '۴) گزارش هر انحراف به ${state.team.where((t) => t.role == 'leader').map((t) => t.name).firstOrNullSafe() ?? 'رهبر تیم'}';
  }

  // ════════ گام ۱۱ ════════

  Future<void> addLesson(LessonLearned l) async {
    await _l3.addLesson(l);
    _saved(state.copyWith(lessons: await _l3.lessons(state.problemId!)));
  }

  // ════════ گام ۱۲: بستن + گیمیفیکیشن ════════

  Future<void> setSponsorApproval(bool v) async {
    _saved(state.copyWith(sponsorApproval: v));
    await _meta({
      'approvals': {
        'manager': state.managerApproval,
        'finance': state.financeApproval,
        'sponsor': v,
      }
    });
  }

  /// محاسبه‌ی امتیاز تیم (گیمیفیکیشن) و بستن رسمی پروژه +
  /// تبدیل خودکار به بانک دانش.
  Future<void> closeProject() async {
    final score = 50 +
        state.lessons.length * 5 +
        state.fmea.where((f) => f.proposedAction != null).length * 10 +
        (state.roi > 0 ? 20 : 0) +
        (state.containmentApproved ? 10 : 0);
    _saved(state.copyWith(teamScore: score));
    await _meta({'team_score': score});

    // تبدیل به بانک دانش
    await _repo.insertKnowledgeFromProject(
      problemId: state.problemId!,
      title: state.title,
      summary: 'پروژه‌ی سطح ۳ (${state.methodology.label}) — صرفه‌جویی: '
          '${state.savings.toStringAsFixed(0)} | ROI: ${state.roi.toStringAsFixed(0)}٪',
      tags: ['سطح۳', state.methodology.label,
        for (final l in state.lessons) l.category,
      ],
    );

    await _repo.updateProblem(state.problemId!, {
      'status': ProblemStatus.closed,
      'resolved_at': DateTime.now().toIso8601String(),
    });
    ref.read(problemsVersionProvider.notifier).state++;
    _saved(state);
  }
}

/// الحاق ایمن برای لیست خالی
extension _SafeFirst<T> on Iterable<T> {
  T? firstOrNullSafe() => isEmpty ? null : first;
}

final level3WizardProvider =
    NotifierProvider<Level3WizardNotifier, Level3State>(Level3WizardNotifier.new);
