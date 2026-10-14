import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/action_item.dart';
import '../../data/models/fishbone_node.dart';
import '../../data/models/gantt_task.dart';
import '../../data/models/level2_models.dart';
import '../../data/models/pareto_entry.dart';
import '../../data/models/problem.dart';
import '../../data/repositories/level2_repository.dart';
import '../../data/repositories/problem_repository.dart';
import '../level1/level1_provider.dart' show problemsVersionProvider;
import 'level2_state.dart';

/// مدیریت حالت ویزارد ۸ مرحله‌ای سطح ۲ با Riverpod.
///
/// اصل «ذخیره‌ی خودکار»: هر متد تغییری، بلافاصله پس از به‌روزرسانی state
/// در دیتابیس/متادیتا persist می‌کند و [Level2State.lastSavedAt] را تازه می‌سازد.
class Level2WizardNotifier extends Notifier<Level2State> {
  @override
  Level2State build() => const Level2State();

  ProblemRepository get _repo => ref.read(problemRepositoryProvider);
  Level2Repository get _l2 => ref.read(level2RepositoryProvider);

  DateTime get _now => DateTime.now();

  void _saved(Level2State s) =>
      state = s.copyWith(lastSavedAt: _now);

  Future<void> _saveMeta(Map<String, dynamic> extra) =>
      _repo.mergeProblemMetadata(state.problemId!, extra);

  // ════════════════ ایجاد / بارگذاری ════════════════

  /// ساخت مسئله‌ی سطح ۲ + شش شاخه‌ی اصلی استخوان‌ماهی
  Future<String?> createProblem(String title) async {
    if (title.trim().isEmpty) return 'عنوان مسئله الزامی است.';
    state = state.copyWith(busy: true);
    try {
      final id = await _repo.insertProblem(Problem(
        title: title.trim(),
        level: 2, // 🔒 سطح ۲
        status: ProblemStatus.open,
        ownerId: 1,
        createdBy: 1,
        metadata: const {
          'def_5w2h': {},
          'team': [],
          'kpis': [],
          'whys_tree': [],
          'sop': {},
        },
      ));
      await _l2.seedFishboneCategories(id);
      ref.read(problemsVersionProvider.notifier).state++;
      await loadProblem(id, title: title.trim());
      return null;
    } catch (e) {
      state = state.copyWith(busy: false);
      return 'خطا در ایجاد مسئله: $e';
    }
  }

