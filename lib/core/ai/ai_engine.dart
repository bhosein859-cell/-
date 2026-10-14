import 'dart:convert';
import 'dart:math' as math;

import '../../data/database/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ═══════════════════════════════════════════════════════════════
/// موتور هوش مصنوعی آفلاین گره‌گشا (On-Device AI)
///
/// بدون هیچ مدل خارجی و بدون اینترنت: این موتور از «مسائل حل‌شده‌ی
/// داخل دیتابیس محلی» یاد می‌گیرد. روش کار:
///   ۱. بردارسازی متن با TF-IDF (وزن‌دهی فرکانس واژه)
///   ۲. یافتن مسائل مشابه با شباهت کسینوسی
///   ۳. استخراج ریشه‌ها/چراها/درس‌های آن مسائل و پیشنهاد به کاربر
///
/// حجم موتور: کمتر از ۱۰۰ کیلوبایت کد — بسیار سبک‌تر از حد ۵۰ مگابایت.
/// ═══════════════════════════════════════════════════════════════
class AiEngine {
  AiEngine(this._db);

  final DatabaseHelper _db;

  /// واژه‌های توقف فارسی (حذف از بردار برای افزایش دقت)
  static const Set<String> _stopWords = {
    'و', 'در', 'به', 'از', 'که', 'این', 'را', 'با', 'است', 'برای',
    'آن', 'یک', 'خود', 'ها', 'های', 'شد', 'شده', 'می', 'تا', 'بر',
    'نیز', 'یا', 'اما', 'چون', 'هر', 'ما', 'شما', 'آنها', 'بود',
  };

  /// طبقه‌بندی موضوعی بر اساس واژگان کلیدی صنایع
  static const Map<String, List<String>> _categoryKeywords = {
    'کیفیت': ['ضایعات', 'معیوب', 'خرابی', 'بازگشت', 'شکایت', 'کیفیت', 'تست', 'بازرسی'],
    'ایمنی': ['حادثه', 'ایمنی', 'آسیب', 'خطر', 'زخمی', 'سوختگی', 'سقوط'],
    'تولید': ['خط', 'توقف', 'دستگاه', 'اپراتور', 'شیفت', 'تولید', 'ظرفیت'],
    'مالی': ['هزینه', 'بودجه', 'زیان', 'تأخیر پرداخت', 'بدهی', 'فروش'],
    'منابع انسانی': ['غیبت', 'ترک کار', 'آموزش', 'پرسنل', 'استخدام', 'اضافه‌کاری'],
    'تجهیزات': ['موتور', 'سنسور', 'نشتی', 'روغن', 'بلبرینگ', 'کالیبراسیون', 'قطعه'],
    'نرم‌افزار': ['سرور', 'دیتابیس', 'باگ', 'خطای سیستم', 'شبکه', 'کاربر'],
  };

  /// واژگان احساسی برای تحلیل لحن نظرات (فارسی)
  static const Map<String, int> _sentimentLexicon = {
    'عالی': 2, 'خوب': 1, 'راضی': 1, 'موفق': 1, 'بهتر': 1, 'پیشرفت': 1,
    'ممنون': 1, 'سریع': 1, 'دقیق': 1, 'مؤثر': 1, 'حل شد': 2, 'آسان': 1,
    'بد': -1, 'ضعیف': -1, 'ناراضی': -1, 'شکست': -2, 'مشکل': -1, 'خراب': -2,
    'کند': -1, 'دیر': -1, 'گران': -1, 'خطرناک': -2, 'فاجعه': -2, 'شکایت': -1,
    'ناامید': -2, 'عصبانی': -2, 'مردود': -2,
  };

  // ───────────────── توکن‌سازی و بردارسازی ─────────────────

