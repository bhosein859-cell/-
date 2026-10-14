import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/persian_utils.dart';
import '../data/models/action_item.dart';
import '../data/models/problem.dart';

/// مولد گزارش Word (.docx) — کاملاً آفلاین و بدون نیاز به فایل قالب.
///
/// به‌جای `docx_template`، یک بسته‌ی OOXML استاندارد (ZIP) به‌صورت برنامه‌نویسی‌شده
/// ساخته می‌شود؛ مزایا: بدون دارایی اضافی، پشتیبانی کامل راست‌به‌چپ
/// (`w:bidi` / `w:rtl`) و فونت وزیرمتن.
class WordExporter {
  // ════════════════ بخش‌های ثابت بسته‌ی docx ════════════════

  static const String _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

  static const String _rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const String _docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static const String _styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr>
<w:rFonts w:ascii="Vazirmatn" w:hAnsi="Vazirmatn" w:cs="Vazirmatn" w:eastAsia="Vazirmatn"/>
<w:sz w:val="22"/><w:szCs w:val="22"/>
</w:rPr></w:rPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/>
<w:pPr><w:jc w:val="center"/><w:bidi/></w:pPr>
<w:rPr><w:b/><w:sz w:val="36"/><w:szCs w:val="36"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/>
<w:pPr><w:spacing w:before="240" w:after="120"/><w:bidi/></w:pPr>
<w:rPr><w:b/><w:color w:val="1E3A8A"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
</w:styles>''';

  // ════════════════ ابزارهای XML ════════════════

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// یک run راست‌به‌چپ با فونت وزیرمتن
  String _run(String text, {bool bold = false, int? size, String? color}) {
    final rpr = StringBuffer('<w:rPr>')
      ..write(bold ? '<w:b/><w:bCs/>' : '')
      ..write(size != null ? '<w:sz w:val="$size"/><w:szCs w:val="$size"/>' : '')
      ..write(color != null ? '<w:color w:val="$color"/>' : '')
      ..write('<w:rFonts w:ascii="Vazirmatn" w:hAnsi="Vazirmatn" w:cs="Vazirmatn"/>')
      ..write('<w:rtl/>')
      ..write('</w:rPr>');
    return '<w:r>$rpr<w:t xml:space="preserve">${_esc(text)}</w:t></w:r>';
  }

  /// پاراگراف راست‌به‌چپ ساده
  String _p(String text,
      {String? style, bool bold = false, int? size, bool center = false, String? color}) {
    final ppr = StringBuffer('<w:pPr>')
      ..write(style != null ? '<w:pStyle w:val="$style"/>' : '')
      ..write('<w:bidi/>')
      ..write(center ? '<w:jc w:val="center"/>' : '')
      ..write('</w:pPr>');
    return '<w:p>$ppr${_run(text, bold: bold, size: size, color: color)}</w:p>';
  }

  /// پاراگراف «برچسب: مقدار» با برچسب پررنگ نارنجی
  String _lv(String label, String value) =>
      '<w:p><w:pPr><w:bidi/></w:pPr>'
      '${_run('$label: ', bold: true, color: 'F97316')}'
      '${_run(value)}</w:p>';

  String _empty() => '<w:p/>';

  // ════════════════ ساخت گزارش سطح ۱ ════════════════

  /// تولید فایل .docx گزارش مسئله‌ی سطح ۱ و ذخیره در پوشه‌ی Downloads کاربر.
  /// مسیر فایل نهایی برمی‌گردد.
  Future<String> exportLevel1Report({
    required Problem problem,
    required List<ActionItem> actions,
  }) async {
    final now = DateTime.now();
    final whys = (problem.metadata['five_whys'] is List)
        ? (problem.metadata['five_whys'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final body = StringBuffer()
      // سربرگ گزارش — هویت محصول و سازنده
      ..write(_p('گزارش حل مسئله — سطح ۱ (حل سریع)', style: 'Title'))
      ..write(_p('نرم‌افزار: ${AppConstants.appName} | سازنده: ${AppConstants.creator}',
          center: true, size: 20, color: '555555'))
      ..write(_p('تاریخ گزارش: ${PersianUtils.faDate(now)}',
          center: true, size: 20, color: '555555'))
      ..write(_empty())

      // ۱) مشخصات مسئله
      ..write(_p('۱) مشخصات مسئله', style: 'Heading1'))
      ..write(_lv('کد مسئله', problem.code ?? 'PRB-${problem.id ?? ''}'))
      ..write(_lv('عنوان', problem.title))
      ..write(_lv('اولویت', _priorityFa(problem.priority)))
      ..write(_lv('محل / دپارتمان',
          (problem.metadata['location']?.toString().isEmpty ?? true)
              ? '—'
              : problem.metadata['location'].toString()))
      ..write(_lv('وضعیت', problem.statusFa))
      ..write(_lv('شرح', problem.description ?? '—'))
      ..write(_empty())

      // ۲) ریشه‌یابی سریع (۵ چرا)
      ..write(_p('۲) ریشه‌یابی سریع (۵ چرا)', style: 'Heading1'));
    for (var i = 0; i < 5; i++) {
      final answer = i < whys.length && whys[i].trim().isNotEmpty ? whys[i] : '—';
      body.write(_lv('چرا ${PersianUtils.faDigits('${i + 1}')}', answer));
    }
    body
      ..write(_empty())

      // ۳) اقدام فوری
      ..write(_p('۳) اقدام فوری', style: 'Heading1'));
    if (actions.isEmpty) {
      body.write(_p('اقدامی ثبت نشده است.', size: 20, color: '555555'));
    } else {
      for (final a in actions) {
        body
          ..write(_lv('چه کاری انجام شد؟', a.title))
          ..write(_lv('چه کسی انجام داد؟', a.metadata['done_by']?.toString() ?? '—'))
          ..write(_lv('چه زمانی؟', a.metadata['done_at'] != null
              ? PersianUtils.faDateTime(DateTime.tryParse(a.metadata['done_at'].toString()) ?? now)
              : PersianUtils.faDateTime(now)))
          ..write(_lv('وضعیت اقدام', a.statusFa));
      }
    }
    body
      ..write(_empty())

      // ۴) تایید نهایی
      ..write(_p('۴) تایید نهایی', style: 'Heading1'))
      ..write(_lv('مشکل برطرف شد؟', problem.metadata['verified'] == true ? 'بله' : 'خیر'))
      ..write(_lv('تاریخ بستن', problem.resolvedAt != null
          ? PersianUtils.faDateTime(problem.resolvedAt!)
          : '—'))
      ..write(_empty())
      ..write(_p('— پایان گزارش — تولیدشده توسط ${AppConstants.appName} • ${AppConstants.creator}',
          center: true, size: 18, color: '888888'));

    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
${body.toString()}
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr>
</w:body>
</w:document>''';

