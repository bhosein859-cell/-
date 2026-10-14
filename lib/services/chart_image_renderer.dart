import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;

/// رندر آفلاینِ ویجت‌های برداری (CustomPainter / SVG) به PNG باکیفیت —
/// برای جاسازی نمودارها در گزارش Word بدون هیچ سرویس خارجی.
class ChartImageRenderer {
  /// رسم یک CustomPainter (مثل استخوان‌ماهی یا گانت) روی بوم و خروجی PNG.
  static Future<Uint8List> renderPainterPng(
    CustomPainter painter,
    double width,
    double height, {
    double scale = 2,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFFFFFFFF));
    painter.paint(canvas, Size(width, height));
    final picture = recorder.endRecording();
    final image =
        await picture.toImage((width * scale).round(), (height * scale).round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// رندر لوگوی SVG گره‌گشا به PNG (برای صفحه‌ی عنوان گزارش).
  static Future<Uint8List> renderLogoPng({double size = 512}) async {
    final svgText = await rootBundle.loadString('assets/images/logo.svg');
    final info = await vg.loadPicture(SvgStringLoader(svgText), null);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = const Color(0xFFFFFFFF));
    final scale = size / info.size.width;
    canvas.scale(scale);
    canvas.drawPicture(info.picture);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round() * 2, size.round() * 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return data!.buffer.asUint8List();
  }
}
