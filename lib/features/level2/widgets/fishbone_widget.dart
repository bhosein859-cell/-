import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/fishbone_node.dart';
import '../level2_provider.dart';

/// هندسه‌ی نمودار — مشترک بین رسم (CustomPainter)، برخورد (hit-test)
/// و رندر PNG برای گزارش Word.
class FishboneLayout {
  FishboneLayout._();

  Size size = Size.zero;
  double spineY = 0;
  Rect headRect = Rect.zero;
  final Map<int, Rect> categoryLabels = {}; // nodeId → rect
  final Map<int, Offset> ribOuter = {}; // nodeId → انتهای بیرونی دنده
  final Map<int, Offset> ribAnchor = {}; // nodeId → نقطه‌ی اتصال به ستون فقرات
  final Map<int, Rect> childRects = {}; // nodeId → rect متن زیرشاخه
  final Map<int, Offset> childSpur = {}; // نقطه‌ی شروع خار زیرشاخه

  static FishboneLayout compute(List<FishboneNode> nodes, Size size) {
    final L = FishboneLayout._()
      ..size = size
      ..spineY = size.height / 2
      ..headRect = Rect.fromLTWH(size.width - 168, size.height / 2 - 46, 148, 92);

    final roots = nodes.where((n) => n.isCategory).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    const topDy = -1.0, botDy = 1.0;
    for (var i = 0; i < roots.length; i++) {
      final row = i < 3 ? topDy : botDy;
      final col = i % 3;
      final usable = (size.width - 380) / 3;
      final sx = size.width - 260 - col * usable - (row == botDy ? usable / 2.4 : 0);
      final anchor = Offset(sx, L.spineY);
      final outer = Offset(sx - 130, row == topDy ? 52 : size.height - 52);
      L.ribAnchor[roots[i].id!] = anchor;
      L.ribOuter[roots[i].id!] = outer;
      L.categoryLabels[roots[i].id!] = Rect.fromCenter(
          center: Offset(outer.dx - 46, outer.dy), width: 118, height: 34);

      // زیرشاخه‌ها روی دنده
      final children = nodes
          .where((n) => n.parentId == roots[i].id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (var j = 0; j < children.length; j++) {
        final t = 0.30 + 0.17 * j;
        final onRib = Offset.lerp(outer, anchor, t.clamp(0.15, 0.92).toDouble())!;
        final spurEnd = Offset(onRib.dx - 64, onRib.dy);
        final textRect = Rect.fromLTWH(
            spurEnd.dx - 150, spurEnd.dy - 13, 146, 26);
        L.childSpur[children[j].id!] = onRib;
        L.childRects[children[j].id!] = textRect;
      }
    }
    return L;
  }
}

/// نقاش نمودار استخوان‌ماهی (RTL: سرِ مسئله سمت راست).
class FishbonePainter extends CustomPainter {
  FishbonePainter({
    required this.nodes,
    required this.problemTitle,
    this.dragId,
    this.dragOffset,
  });

  final List<FishboneNode> nodes;
  final String problemTitle;
  final int? dragId;
  final Offset? dragOffset;

  TextPainter _tp(String text,
      {double size = 13, FontWeight w = FontWeight.w500, Color color = Colors.black87}) {
    return TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontFamily: 'Vazirmatn', fontSize: size, fontWeight: w, color: color)),
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: 170);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final L = FishboneLayout.compute(nodes, size);

    // ستون فقرات + سر
    final spinePaint = Paint()
      ..color = AppColors.navyBlue
      ..strokeWidth = 4;
    canvas.drawLine(Offset(24, L.spineY), Offset(L.headRect.left, L.spineY), spinePaint);

    final headPaint = Paint()..color = AppColors.navyBlue;
    canvas.drawRRect(
        RRect.fromRectAndRadius(L.headRect, const Radius.circular(14)), headPaint);
    final headText = _tp(problemTitle, size: 13, w: FontWeight.w800, color: Colors.white);
    headText.paint(
        canvas,
        Offset(L.headRect.center.dx - headText.width / 2,
            L.headRect.center.dy - headText.height / 2));

    final ribPaint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: .8)
      ..strokeWidth = 3;
    final spurPaint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 2;

    for (final n in nodes.where((n) => n.isCategory)) {
      final anchor = L.ribAnchor[n.id!]!;
      final outer = L.ribOuter[n.id!]!;
      canvas.drawLine(anchor, outer, ribPaint);

      // برچسب دسته
      final rect = L.categoryLabels[n.id!]!;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          Paint()..color = AppColors.orange);
      final tp = _tp(n.title, size: 13.5, w: FontWeight.w800, color: Colors.white);
      tp.paint(canvas,
          Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));

      // راهنمای «+ افزودن زیرشاخه»
      final plus = _tp('＋', size: 12, w: FontWeight.w900, color: AppColors.orange);
      plus.paint(canvas, Offset(outer.dx - 6, outer.dy - 8));
    }

    // زیرشاخه‌ها
    for (final c in nodes.where((n) => !n.isCategory)) {
      final rect = L.childRects[c.id]!;
      var drawRect = rect;
      if (dragId == c.id && dragOffset != null) {
        drawRect = rect.shift(dragOffset!);
      }
      final spur = L.childSpur[c.id]!;
      canvas.drawLine(
          spur,
          Offset(drawRect.right + 4, drawRect.center.dy),
          spurPaint);

      final tp = _tp(c.title,
          size: 12.5,
          w: c.isRootCause ? FontWeight.w900 : FontWeight.w500,
          color: c.isRootCause ? AppColors.level3 : Colors.black87);
      tp.paint(canvas, Offset(drawRect.right - tp.width, drawRect.center.dy - tp.height / 2));

      if (c.isRootCause) {
        canvas.drawCircle(Offset(drawRect.right + 2, drawRect.center.dy), 5,
            Paint()..color = AppColors.level3);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FishbonePainter old) =>
      old.nodes != nodes || old.dragId != dragId || old.dragOffset != dragOffset;
}

