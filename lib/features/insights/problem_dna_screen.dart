import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// دی‌ان‌ای مسئله (Problem DNA)
/// گراف تعاملی ارتباط مسائل سازمان با هم: گره‌ها بر اساس شباهت متن
/// به هم وصل می‌شوند، رنگ گره = سطح بحرانیت، کلیک = باز شدن مسئله.
/// ═══════════════════════════════════════════════════════════════
class ProblemDnaScreen extends ConsumerStatefulWidget {
  const ProblemDnaScreen({super.key});

  @override
  ConsumerState<ProblemDnaScreen> createState() => _ProblemDnaScreenState();
}

class _ProblemDnaScreenState extends ConsumerState<ProblemDnaScreen> {
  List<_Node> _nodes = [];
  List<(int, int)> _edges = [];
  _Node? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final engine = ref.read(aiEngineProvider);
    final db = await ref.read(databaseProvider).database;
    final rows = await db.query('problems',
        columns: ['id', 'title', 'level', 'status', 'description'],
        where: 'is_archived = 0',
        orderBy: 'id DESC',
        limit: 40);

    final nodes = <_Node>[];
    for (final r in rows) {
      nodes.add(_Node(
        id: r['id'] as int,
        title: r['title'] as String? ?? '',
        level: r['level'] as int? ?? 1,
        status: r['status'] as String? ?? 'open',
        tokens: engine.tf(engine.tokenize(
            '${r['title']} ${r['description'] ?? ''}')),
      ));
    }
    // یال بین هر جفت با شباهت بیش از آستانه
    final edges = <(int, int)>[];
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final sim = engine.cosine(nodes[i].tokens, nodes[j].tokens);
        if (sim > 0.18) edges.add((nodes[i].id, nodes[j].id));
      }
    }
    setState(() {
      _nodes = nodes;
      _edges = edges;
      _loading = false;
    });
  }

  Color _levelColor(int level) => switch (level) {
        3 => AppColors.level3,
        2 => AppColors.level2,
        _ => AppColors.navyBlue,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('دی‌ان‌ای مسئله — نقشه ارتباطات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppColors.navyBlue, 'سطح ۱'),
              const SizedBox(width: 12),
              _legend(AppColors.level2, 'سطح ۲'),
              const SizedBox(width: 12),
              _legend(AppColors.level3, 'سطح ۳'),
              const SizedBox(width: 12),
              _legend(Colors.transparent, 'بسته‌شده', outline: true),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? const Center(child: Text('هنوز مسئله‌ای ثبت نشده است.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    _layout(size);
                    return Stack(
                      children: [
                        GestureDetector(
                          onTapUp: (d) => _hitTest(d.localPosition),
                          child: CustomPaint(
                            size: size,
                            painter: _DnaPainter(
                              nodes: _nodes,
                              edges: _edges,
                              positions: _positions,
                              selectedId: _selected?.id,
                              colorOf: _levelColor,
                            ),
                          ),
                        ),
                        if (_selected != null) _detailCard(),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _legend(Color c, String label, {bool outline = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outline ? Colors.transparent : c,
              border: outline
                  ? Border.all(color: AppColors.success, width: 2)
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  final Map<int, Offset> _positions = {};

  /// چیدمان دایره‌ای: مسئله‌ی انتخابی در مرکز، بقیه دور آن
  void _layout(Size size) {
    _positions.clear();
    final c = Offset(size.width / 2, size.height / 2);
    if (_nodes.isEmpty) return;
    if (_selected == null) {
      final r = (size.shortestSide / 2) * 0.72;
      for (var i = 0; i < _nodes.length; i++) {
        final a = 2 * 3.141592653 * i / _nodes.length - 3.141592653 / 2;
        _positions[_nodes[i].id] = c + Offset(r * 1.0 * _cos(a), r * _sin(a));
      }
    } else {
      _positions[_selected!.id] = c;
      final others = _nodes.where((n) => n.id != _selected!.id).toList();
      final r = (size.shortestSide / 2) * 0.75;
      for (var i = 0; i < others.length; i++) {
        final a = 2 * 3.141592653 * i / (others.isEmpty ? 1 : others.length);
        _positions[others[i].id] = c + Offset(r * _cos(a), r * _sin(a));
      }
    }
  }

  double _cos(double a) => math.cos(a);
  double _sin(double a) => math.sin(a);

  void _hitTest(Offset p) {
    for (final e in _positions.entries) {
      if ((e.value - p).distance < 26) {
        setState(() => _selected = _nodes.firstWhere((n) => n.id == e.key));
        return;
      }
    }
    setState(() => _selected = null);
  }

  Widget _detailCard() {
    final n = _selected!;
    return Positioned(
      bottom: 16,
      right: 16,
      left: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: _levelColor(n.level)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(n.title,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selected = null)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'سطح: ${PersianUtils.faDigits('${n.level}')} | '
                'وضعیت: ${n.status == 'closed' ? 'بسته‌شده ✓' : 'فعال'} | '
                'اتصالات: ${PersianUtils.faDigits('${_edges.where((e) => e.$1 == n.id || e.$2 == n.id).length}')}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                'مسائل متصل، علائم مشترک دارند؛ برای جلوگیری از تکرار، '
                'امکان ادغام یا ارجاع متقابل وجود دارد.',
                style: const TextStyle(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Node {
  const _Node({
    required this.id,
    required this.title,
    required this.level,
    required this.status,
    required this.tokens,
  });

  final int id;
  final String title;
  final int level;
  final String status;
  final Map<String, double> tokens;
}

class _DnaPainter extends CustomPainter {
  const _DnaPainter({
    required this.nodes,
    required this.edges,
    required this.positions,
    required this.selectedId,
    required this.colorOf,
  });

  final List<_Node> nodes;
  final List<(int, int)> edges;
  final Map<int, Offset> positions;
  final int? selectedId;
  final Color Function(int level) colorOf;

  @override
  void paint(Canvas canvas, Size size) {
    // یال‌ها
    final edgePaint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: .25)
      ..strokeWidth = 1.6;
    for (final (a, b) in edges) {
      final pa = positions[a];
      final pb = positions[b];
      if (pa != null && pb != null) canvas.drawLine(pa, pb, edgePaint);
    }
    // گره‌ها
    for (final n in nodes) {
      final p = positions[n.id];
      if (p == null) continue;
      final selected = n.id == selectedId;
      final r = selected ? 22.0 : 15.0;
      if (n.status == 'closed') {
        canvas.drawCircle(p, r, Paint()..color = Colors.white);
        canvas.drawCircle(
            p, r,
            Paint()
              ..color = AppColors.success
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      } else {
        canvas.drawCircle(p, r, Paint()..color = colorOf(n.level));
      }
      // برچسب کوتاه
      final tp = TextPainter(
        text: TextSpan(
          text: n.title.length > 14 ? '${n.title.substring(0, 14)}…' : n.title,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: 140);
      tp.paint(canvas, p + Offset(-tp.width / 2, r + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DnaPainter old) =>
      old.nodes != nodes || old.selectedId != selectedId;
}
