import 'model_utils.dart';

/// متدولوژی‌های حل مسئله‌ی سطح ۳
enum Methodology {
  d8('8D', 'هشت discipline حل مسئله‌ی تیمی — شکایات مشتری و حوادث بحرانی'),
  dmaic('DMAIC', 'چرخه‌ی شش سیگما: تعریف، اندازه‌گیری، تحلیل، بهبود، کنترل'),
  a3('A3', 'خلاصه‌ی کل پروژه در یک صفحه — پروژه‌های استراتژیک'),
  kt('KT', 'کپنر-تریگو: تحلیل موقعیت، مسئله، تصمیم و خطر'),
  rca('RCA جامع', 'تحلیل ریشه‌ای عمیق برای حوادث');

  const Methodology(this.label, this.desc);
  final String label;
  final String desc;

  /// برچسب متدولوژی برای هر یک از ۱۲ گام ویزارد (شماره‌ی گام ۱ تا ۱۲)
  String stepTag(int step) {
    final i = step.clamp(1, 12) - 1;
    switch (this) {
      case Methodology.d8:
        return const [
          'D1 تیم', 'D2 شرح مسئله', 'D3 اقدام فوری', 'D4 ریشه‌یابی',
          'D5 راه‌حل', 'D6 اجرا', 'D7 پیشگیری', 'D8 تقدیر',
          'D3', 'D4', 'D6', 'D8',
        ][i];
      case Methodology.dmaic:
        return const [
          'Define', 'Define', 'Measure', 'Analyze', 'Analyze', 'Improve',
          'Improve', 'Measure', 'Improve', 'Control', 'Control', 'Control',
        ][i];
      case Methodology.a3:
        return const [
          'پیش‌زمینه', 'شرایط فعلی', 'هدف', 'تحلیل', 'تحلیل', 'راه‌حل',
          'اجرا', 'اثر', 'اجرا', 'استاندارد', 'بازتاب', 'بستن',
        ][i];
      case Methodology.kt:
        return const [
          'موقعیت', 'موقعیت', 'مسئله', 'مسئله', 'مسئله', 'تصمیم',
          'تصمیم', 'تحلیل', 'اجرا', 'خطر', 'خطر', 'بستن',
        ][i];
      case Methodology.rca:
        return const [
          'تعریف', 'تعریف', 'مهار', 'تحلیل', 'تحلیل', 'اصلاح',
          'اصلاح', 'ارزیابی', 'اجرا', 'پیشگیری', 'یادگیری', 'بستن',
        ][i];
    }
  }
}

/// نقش‌های تیم سطح ۳
class TeamRoleL3 {
  TeamRoleL3._();

  static const Map<String, String> fa = {
    'leader': 'رهبر تیم',
    'technical': 'متخصص فنی',
    'operator': 'اپراتور',
    'customer': 'نماینده مشتری',
    'sponsor': 'مدیر حامی',
    'quality': 'مدیر کیفیت',
  };
}

/// عضو تیم (جدول Team_Members)
class TeamMemberL3 {
  const TeamMemberL3({
    this.id,
    required this.problemId,
    this.userId,
    required this.name,
    required this.role,
    this.joinedAt,
  });

  final int? id;
  final int problemId;
  final int? userId;
  final String name;
  final String role;
  final DateTime? joinedAt;

  String get roleFa => TeamRoleL3.fa[role] ?? role;

  factory TeamMemberL3.fromMap(Map<String, dynamic> m) => TeamMemberL3(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        userId: m['user_id'] as int?,
        name: m['name'] as String,
        role: m['role'] as String,
        joinedAt: parseDbDate(m['joined_at']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'user_id': userId,
        'name': name,
        'role': role,
        'joined_at': (joinedAt ?? DateTime.now()).toIso8601String(),
      };
}

/// سطر جدول FMEA (جدول FMEA_Items) — RPN خودکار = S × O × D
class FmeaItem {
  const FmeaItem({
    this.id,
    required this.problemId,
    required this.itemName,
    required this.failureMode,
    required this.effect,
    required this.severity,
    required this.cause,
    required this.occurrence,
    required this.control,
    required this.detection,
    this.proposedAction,
  });

  final int? id;
  final int problemId;
  final String itemName; // آیتم
  final String failureMode; // حالت خرابی
  final String effect; // اثر خرابی
  final int severity; // شدت S (۱ تا ۱۰)
  final String cause; // علت خرابی
  final int occurrence; // احتمال وقوع O
  final String control; // کنترل فعلی
  final int detection; // قابلیت شناسایی D
  final String? proposedAction;

  int get rpn => severity * occurrence * detection;

  /// آستانه‌ی بحرانی بودن RPN
  bool get isCritical => rpn >= 100;

  factory FmeaItem.fromMap(Map<String, dynamic> m) => FmeaItem(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        itemName: m['item_name'] as String,
        failureMode: m['failure_mode'] as String,
        effect: m['effect'] as String,
        severity: m['s'] as int? ?? 1,
        cause: m['cause'] as String,
        occurrence: m['o'] as int? ?? 1,
        control: m['control'] as String? ?? '',
        detection: m['d'] as int? ?? 1,
        proposedAction: m['proposed_action'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'item_name': itemName,
        'failure_mode': failureMode,
        'effect': effect,
        's': severity,
        'cause': cause,
        'o': occurrence,
        'control': control,
        'd': detection,
        'rpn': rpn,
        'proposed_action': proposedAction,
      };
}

/// داده‌ی آماری (جدول Statistical_Data)
class StatisticalData {
  const StatisticalData({
    this.id,
    required this.problemId,
    required this.chartType, // histogram | control | scatter | box
    required this.values,
    required this.values2, // برای محور Y پراکندگی
  });

