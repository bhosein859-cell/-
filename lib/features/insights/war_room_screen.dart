import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// حالت اتاق جنگ (War Room)
/// نمای تمام‌صفحه و ساده برای جلسات طوفان فکری تیمی:
/// تایمر شمارش معکوس + ایده‌های چسبنده + رأی‌گیری سریع آفلاین.
/// ═══════════════════════════════════════════════════════════════
class WarRoomScreen extends ConsumerStatefulWidget {
  const WarRoomScreen({super.key, required this.problemId});

  final int problemId;

  @override
  ConsumerState<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends ConsumerState<WarRoomScreen> {
  final _idea = TextEditingController();
  final List<_Idea> _ideas = [];
  Timer? _timer;
  int _secondsLeft = 5 * 60;
  bool _running = false;

  static const List<Color> _noteColors = [
    Color(0xFFFFF9C4), Color(0xFFFFE0B2), Color(0xFFC8E6C9),
    Color(0xFFBBDEFB), Color(0xFFF8BBD0),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _idea.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        SystemSound.play(SystemSoundType.alert); // هشدار پایان زمان
        setState(() => _running = false);
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⏰ وقت تمام شد!'),
            content: const Text('زمان ایده‌پردازی به پایان رسید؛ '
                'حالا رأی‌گیری کنید.'),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('باشه')),
            ],
          ),
        );
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _addIdea() {
    if (_idea.text.trim().isEmpty) return;
    setState(() {
      _ideas.add(_Idea(
        text: _idea.text.trim(),
        color: _noteColors[_ideas.length % _noteColors.length],
      ));
    });
    _idea.clear();
  }

  Future<void> _voteOnIdeas() async {
    if (_ideas.isEmpty) return;
    final db = await ref.read(databaseProvider).database;
    final pollId = await db.insert('polls', {
      'problem_id': widget.problemId,
      'question': 'کدام ایده برای اجرا انتخاب شود؟',
      'options': jsonEncode([for (final i in _ideas) i.text]),
    });
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _VoteDialog(pollId: pollId, ideas: _ideas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mm = _secondsLeft ~/ 60;
    final ss = _secondsLeft % 60;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('🪖 اتاق جنگ — طوفان فکری'),
        actions: [
          // ── تایمر جلسه ──
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _running
                  ? AppColors.orange.withValues(alpha: .15)
                  : Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer,
                    size: 18,
                    color: _running ? AppColors.orange : Colors.black54),
                const SizedBox(width: 6),
                Text(
                  '${PersianUtils.faDigits('${mm.toString().padLeft(2, '0')}')}'
                  ':${PersianUtils.faDigits('${ss.toString().padLeft(2, '0')}')}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _running ? AppColors.orange : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _running ? 'توقف تایمر' : 'شروع تایمر',
            icon: Icon(_running ? Icons.pause_circle : Icons.play_circle),
            onPressed: _toggleTimer,
          ),
          IconButton(
            tooltip: 'تنظیم زمان',
            icon: const Icon(Icons.more_time),
            onPressed: () {
              setState(() => _secondsLeft = 5 * 60);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── ورود ایده ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idea,
                    onSubmitted: (_) => _addIdea(),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'ایده‌ات را بنویس و اینتر بزن…',
                      prefixIcon: Icon(Icons.lightbulb_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addIdea,
                  icon: const Icon(Icons.add),
                  label: const Text('ثبت'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _voteOnIdeas,
                  icon: const Icon(Icons.how_to_vote_outlined),
                  label: const Text('رأی‌گیری'),
                ),
              ],
            ),
          ),
          // ── دیوار ایده‌ها ──
          Expanded(
            child: _ideas.isEmpty
                ? const Center(
                    child: Text('دیوار خالی است؛ اولین ایده را بچسبان! 💡'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _ideas.length,
                    itemBuilder: (context, i) {
                      final idea = _ideas[i];
                      return GestureDetector(
                        onLongPress: () =>
                            setState(() => _ideas.removeAt(i)),
                        child: Container(
                          transform: Matrix4.rotationZ(
                              (i.isEven ? 1 : -1) * 0.02),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: idea.color,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  idea.text,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('👍 ${PersianUtils.faDigits('${idea.votes}')}',
                                      style: const TextStyle(fontSize: 12)),
                                  GestureDetector(
                                    onTap: () => setState(() => idea.votes++),
                                    child: const Icon(Icons.thumb_up_outlined,
                                        size: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Idea {
  _Idea({required this.text, required this.color});

  final String text;
  final Color color;
  int votes = 0;
}

/// دیالوگ رأی‌گیری — ذخیره در جدول نظرسنجی (آفلاین)
class _VoteDialog extends ConsumerStatefulWidget {
  const _VoteDialog({required this.pollId, required this.ideas});

  final int pollId;
  final List<_Idea> ideas;

  @override
  ConsumerState<_VoteDialog> createState() => _VoteDialogState();
}

class _VoteDialogState extends ConsumerState<_VoteDialog> {
  int? _choice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رأی‌گیری تیمی'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.ideas.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _choice,
                title: Text(widget.ideas[i].text),
                onChanged: (v) => setState(() => _choice = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف')),
        FilledButton(
          onPressed: _choice == null
              ? null
              : () async {
                  await (await ref.read(databaseProvider).database)
                      .insert('poll_votes', {
                    'poll_id': widget.pollId,
                    'user_id': 1,
                    'option_idx': _choice,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ رأی شما ثبت شد.')));
                    Navigator.pop(context);
                  }
                },
          child: const Text('ثبت رأی'),
        ),
      ],
    );
  }
}