/// ویجت تعاملی استخوان‌ماهی: زوم/پن، کلیک برای افزودن،
/// لمس‌طولانی + کشیدن برای جابه‌جایی (Drag & Drop).
class FishboneWidget extends ConsumerStatefulWidget {
  const FishboneWidget({super.key});

  @override
  ConsumerState<FishboneWidget> createState() => _FishboneWidgetState();
}

class _FishboneWidgetState extends ConsumerState<FishboneWidget> {
  int? _dragId;
  Offset _dragOffset = Offset.zero;

  void _hitTest(Offset localPosition, Size size,
      {void Function(FishboneNode)? onCategory, void Function(FishboneNode)? onChild}) {
    final state = ref.read(level2WizardProvider);
    final L = FishboneLayout.compute(state.fishbone, size);
    for (final n in state.fishbone) {
      if (n.isCategory && L.categoryLabels[n.id]!.contains(localPosition)) {
        onCategory?.call(n);
        return;
      }
      if (!n.isCategory && L.childRects[n.id]!.inflate(6).contains(localPosition)) {
        onChild?.call(n);
        return;
      }
    }
  }

  Future<void> _addChildDialog(FishboneNode category) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('زیرشاخه‌ی جدید برای «${category.title}»'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'علت احتمالی…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('افزودن')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(level2WizardProvider.notifier)
          .addFishboneChild(category.id!, controller.text.trim());
    }
  }

  Future<void> _childMenu(FishboneNode child) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('ویرایش عنوان'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: AppColors.level3),
              title: Text(child.isRootCause ? 'حذف علامت ریشه‌ی اصلی' : 'علامت‌گذاری به‌عنوان ریشه‌ی اصلی'),
              onTap: () => Navigator.pop(ctx, 'root'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.level3),
              title: const Text('حذف'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    final notifier = ref.read(level2WizardProvider.notifier);
    if (action == 'root') {
      await notifier.toggleRootCause(child.id!);
    } else if (action == 'delete') {
      await notifier.deleteFishbone(child.id!);
    } else if (action == 'edit') {
      final controller = TextEditingController(text: child.title);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ویرایش'),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ذخیره')),
          ],
        ),
      );
      if (ok == true) await notifier.renameFishbone(child.id!, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 430);
        return InteractiveViewer(
          minScale: 0.6,
          maxScale: 2.4,
          boundaryMargin: const EdgeInsets.all(80),
          child: GestureDetector(
            // کلیک: افزودن زیرشاخه / منوی گره
            onTapUp: (details) => _hitTest(
              details.localPosition,
              size,
              onCategory: _addChildDialog,
              onChild: _childMenu,
            ),
            // لمس طولانی + کشیدن: جابه‌جایی زیرشاخه
            onLongPressStart: (details) => _hitTest(
              details.localPosition,
              size,
              onChild: (c) => setState(() {
                _dragId = c.id;
                _dragOffset = Offset.zero;
              }),
            ),
            onLongPressMoveUpdate: (details) {
              if (_dragId != null) {
                setState(() => _dragOffset = details.localPosition * 0.35);
              }
            },
            onLongPressEnd: (details) async {
              final id = _dragId;
              setState(() {
                _dragId = null;
                _dragOffset = Offset.zero;
              });
              if (id == null) return;
              final dx = details.localPosition.dx;
              if (dx.abs() > 50) {
                final node = state.fishbone.firstWhere((n) => n.id == id);
                final newIndex = node.sortOrder + (dx < -50 ? 1 : -1);
                await ref
                    .read(level2WizardProvider.notifier)
                    .reorderFishboneChild(id, newIndex);
              }
            },
            child: CustomPaint(
              size: size,
              painter: FishbonePainter(
                nodes: state.fishbone,
                problemTitle: state.title,
                dragId: _dragId,
                dragOffset: _dragOffset,
              ),
            ),
          ),
        );
      },
    );
  }
}