  final int? id;
  final int problemId;
  final String chartType;
  final List<double> values;
  final List<double> values2;

  factory StatisticalData.fromMap(Map<String, dynamic> m) => StatisticalData(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        chartType: m['chart_type'] as String,
        values: decodeJsonList(m['data']).map(double.parse).toList(),
        values2: decodeJsonList(m['data2']).map(double.parse).toList(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'chart_type': chartType,
        'data': '[${values.join(',')}]',
        'data2': '[${values2.join(',')}]',
      };
}

/// سطر ماتریس Pugh (جدول Pugh_Matrix): یک امتیاز یک راه‌حل برای یک معیار
class PughCell {
  const PughCell({
    this.id,
    required this.problemId,
    required this.solution,
    required this.criterion,
    required this.score, // ۱ تا ۵
    required this.weight, // ۱ تا ۱۰
  });

  final int? id;
  final int problemId;
  final String solution;
  final String criterion;
  final int score;
  final int weight;

  factory PughCell.fromMap(Map<String, dynamic> m) => PughCell(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        solution: m['solution'] as String,
        criterion: m['criterion'] as String,
        score: m['score'] as int? ?? 3,
        weight: m['weight'] as int? ?? 5,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'solution': solution,
        'criterion': criterion,
        'score': score,
        'weight': weight,
      };
}

/// نتیجه‌ی Pilot (جدول Pilot_Results)
class PilotResult {
  const PilotResult({
    this.id,
    required this.problemId,
    required this.date,
    required this.before,
    required this.after,
    this.statNote,
  });

  final int? id;
  final int problemId;
  final DateTime date;
  final double before;
  final double after;
  final String? statNote;

  factory PilotResult.fromMap(Map<String, dynamic> m) => PilotResult(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        date: parseDbDate(m['date']) ?? DateTime.now(),
        before: (m['before'] as num).toDouble(),
        after: (m['after'] as num).toDouble(),
        statNote: m['stat_note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'date': date.toIso8601String(),
        'before': before,
        'after': after,
        'stat_note': statNote,
      };
}

/// سطر هزینه‌ی کیفیت پایین (جدول COPQ)
class CopqRow {
  const CopqRow({
    this.id,
    required this.problemId,
    required this.category,
    required this.before,
    required this.after,
  });

  final int? id;
  final int problemId;
  final String category; // internal | external | appraisal | prevention
  final double before;
  final double after;

  static const Map<String, String> faCategories = {
    'internal': 'شکست داخلی (ضایعات، دوباره‌کاری)',
    'external': 'شکست خارجی (مرجوعی، گارانتی)',
    'appraisal': 'ارزیابی (بازرسی، آزمون)',
    'prevention': 'پیشگیری (آموزش، پیش‌گیری فنی)',
  };

  double get saving => before - after;

  /// نام فارسی دسته‌ی COPQ
  String get faCategory => faCategories[category] ?? category;

  factory CopqRow.fromMap(Map<String, dynamic> m) => CopqRow(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        category: m['category'] as String,
        before: (m['before'] as num).toDouble(),
        after: (m['after'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'category': category,
        'before': before,
        'after': after,
      };
}

/// درس آموخته (جدول Lessons_Learned)
class LessonLearned {
  const LessonLearned({
    this.id,
    required this.problemId,
    required this.lesson,
    required this.category,
    this.createdAt,
  });

  final int? id;
  final int problemId;
  final String lesson;
  final String category; // technical | team | process | management
  final DateTime? createdAt;

  /// نام فارسی دسته‌ی درس‌آموخته
  String get categoryFa => faCategories[category] ?? category;

  static const Map<String, String> faCategories = {
    'technical': 'فنی',
    'team': 'تیمی',
    'process': 'فرایندی',
    'management': 'مدیریتی',
  };

  factory LessonLearned.fromMap(Map<String, dynamic> m) => LessonLearned(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        lesson: m['lesson'] as String,
        category: m['category'] as String? ?? 'technical',
        createdAt: parseDbDate(m['created_at']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'lesson': lesson,
        'category': category,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}

/// تحلیل KT — جدول Is / Is Not
class KtAnalysis {
  const KtAnalysis({
    this.isWhat = '',
    this.isNotWhat = '',
    this.isWhere = '',
    this.isNotWhere = '',
    this.isWhen = '',
    this.isNotWhen = '',
    this.isWho = '',
    this.isNotWho = '',
  });

  final String isWhat, isNotWhat;
  final String isWhere, isNotWhere;
  final String isWhen, isNotWhen;
  final String isWho, isNotWho;

  Map<String, dynamic> toJson() => {
        'is_what': isWhat, 'is_not_what': isNotWhat,
        'is_where': isWhere, 'is_not_where': isNotWhere,
        'is_when': isWhen, 'is_not_when': isNotWhen,
        'is_who': isWho, 'is_not_who': isNotWho,
      };

  factory KtAnalysis.fromJson(Map<String, dynamic> j) => KtAnalysis(
        isWhat: j['is_what'] as String? ?? '',
        isNotWhat: j['is_not_what'] as String? ?? '',
        isWhere: j['is_where'] as String? ?? '',
        isNotWhere: j['is_not_where'] as String? ?? '',
        isWhen: j['is_when'] as String? ?? '',
        isNotWhen: j['is_not_when'] as String? ?? '',
        isWho: j['is_who'] as String? ?? '',
        isNotWho: j['is_not_who'] as String? ?? '',
      );
}
