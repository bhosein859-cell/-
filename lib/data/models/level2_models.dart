/// مدل‌های سبک فاز ۲ که در `metadata` مسئله ذخیره می‌شوند
/// (تیم، شاخص‌ها، درخت ۵ چرا) — انعطاف‌پذیر بدون تغییر اسکیمای جداول.

/// عضو تیم حل مسئله.
class TeamMember {
  const TeamMember({required this.name, required this.role});

  final String name;
  final String role;

  static const Map<String, String> roleFa = {
    'leader': 'رهبر تیم',
    'member': 'عضو',
    'expert': 'کارشناس',
    'observer': 'ناظر',
  };

  Map<String, dynamic> toJson() => {'name': name, 'role': role};

  factory TeamMember.fromJson(Map<String, dynamic> j) =>
      TeamMember(name: j['name'] as String? ?? '', role: j['role'] as String? ?? 'member');
}

/// شاخص کلیدی عملکرد (KPI) با اندازه‌گیری قبل/بعد.
class Kpi {
  const Kpi({
    required this.name,
    this.unit = '',
    this.baseline,
    this.target,
    this.after,
  });

  final String name;
  final String unit;
  final double? baseline; // قبل از اقدام
  final double? target;
  final double? after; // بعد از اقدام

  /// درصد بهبود — مثبت یعنی بهبود
  double? get improvementPercent {
    if (baseline == null || after == null || baseline == 0) return null;
    return (after! - baseline!) / baseline!.abs() * 100;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'baseline': baseline,
        'target': target,
        'after': after,
      };

  factory Kpi.fromJson(Map<String, dynamic> j) => Kpi(
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        baseline: (j['baseline'] as num?)?.toDouble(),
        target: (j['target'] as num?)?.toDouble(),
        after: (j['after'] as num?)?.toDouble(),
      );
}

/// گره درخت ۵ چرا پیشرفته (چندشاخه‌ای).
class WhyTreeNode {
  const WhyTreeNode({
    required this.nodeId,
    required this.text,
    this.parentId,
    this.fishboneNodeId, // اتصال به شاخه‌ی استخوان‌ماهی
  });

  final String nodeId;
  final String text;
  final String? parentId;

  /// این ریشه به کدام شاخه‌ی استخوان‌ماهی متصل است؟
  final int? fishboneNodeId;

  Map<String, dynamic> toJson() => {
        'id': nodeId,
        'text': text,
        'parent_id': parentId,
        'fishbone_node_id': fishboneNodeId,
      };

  factory WhyTreeNode.fromJson(Map<String, dynamic> j) => WhyTreeNode(
        nodeId: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        parentId: j['parent_id'] as String?,
        fishboneNodeId: j['fishbone_node_id'] as int?,
      );
}

/// فرم تعریف مسئله 5W2H.
class Definition5W2H {
  const Definition5W2H({
    this.what = '',
    this.why = '',
    this.where = '',
    this.when = '',
    this.who = '',
    this.how = '',
    this.howMuch = '',
  });

  final String what; // چه چیزی؟
  final String why; // چرا؟
  final String where; // کجا؟
  final String when; // چه زمانی؟
  final String who; // چه کسی؟
  final String how; // چگونه؟
  final String howMuch; // چقدر؟

  Map<String, dynamic> toJson() => {
        'what': what,
        'why': why,
        'where': where,
        'when': when,
        'who': who,
        'how': how,
        'how_much': howMuch,
      };

  factory Definition5W2H.fromJson(Map<String, dynamic> j) => Definition5W2H(
        what: j['what'] as String? ?? '',
        why: j['why'] as String? ?? '',
        where: j['where'] as String? ?? '',
        when: j['when'] as String? ?? '',
        who: j['who'] as String? ?? '',
        how: j['how'] as String? ?? '',
        howMuch: j['how_much'] as String? ?? '',
      );
}
