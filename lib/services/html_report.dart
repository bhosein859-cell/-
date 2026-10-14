import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/database/database_helper.dart';
import 'downloads_resolver.dart';

/// ═══════════════════════════════════════════════════════════════
/// خروجی HTML تعاملی — وب‌سایت تک‌فایلی و کاملاً آفلاین
/// نمودارها با SVG داخلی رسم می‌شوند و بخش‌ها با کلیک باز/بسته
/// می‌شوند؛ بدون هیچ وابستگی به اینترنت، در هر مرورگری باز می‌شود.
/// ═══════════════════════════════════════════════════════════════
class HtmlReport {
  HtmlReport(this._db);

  final DatabaseHelper _db;

  Future<String> generate({int? problemId}) async {
    final db = await _db.database;
    final problems = problemId == null
        ? await db.query('problems', orderBy: 'id DESC', limit: 30)
        : await db.query('problems', where: 'id = ?', whereArgs: [problemId]);

    final buf = StringBuffer();
    buf.writeln(_header());

    for (final pr in problems) {
      final id = pr['id'] as int;
      final actions = await db.query('actions', where: 'problem_id = ?', whereArgs: [id]);
      final lessons = await db.query('lessons_learned', where: 'problem_id = ?', whereArgs: [id]);
      final level = pr['level'] as int? ?? 1;
      final status = pr['status'] as String? ?? 'open';

      buf.writeln('<section class="card">');
      buf.writeln('<h2 onclick="this.parentNode.classList.toggle(\'open\')">'
          '📌 ${_esc(pr['title'] as String? ?? '')} '
          '<span class="badge l$level">سطح $level</span> '
          '<span class="badge ${status == 'closed' ? 'done' : 'act'}">'
          '${status == 'closed' ? 'بسته شده' : 'فعال'}</span></h2>');
      buf.writeln('<div class="body">');

      // نمودار وضعیت اقدامات
      final total = actions.length;
      final done = actions.where((a) => a['status'] == 'done').length;
      buf.writeln(_donut(done, total - done));
      buf.writeln('<table><tr><th>اقدام</th><th>وضعیت</th><th>پیشرفت</th></tr>');
      for (final a in actions.take(20)) {
        buf.writeln('<tr><td>${_esc(a['title'] as String? ?? '')}</td>'
            '<td>${_esc(a['status'] as String? ?? '')}</td>'
            '<td>${a['progress'] ?? 0}٪</td></tr>');
      }
      buf.writeln('</table>');

      if (lessons.isNotEmpty) {
        buf.writeln('<h3>📚 درس‌آموخته‌ها</h3><ul>');
        for (final l in lessons) {
          buf.writeln('<li>${_esc(l['lesson'] as String? ?? '')}</li>');
        }
        buf.writeln('</ul>');
      }
      buf.writeln('</div></section>');
    }
    buf.writeln(_footer());

    final dir = await resolveDownloadsDir();
    final path = p.join(dir.path,
        'GerehGosha-Report-${DateTime.now().millisecondsSinceEpoch}.html');
    await File(path).writeAsString(buf.toString(), flush: true);
    return path;
  }

  /// نمودار دونات ساده با SVG (بدون جاوااسکریپت خارجی)
  String _donut(int done, int other) {
    final total = done + other == 0 ? 1 : done + other;
    final doneDeg = done / total * 360;
    return '''
    <div class="donut-wrap">
      <svg width="120" height="120" viewBox="0 0 42 42">
        <circle cx="21" cy="21" r="15.9" fill="none" stroke="#E2E8F0" stroke-width="6"/>
        <circle cx="21" cy="21" r="15.9" fill="none" stroke="#10B981" stroke-width="6"
          stroke-dasharray="$doneDeg ${360 - doneDeg}" stroke-dashoffset="90"
          stroke-linecap="round"/>
        <text x="21" y="23" text-anchor="middle" font-size="8" fill="#1E3A8A"
          font-weight="bold">$done/$total</text>
      </svg>
      <p>پیشرفت اقدامات</p>
    </div>''';
  }

  String _header() => '''
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>گزارش گره‌گشا</title>
<style>
  * { box-sizing: border-box; font-family: Vazirmatn, Tahoma, sans-serif; }
  body { background:#F1F5F9; color:#0F172A; margin:0; padding:24px; }
  header { text-align:center; margin-bottom:24px; }
  header h1 { color:#1E3A8A; margin:0; }
  header p { color:#F97316; font-weight:bold; margin:6px 0 0; }
  .card { background:#fff; border-radius:14px; padding:18px; margin-bottom:16px;
          box-shadow:0 1px 4px rgba(0,0,0,.08); }
  .card h2 { cursor:pointer; color:#1E3A8A; font-size:18px; }
  .card:not(.open) .body { display:none; }
  .badge { display:inline-block; padding:2px 10px; border-radius:999px;
           font-size:12px; vertical-align:middle; }
  .l1 { background:#DBEAFE; color:#1E3A8A; }
  .l2 { background:#FEF3C7; color:#B45309; }
  .l3 { background:#FEE2E2; color:#B91C1C; }
  .done { background:#D1FAE5; color:#047857; }
  .act { background:#FFEDD5; color:#C2410C; }
  table { width:100%; border-collapse:collapse; margin-top:10px; }
  th, td { padding:8px; border-bottom:1px solid #E2E8F0; text-align:right; font-size:14px; }
  th { color:#64748B; font-size:12px; }
  .donut-wrap { float:left; text-align:center; margin-left:16px; }
  .donut-wrap p { font-size:12px; color:#64748B; }
  footer { text-align:center; color:#94A3B8; font-size:12px; margin-top:30px; }
</style>
</head>
<body>
<header>
  <h1>گره‌گشا</h1>
  <p>گزارش تعاملی پروژه‌ها — ساخته‌ی حسین بختیاری</p>
</header>
''';

  String _footer() => '''
<footer>گره‌گشا نسخه ۱٫۰٫۰ — تولید شده در ${DateTime.now().toIso8601String().substring(0, 16)} — آفلاین و بدون نیاز به اینترنت</footer>
</body>
</html>''';

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

final htmlReportProvider =
    Provider<HtmlReport>((ref) => HtmlReport(ref.watch(databaseProvider)));