    // مونتاژ بسته‌ی ZIP با پسوند .docx
    final archive = Archive()
      ..addFile(_entry('[Content_Types].xml', _contentTypes))
      ..addFile(_entry('_rels/.rels', _rootRels))
      ..addFile(_entry('word/document.xml', documentXml))
      ..addFile(_entry('word/styles.xml', _styles))
      ..addFile(_entry('word/_rels/document.xml.rels', _docRels));

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) throw StateError('خطا در ساخت بسته‌ی docx');

    final dir = await _resolveDownloadsDir();
    final path = p.join(dir.path, 'GerehGosha-Report-${problem.id ?? 0}.docx');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  ArchiveFile _entry(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  String _priorityFa(String priority) => const {
        'low': 'کم',
        'medium': 'متوسط',
        'high': 'زیاد',
      }[priority] ??
      priority;

  // ════════════════ تعیین پوشه‌ی Downloads ════════════════

  /// ویندوز: پوشه‌ی Downloads کاربر | اندروید: Downloads عمومی با فال‌بک ایمن
  Future<Directory> _resolveDownloadsDir() async {
    if (Platform.isAndroid) {
      // تلاش برای Downloads عمومی (نیازمند مجوز در اندروید ≤۹؛ در اندروید ۱۰+
      // در صورت عدم دسترسی، به‌صورت ایمن فال‌بک می‌شود)
      try {
        final pub = Directory('/storage/emulated/0/Download');
        if (await pub.exists()) {
          final probe = File(p.join(pub.path, '.gerehgosha_probe'));
          await probe.writeAsString('ok');
          await probe.delete();
          return pub;
        }
      } catch (_) {
        // دسترسی مستقیم ممکن نیست → فال‌بک
      }
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final dir = Directory(p.join(ext.path, 'Download'));
        await dir.create(recursive: true);
        return dir;
      }
    } else {
      try {
        final dl = await getDownloadsDirectory();
        if (dl != null) return dl;
      } catch (_) {
        // فال‌بک به اسناد
      }
    }
    return getApplicationDocumentsDirectory();
  }
}