  /// بارگذاری کامل یک مسئله‌ی سطح ۲ (برای ادامه‌ی کار)
  Future<void> loadProblem(int id, {String? title}) async {
    final problem = await _repo.getProblem(id);
    if (problem == null) return;

    final meta = problem.metadata;
    state = Level2State(
      problemId: id,
      title: title ?? problem.title,
      def: Definition5W2H.fromJson(
          Map<String, dynamic>.from(meta['def_5w2h'] as Map? ?? const {})),
      team: [
        for (final t in (meta['team'] as List? ?? const []))
          TeamMember.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
      kpis: [
        for (final k in (meta['kpi'] as List? ??
            meta['kpis'] as List? ?? const []))
          Kpi.fromJson(Map<String, dynamic>.from(k as Map)),
      ],
      whysTree: [
        for (final w in (meta['whys_tree'] as List? ?? const []))
          WhyTreeNode.fromJson(Map<String, dynamic>.from(w as Map)),
      ],
      sopText: (meta['sop'] as Map? ?? const {})['text'] as String? ?? '',
      sopAttachmentName:
          (meta['sop'] as Map? ?? const {})['file'] as String?,
      sopReviewDate: (meta['sop'] as Map? ?? const {})['review_at'] != null
          ? DateTime.tryParse((meta['sop'] as Map)['review_at'] as String)
          : null,
      fishbone: await _l2.fishboneNodes(id),
      pareto: computePareto(await _l2.paretoData(id)),
      actions: await _repo.actionsForProblem(id),
      gantt: await _l2.ganttTasks(id),
      lastSavedAt: _now,
    );
  }

  void setStep(int step) => state = state.copyWith(step: step);

  // ════════════════ گام ۱: تعریف 5W2H + تیم + KPI ════════════════

  Future<void> saveDefinition(Definition5W2H def) async {
    _saved(state.copyWith(def: def));
    await _saveMeta({'def_5w2h': def.toJson()});
  }

  Future<void> addTeamMember(TeamMember member) async {
    final team = [...state.team, member];
    _saved(state.copyWith(team: team));
    await _saveMeta({'team': [for (final t in team) t.toJson()]});
  }

  Future<void> removeTeamMember(int index) async {
    final team = [...state.team]..removeAt(index);
    _saved(state.copyWith(team: team));
    await _saveMeta({'team': [for (final t in team) t.toJson()]});
  }

  Future<void> addKpi(Kpi kpi) async {
    final kpis = [...state.kpis, kpi];
    _saved(state.copyWith(kpis: kpis));
    await _saveMeta({'kpis': [for (final k in kpis) k.toJson()]});
  }

  Future<void> updateKpi(int index, Kpi kpi) async {
    final kpis = [...state.kpis]..[index] = kpi;
    _saved(state.copyWith(kpis: kpis));
    await _saveMeta({'kpis': [for (final k in kpis) k.toJson()]});
  }

  Future<void> removeKpi(int index) async {
    final kpis = [...state.kpis]..removeAt(index);
    _saved(state.copyWith(kpis: kpis));
    await _saveMeta({'kpis': [for (final k in kpis) k.toJson()]});
  }

  // ════════════════ گام ۲: استخوان‌ماهی + پارتو ════════════════

  Future<void> reloadFishbone() async =>
      _saved(state.copyWith(fishbone: await _l2.fishboneNodes(state.problemId!)));

  Future<void> addFishboneChild(int parentId, String title) async {
    final parent = state.fishbone.firstWhere((n) => n.id == parentId);
    await _l2.insertFishboneNode(FishboneNode(
      problemId: state.problemId!,
      parentId: parentId,
      title: title,
      level: parent.level + 1,
      sortOrder: state.fishbone
          .where((n) => n.parentId == parentId)
          .length,
    ));
    await reloadFishbone();
  }

  Future<void> renameFishbone(int id, String title) async {
    await _l2.updateFishboneNode(id, {'title': title});
    await reloadFishbone();
  }

  Future<void> toggleRootCause(int id) async {
    final node = state.fishbone.firstWhere((n) => n.id == id);
    await _l2.updateFishboneNode(id, {'is_root_cause': node.isRootCause ? 0 : 1});
    await reloadFishbone();
  }

  Future<void> deleteFishbone(int id) async {
    await _l2.deleteFishboneNode(id);
    await reloadFishbone();
  }

  /// جابه‌جایی (Drag & Drop) یک زیرشاخه به ترتیب جدید
  Future<void> reorderFishboneChild(int nodeId, int newOrder) async {
    final siblings = state.fishbone
        .where((n) =>
            n.parentId == state.fishbone.firstWhere((x) => x.id == nodeId).parentId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final moving = siblings.firstWhere((n) => n.id == nodeId);
    siblings.remove(moving);
    siblings.insert(newOrder.clamp(0, siblings.length), moving);
    for (var i = 0; i < siblings.length; i++) {
      await _l2.updateFishboneNode(siblings[i].id!, {'sort_order': i});
    }
    await reloadFishbone();
  }

  /// ذخیره‌ی داده‌های پارتو با محاسبه‌ی خودکار درصد تجمعی
  Future<void> savePareto(List<ParetoEntry> entries) async {
    final computed = computePareto(entries);
    _saved(state.copyWith(pareto: computed));
    await _l2.replacePareto(state.problemId!, computed);
  }

  // ════════════════ گام ۳: درخت ۵ چرا ════════════════

  Future<void> addWhyNode(String text, String? parentId, int? fishboneNodeId) async {
    final node = WhyTreeNode(
      nodeId: 'w${_now.millisecondsSinceEpoch}',
      text: text,
      parentId: parentId,
      fishboneNodeId: fishboneNodeId,
    );
    final tree = [...state.whysTree, node];
    _saved(state.copyWith(whysTree: tree));
    await _saveMeta({'whys_tree': [for (final w in tree) w.toJson()]});
  }

  Future<void> deleteWhySubtree(String nodeId) async {
    final toDelete = <String>{nodeId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final n in state.whysTree) {
        if (n.parentId != null &&
            toDelete.contains(n.parentId) &&
            !toDelete.contains(n.nodeId)) {
          toDelete.add(n.nodeId);
          grew = true;
        }
      }
    }
    final tree = state.whysTree.where((n) => !toDelete.contains(n.nodeId)).toList();
    _saved(state.copyWith(whysTree: tree));
    await _saveMeta({'whys_tree': [for (final w in tree) w.toJson()]});
  }

  // ════════════════ گام ۴: برنامه‌ریزی 5W2H + گانت ════════════════

  Future<void> addAction(Map<String, dynamic> w2h) async {
    final id = await _repo.insertAction(ActionItem(
      problemId: state.problemId!,
      title: w2h['what'] as String? ?? '',
      phase: 'L2',
      status: ActionStatus.pending,
      metadata: w2h,
    ));
    _saved(state.copyWith(actions: await _repo.actionsForProblem(state.problemId!)));
    // نوار گانت هم‌زمان ساخته می‌شود
    if (w2h['start'] != null && w2h['end'] != null) {
      await addGantt(GanttTask(
        problemId: state.problemId!,
        actionId: id,
        title: w2h['what'] as String? ?? '',
        startDate: DateTime.parse(w2h['start'] as String),
        endDate: DateTime.parse(w2h['end'] as String),
      ));
    }
  }

  Future<void> updateActionMeta(int actionId, Map<String, dynamic> w2h) async {
    await _repo.updateAction(actionId, {
      'title': w2h['what'] as String? ?? '',
      'metadata': jsonEncode(w2h),
    });
    _saved(state.copyWith(actions: await _repo.actionsForProblem(state.problemId!)));
  }

  Future<void> deleteAction(int actionId) async {
    await _repo.updateAction(actionId, {'status': ActionStatus.blocked});
    _saved(state.copyWith(actions: await _repo.actionsForProblem(state.problemId!)));
  }

  Future<void> addGantt(GanttTask task) async {
    await _l2.insertGanttTask(task);
    _saved(state.copyWith(gantt: await _l2.ganttTasks(state.problemId!)));
  }

  Future<void> updateGantt(int id, Map<String, Object?> values) async {
    await _l2.updateGanttTask(id, values);
    _saved(state.copyWith(gantt: await _l2.ganttTasks(state.problemId!)));
  }

  Future<void> deleteGantt(int id) async {
    await _l2.deleteGanttTask(id);
    _saved(state.copyWith(gantt: await _l2.ganttTasks(state.problemId!)));
  }

  // ════════════════ گام ۵: اجرا ════════════════

  /// ثبت درصد تکمیل اقدام + همگام‌سازی گانت
  Future<void> setActionProgress(int actionId, int progress) async {
    final status = progress >= 100
        ? ActionStatus.done
        : progress > 0
            ? ActionStatus.inProgress
            : ActionStatus.pending;
    await _repo.updateAction(actionId, {'progress': progress, 'status': status});
    final g = state.gantt.where((t) => t.actionId == actionId).toList();
    for (final t in g) {
      await _l2.updateGanttTask(t.id!, {'progress': progress, 'status': status});
    }
    _saved(state.copyWith(
      actions: await _repo.actionsForProblem(state.problemId!),
      gantt: await _l2.ganttTasks(state.problemId!),
    ));
  }

  /// ثبت مانع + راه‌حل موقت در متادیتای اقدام
  Future<void> addObstacle(int actionId, String obstacle, String workaround) async {
    final action = state.actions.firstWhere((a) => a.id == actionId);
    final meta = Map<String, dynamic>.from(action.metadata);
    final obstacles = List<Map<String, dynamic>>.from(
        (meta['obstacles'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
    obstacles.add({
      'text': obstacle,
      'workaround': workaround,
      'at': _now.toIso8601String(),
    });
    meta['obstacles'] = obstacles;
    await _repo.updateAction(actionId, {'metadata': jsonEncode(meta)});
    _saved(state.copyWith(actions: await _repo.actionsForProblem(state.problemId!)));
  }

  // ════════════════ گام ۶: بررسی (مقادیر «بعد») ════════════════

  Future<void> setKpiAfter(int index, double? after) async {
    final kpis = [...state.kpis];
    final k = kpis[index];
    kpis[index] = Kpi(
        name: k.name, unit: k.unit, baseline: k.baseline, target: k.target, after: after);
    _saved(state.copyWith(kpis: kpis));
    await _saveMeta({'kpis': [for (final x in kpis) x.toJson()]});
  }

  // ════════════════ گام ۷: استانداردسازی ════════════════

  Future<void> saveSop({String? text, String? attachmentName, DateTime? reviewDate}) async {
    final sop = {
      'text': text ?? state.sopText,
      'file': attachmentName ?? state.sopAttachmentName,
      'review_at': (reviewDate ?? state.sopReviewDate)?.toIso8601String(),
    };
    _saved(state.copyWith(
      sopText: text ?? state.sopText,
      sopAttachmentName: attachmentName ?? state.sopAttachmentName,
      sopReviewDate: reviewDate ?? state.sopReviewDate,
    ));
    await _saveMeta({'sop': sop});
  }

  // ════════════════ بستن مسئله ════════════════

  Future<void> closeProblem() async {
    await _repo.updateProblem(state.problemId!, {
      'status': ProblemStatus.closed,
      'resolved_at': _now.toIso8601String(),
    });
    ref.read(problemsVersionProvider.notifier).state++;
    _saved(state);
  }
}

final level2WizardProvider =
    NotifierProvider<Level2WizardNotifier, Level2State>(Level2WizardNotifier.new);
