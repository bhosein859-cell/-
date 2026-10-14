import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


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

  /// رندر لوگوی گره‌گشا به PNG (برای صفحه‌ی عنوان گزارش).
  /// از لوگوی PNG همراه برنامه استفاده می‌کند تا وابسته به API کتابخانه‌ی
  /// برداری (SVG) نباشد؛ خود نمایش درون‌برنامه‌ای همچنان SVG است.
  static Future<Uint8List> renderLogoPng({double size = 512}) async {
    final asset = await rootBundle.load('assets/images/logo.png');
    final target = size.round().clamp(16, 4096);
    final codec = await ui.instantiateImageCodec(
      asset.buffer.asUint8List(),
      targetWidth: target,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    codec.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawImage(image, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final out = await picture.toImage(image.width, image.height);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    out.dispose();
    return data!.buffer.asUint8List();
  }
}
