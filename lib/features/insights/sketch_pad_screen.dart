import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// حالت ترسیم دستی (Stylus Support)
/// کشیدن استخوان‌ماهی، فلوچارت یا یادداشت با قلم/انگشت و ذخیره‌ی
/// آن به‌صورت تصویر PNG در پیوست‌های پروژه.
/// ═══════════════════════════════════════════════════════════════
class SketchPadScreen extends ConsumerStatefulWidget {
  const SketchPadScreen({super.key, required this.problemId});

  final int problemId;

  @override
  ConsumerState<SketchPadScreen> createState() => _SketchPadScreenState();
}

class _SketchPadScreenState extends ConsumerState<SketchPadScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redo = [];
  Color _color = AppColors.navyBlue;
  double _width = 3;

  void _addPoint(Offset p) {
    if (_strokes.isEmpty || _strokes.last.done) {
      _strokes.add(_Stroke(color: _color, width: _width));
    }
    _strokes.last.points.add(p);
    setState(() {});
  }

  Future<void> _saveAsAttachment() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    // ذخیره‌ی فایل در پوشه‌ی رسمی پیوست‌های اپ (کنار دیتابیس)
    final helper = ref.read(databaseProvider);
    final dir = await helper.attachmentsDir;
    final fileName =
        'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    await (await helper.database).insert('attachments', {
      'problem_id': widget.problemId,
      'file_name':
          'ترسیم دستی ${DateTime.now().toIso8601String().substring(0, 16)}.png',
      'file_path': fileName,
      'mime_type': 'image/png',
      'size_bytes': await file.length(),
      'uploaded_by': 1,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ ترسیم به پیوست‌های پروژه اضافه شد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ترسیم دستی'),
        actions: [
          IconButton(
              tooltip: 'بازگشت',
              icon: const Icon(Icons.undo),
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(() => _redo.add(_strokes.removeLast()))),
          IconButton(
              tooltip: 'از نو',
              icon: const Icon(Icons.restore),
              onPressed: _redo.isEmpty
                  ? null
                  : () => setState(() => _strokes.add(_redo.removeLast()))),
          IconButton(
              tooltip: 'پاک کردن همه',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(() {
                    _strokes.clear();
                    _redo.clear();
                  })),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saveAsAttachment,
            icon: const Icon(Icons.save_alt),
            label: const Text('ذخیره در پیوست'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── نوار ابزار قلم ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                for (final c in const [
                  AppColors.navyBlue, AppColors.orange, AppColors.level3,
                  AppColors.success, Colors.black,
                ])
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _color == c
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: .5), blurRadius: 6)
                              ]
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                const Text('ضخامت:'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 12,
                    value: _width,
                    onChanged: (v) => setState(() => _width = v),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── بوم ترسیم ──
          Expanded(
            child: Listener(
              onPointerDown: (d) => _addPoint(d.localPosition),
              onPointerMove: (d) => _addPoint(d.localPosition),
              onPointerUp: (_) => setState(() {
                if (_strokes.isNotEmpty) _strokes.last.done = true;
              }),
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  child: CustomPaint(
                    painter: _SketchPainter(strokes: _strokes),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stroke {
  _Stroke({required this.color, required this.width});

  final Color color;
  final double width;
  final List<Offset> points = [];
  bool done = false;
}

class _SketchPainter extends CustomPainter {
  const _SketchPainter({required this.strokes});

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white);
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter old) => true;
}
