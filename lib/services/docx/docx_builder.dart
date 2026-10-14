import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// سازنده‌ی عمومی فایل Word (.docx) — کاملاً آفلاین.
///
/// پشتیبانی: پاراگراف راست‌به‌چپ، عنوان/سرتیتر، جدول، تصویر (PNG)،
/// صفحه‌ی جدید. خروجی: بایت‌های یک بسته‌ی OOXML معتبر.
class DocxBuilder {
  final StringBuffer _body = StringBuffer();
  final List<Uint8List> _images = [];

  // ═══════════════ ابزارهای متنی ═══════════════

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

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

  /// پاراگراف راست‌به‌چپ
  void para(String text,
      {String? style, bool bold = false, int? size, bool center = false, String? color, int indentRight = 0}) {
    final ppr = StringBuffer('<w:pPr>')
      ..write(style != null ? '<w:pStyle w:val="$style"/>' : '')
      ..write(indentRight > 0 ? '<w:ind w:right="$indentRight"/>' : '')
      ..write('<w:bidi/>')
      ..write(center ? '<w:jc w:val="center"/>' : '')
      ..write('</w:pPr>');
    _body.write('<w:p>$ppr${_run(text, bold: bold, size: size, color: color)}</w:p>');
  }

  /// پاراگراف «برچسب: مقدار»
  void labelValue(String label, String value) {
    _body.write('<w:p><w:pPr><w:bidi/></w:pPr>'
        '${_run('$label: ', bold: true, color: 'F97316')}'
        '${_run(value)}</w:p>');
  }

  void heading(String text) => para(text, style: 'Heading1');

  void empty() => _body.write('<w:p/>');

  void pageBreak() => _body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');

  // ═══════════════ جدول ═══════════════

  /// جدول راست‌به‌چپ با حاشیه — سطر اول به‌عنوان سربرگ پررنگ
  void table(List<List<String>> rows) {
    if (rows.isEmpty) return;
    final cols = rows.first.length;
    final colW = 9000 ~/ cols;

    final sb = StringBuffer()
      ..write('<w:tbl><w:tblPr><w:tblW w:w="9000" w:type="dxa"/><w:bidiVisual/>')
      ..write('<w:tblBorders>')
      ..write('<w:top w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('<w:left w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('<w:bottom w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('<w:right w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('<w:insideH w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('<w:insideV w:val="single" w:sz="4" w:space="0" w:color="94A3B8"/>')
      ..write('</w:tblBorders></w:tblPr>')
      ..write('<w:tblGrid>${'<w:gridCol w:w="$colW"/>' * cols}</w:tblGrid>');

    for (var r = 0; r < rows.length; r++) {
      sb.write('<w:tr>');
      for (var c = 0; c < cols; c++) {
        final cell = c < rows[r].length ? rows[r][c] : '';
        sb.write('<w:tc><w:tcPr><w:tcW w:w="$colW" w:type="dxa"/>')
          ..write(r == 0 ? '<w:shd w:val="clear" w:color="auto" w:fill="1E3A8A"/>' : '')
          ..write('</w:tcPr><w:p><w:pPr><w:bidi/></w:pPr>')
          ..write(_run(cell,
              bold: r == 0,
              size: 18,
              color: r == 0 ? 'FFFFFF' : '000000'))
          ..write('</w:p></w:tc>');
      }
      sb.write('</w:tr>');
    }
    sb.write('</w:tbl>');
    _body.write(sb.toString());
  }

  // ═══════════════ تصویر ═══════════════

  /// جاسازی تصویر PNG با ابعاد سانتی‌متری
  void image(Uint8List png, {double widthCm = 15.8, double heightCm = 8.5}) {
    _images.add(png);
    final index = _images.length;
    final cx = (widthCm * 360000).round();
    final cy = (heightCm * 360000).round();
    _body.write('''
<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:drawing>
<wp:inline distT="0" distB="0" distL="0" distR="0">
<wp:extent cx="$cx" cy="$cy"/><wp:docPr id="$index" name="img$index"/>
<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
<pic:pic><pic:nvPicPr><pic:cNvPr id="$index" name="img$index"/><pic:cNvPicPr/></pic:nvPicPr>
<pic:blipFill><a:blip r:embed="rImg$index"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>''');
  }

  // ═══════════════ مونتاژ بسته ═══════════════

  static const String _styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr>
<w:rFonts w:ascii="Vazirmatn" w:hAnsi="Vazirmatn" w:cs="Vazirmatn" w:eastAsia="Vazirmatn"/>
<w:sz w:val="22"/><w:szCs w:val="22"/>
</w:rPr></w:rPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/>
<w:pPr><w:jc w:val="center"/><w:bidi/></w:pPr>
<w:rPr><w:b/><w:sz w:val="40"/><w:szCs w:val="40"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/>
<w:pPr><w:spacing w:before="240" w:after="120"/><w:bidi/></w:pPr>
<w:rPr><w:b/><w:color w:val="1E3A8A"/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
</w:styles>''';

  Uint8List build() {
    final hasImages = _images.isNotEmpty;

    final contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
${hasImages ? '<Default Extension="png" ContentType="image/png"/>' : ''}
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

    final rootRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final docRels = StringBuffer('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>''');
    for (var i = 1; i <= _images.length; i++) {
      docRels.write(
          '<Relationship Id="rImg$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image$i.png"/>');
    }
    docRels.write('</Relationships>');

    final document = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
 xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
<w:body>
${_body.toString()}
<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1000" w:right="1000" w:bottom="1000" w:left="1000"/></w:sectPr>
</w:body>
</w:document>''';

    final archive = Archive()
      ..addFile(_entry('[Content_Types].xml', contentTypes))
      ..addFile(_entry('_rels/.rels', rootRels))
      ..addFile(_entry('word/document.xml', document))
      ..addFile(_entry('word/styles.xml', _styles))
      ..addFile(_entry('word/_rels/document.xml.rels', docRels.toString()));
    for (var i = 1; i <= _images.length; i++) {
      archive.addFile(ArchiveFile('word/media/image$i.png', _images[i - 1].length, _images[i - 1]));
    }

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) throw StateError('خطا در ساخت بسته‌ی docx');
    return bytes;
  }

  ArchiveFile _entry(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }
}