  List<String> tokenize(String text) {
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[‌.!؟?،,؛;:()\[\]"«»]'), ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();
  }

  /// بردار فرکانس واژه (Term Frequency)
  Map<String, double> tf(List<String> tokens) {
    final counts = <String, double>{};
    for (final t in tokens) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final n = tokens.isEmpty ? 1 : tokens.length;
    return {for (final e in counts.entries) e.key: e.value / n};
  }

  /// شباهت کسینوسی بین دو بردار واژه
  double cosine(Map<String, double> a, Map<String, double> b) {
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (final e in a.entries) {
      final bv = b[e.key];
      if (bv != null) dot += e.value * bv;
      na += e.value * e.value;
    }
    for (final v in b.values) {
      nb += v * v;
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  // ───────────────── حافظه‌ی تجربیات (مسائل بسته‌شده) ─────────────────

  Future<List<_Memory>> _closedMemories() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT p.id, p.title, COALESCE(p.description,'') AS description, p.metadata
      FROM problems p
      WHERE p.status = 'closed'
    ''');
    final out = <_Memory>[];
    for (final r in rows) {
      final meta = jsonDecode(r['metadata'] as String? ?? '{}') as Map<String, dynamic>;
      final whys = (meta['whys_tree'] as List? ?? const [])
          .map((w) => (w as Map)['text']?.toString() ?? '')
          .toList();
      // ریشه‌ها = برگ‌های درخت چراها
      final roots = <String>[];
      for (final w in (meta['whys_tree'] as List? ?? const [])) {
        final wm = w as Map;
        final isLeaf = !(meta['whys_tree'] as List)
            .any((x) => (x as Map)['parent_id'] == wm['id']);
        if (isLeaf) roots.add(wm['text']?.toString() ?? '');
      }
      final lessons = <String>[];
      try {
        final ls = await db.query('lessons_learned',
            where: 'problem_id = ?', whereArgs: [r['id']]);
        lessons.addAll(ls.map((l) => l['lesson'] as String? ?? ''));
      } catch (_) {}
      out.add(_Memory(
        id: r['id'] as int,
        title: r['title'] as String? ?? '',
        description: r['description'] as String? ?? '',
        whys: whys.where((w) => w.isNotEmpty).toList(),
        roots: roots.where((w) => w.isNotEmpty).toList(),
        lessons: lessons,
        text: '${r['title']} ${r['description']} ${whys.join(' ')}',
      ));
    }
    return out;
  }

  /// k مسئله‌ی مشابه (به ترتیب شباهت)
  Future<List<SimilarProblem>> findSimilar(String query, {int k = 5}) async {
    final memories = await _closedMemories();
    if (memories.isEmpty) return const [];
    final qv = tf(tokenize(query));
    final scored = <SimilarProblem>[];
    for (final m in memories) {
      final sim = cosine(qv, tf(tokenize(m.text)));
      if (sim > 0.05) {
        scored.add(SimilarProblem(
            id: m.id, title: m.title, similarity: sim, roots: m.roots));
      }
    }
    scored.sort((a, b) => b.similarity.compareTo(a.similarity));
    return scored.take(k).toList();
  }

  // ───────────────── ۱. پیشنهاد ریشه‌های احتمالی ─────────────────

  Future<List<String>> suggestRoots(String problemText) async {
    final similar = await findSimilar(problemText, k: 8);
    final suggestions = <String, double>{};
    for (final s in similar) {
      for (final r in s.roots) {
        suggestions[r] = (suggestions[r] ?? 0) + s.similarity;
      }
    }
    final list = suggestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(6).map((e) => e.key).toList();
  }

  // ───────────────── ۲. پیشنهاد «چرا»ی بعدی ─────────────────

  Future<List<String>> suggestNextWhy(String lastWhy) async {
    final similar = await findSimilar(lastWhy, k: 8);
    final out = <String>[];
    for (final s in similar) {
      for (final w in (await _memoryWhys(s.id))) {
        if (!out.contains(w) && w != lastWhy) out.add(w);
      }
    }
    return out.take(5).toList();
  }

  Future<List<String>> _memoryWhys(int problemId) async {
    final db = await _db.database;
    final rows = await db.query('problems',
        columns: ['metadata'], where: 'id = ?', whereArgs: [problemId]);
    if (rows.isEmpty) return const [];
    final meta =
        jsonDecode(rows.first['metadata'] as String? ?? '{}') as Map<String, dynamic>;
    return (meta['whys_tree'] as List? ?? const [])
        .map((w) => (w as Map)['text']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // ───────────────── ۳. پیشنهاد متدولوژی ─────────────────

  /// بر اساس بحرانیت، تکرارپذیری و واژگان کلیدی
  Future<MethodologySuggestion> suggestMethodology({
    required String title,
    int criticality = 1,
    bool isRecurring = false,
  }) async {
    final text = '$title';
    bool any(List<String> keys) => keys.any((k) => text.contains(k));

    if (criticality >= 4 ||
        any(['شکایت مشتری', 'ایمنی', 'حادثه', 'بازگشت', 'توقف خط', 'بحرانی'])) {
      return const MethodologySuggestion('8D',
          'مسئله بحرانی/مشتری‌محور است؛ ۸ دیسیپلین تیمی بهترین انتخاب است.', 90);
    }
    if (any(['فرایند', 'شش سیگما', 'کاهش تغییرات', 'قابلیت فرایند']) ||
        criticality == 3 && isRecurring) {
      return const MethodologySuggestion('DMAIC',
          'مسئله‌ی فرایندی تکرارشونده؛ چرخه‌ی شش سیگما دقیق‌ترین تحلیل را می‌دهد.', 85);
    }
    if (any(['چرا', 'علت', 'ریشه']) && !isRecurring) {
      return const MethodologySuggestion('RCA جامع',
          'نیاز به ریشه‌یابی عمیق بدون فوریت سازمانی؛ تحلیل ریشه‌ای جامع مناسب است.', 80);
    }
    if (any(['استراتژیک', 'بهبود', 'پروژه بزرگ'])) {
      return const MethodologySuggestion('A3',
          'پروژه‌ی بهبود استراتژیک؛ خلاصه‌سازی یک‌صفحه‌ای A3 شفافیت می‌دهد.', 75);
    }
    return MethodologySuggestion(
        'سطح ۲ (PDCA)',
        isRecurring
            ? 'مسئله‌ی تیمی تکرارشونده؛ چرخه‌ی استاندارد سطح ۲ کافی و سریع است.'
            : 'مسئله‌ی متوسط؛ چرخه‌ی استاندارد سطح ۲ پیشنهاد می‌شود.',
        70);
  }

  // ───────────────── ۴. دسته‌بندی خودکار مسئله ─────────────────

  String classify(String text) {
    final tokens = tokenize(text).toSet();
    var best = 'عمومی';
    var bestScore = 0;
    for (final e in _categoryKeywords.entries) {
      final score = e.value.where(tokens.contains).length;
      if (score > bestScore) {
        bestScore = score;
        best = e.key;
      }
    }
    return best;
  }

  // ───────────────── ۵. تحلیل احساسات ─────────────────

  SentimentResult analyzeSentiment(String text) {
    var score = 0;
    final hits = <String>[];
    for (final e in _sentimentLexicon.entries) {
      if (text.contains(e.key)) {
        score += e.value;
        hits.add(e.key);
      }
    }
    final label = score > 0 ? 'مثبت' : (score < 0 ? 'منفی' : 'خنثی');
    return SentimentResult(label: label, score: score, keywords: hits);
  }

  // ───────────────── ۶. استخراج خودکار درس‌آموخته ─────────────────

  Future<List<String>> extractLessons(int problemId) async {
    final db = await _db.database;
    final meta = await _metaOf(db, problemId);
    final out = <String>[];
    // الگوهای زبانی رایج برای درس‌آموخته در متن‌های پروژه
    final sources = <String>[
      ...((meta['whys_tree'] as List? ?? const [])
          .map((w) => (w as Map)['text']?.toString() ?? '')),
      ...((meta['ideas'] as List? ?? const []).map((e) => e.toString())),
    ];
    for (final s in sources) {
      if (s.contains('باید') || s.contains('نباید') ||
          s.contains('دفعه بعد') || s.contains('بهتر است')) {
        out.add(s);
      }
    }
    // اگر هیچ الگویی نبود، ریشه‌های نهایی را به‌عنوان درس پیشنهاد بده
    if (out.isEmpty) {
      for (final r in await suggestRoots(await _titleOf(db, problemId))) {
        out.add('ریشه‌ی شناسایی‌شده نیازمند کنترل پایدار است: $r');
        if (out.length >= 3) break;
      }
    }
    return out;
  }

  // ───────────────── ۷. تولید خودکار FAQ ─────────────────

  Future<List<Map<String, String>>> generateFaq() async {
    final memories = await _closedMemories();
    return [
      for (final m in memories.take(20))
        {
          'question': 'چگونه مشکل «${m.title}» حل شد؟',
          'answer': m.roots.isEmpty
              ? 'این مسئله با تحلیل ساختاریافته بسته شد.'
              : 'ریشه(ها): ${m.roots.take(3).join('؛ ')}. '
                  '${m.lessons.isEmpty ? '' : 'درس اصلی: ${m.lessons.first}'}',
        },
    ];
  }

  Future<Map<String, dynamic>> _metaOf(dynamic db, int problemId) async {
    final rows = await (db as dynamic).query('problems',
        columns: ['metadata'], where: 'id = ?', whereArgs: [problemId]);
    if (rows.isEmpty) return {};
    return jsonDecode(rows.first['metadata'] as String? ?? '{}')
        as Map<String, dynamic>;
  }

  Future<String> _titleOf(dynamic db, int problemId) async {
    final rows = await (db as dynamic).query('problems',
        columns: ['title'], where: 'id = ?', whereArgs: [problemId]);
    return rows.isEmpty ? '' : rows.first['title'] as String? ?? '';
  }
}

class _Memory {
  const _Memory({
    required this.id,
    required this.title,
    required this.description,
    required this.whys,
    required this.roots,
    required this.lessons,
    required this.text,
  });

  final int id;
  final String title, description, text;
  final List<String> whys, roots, lessons;
}

/// مسئله‌ی مشابه یافت‌شده
class SimilarProblem {
  const SimilarProblem({
    required this.id,
    required this.title,
    required this.similarity,
    required this.roots,
  });

  final int id;
  final String title;
  final double similarity; // ۰ تا ۱
  final List<String> roots;

  String get percent => '${(similarity * 100).toStringAsFixed(0)}٪ شباهت';
}

class MethodologySuggestion {
  const MethodologySuggestion(this.methodology, this.reason, this.confidence);

  final String methodology;
  final String reason;
  final int confidence; // ۰ تا ۱۰۰
}

class SentimentResult {
  const SentimentResult(
      {required this.label, required this.score, required this.keywords});

  final String label; // مثبت | منفی | خنثی
  final int score;
  final List<String> keywords;
}

final aiEngineProvider = Provider<AiEngine>(
  (ref) => AiEngine(ref.watch(databaseProvider)),
);
