import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// ماشین زمان (Time Machine)
/// پخش مجدد مراحل حل مسئله به صورت ترتیبی: با حرکت اسلایدر، وضعیت
/// پروژه (رویدادها، اقدامات انجام‌شده، پیوست‌ها) در هر لحظه دیده می‌شود.
/// منبع داده: جدول لاگ تغییرات (audit_trail) — کاملاً آفلاین.
/// ═══════════════════════════════════════════════════════════════
class TimeMachineScreen extends ConsumerStatefulWidget {
  const TimeMachineScreen({super.key, required this.problemId});

  final int problemId;

  @override
  ConsumerState<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends ConsumerState<TimeMachineScreen> {
  List<_Event> _events = [];
  String _title = '';
  double _t = 0; // موقعیت اسلایدر: ایندکس رویداد
  Timer? _player;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _player?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final p = await db.query('problems',
        columns: ['title'], where: 'id = ?', whereArgs: [widget.problemId]);
    final rows = await db.query('audit_trail',
        where: 'problem_id = ?',
        whereArgs: [widget.problemId],
        orderBy: 'created_at ASC, id ASC');

    final events = <_Event>[];
    for (final r in rows) {
      events.add(_Event(
        at: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        action: r['action'] as String? ?? '',
        entity: r['entity_type'] as String? ?? '',
        details: r['details'] as String? ?? '',
      ));
    }
    // اگر لاگ خالی بود، دست‌کم نقطه‌ی ایجاد پروژه را بساز
    if (events.isEmpty && p.isNotEmpty) {
      final created = await db.query('problems',
          columns: ['created_at'],
          where: 'id = ?',
          whereArgs: [widget.problemId]);
      events.add(_Event(
        at: DateTime.tryParse(created.first['created_at'] as String? ?? '') ??
            DateTime.now(),
        action: 'create',
        entity: 'problem',
        details: 'ایجاد پروژه',
      ));
    }
    setState(() {
      _title = p.isEmpty ? '' : p.first['title'] as String? ?? '';
      _events = events;
      _t = events.isEmpty ? 0 : (events.length - 1).toDouble();
    });
  }

  void _togglePlay() {
    if (_playing) {
      _player?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_t >= (_events.length - 1)) _t = 0;
    setState(() => _playing = true);
    _player = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_t >= (_events.length - 1)) {
        timer.cancel();
        if (mounted) setState(() => _playing = false);
        return;
      }
      setState(() => _t += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = _t.round().clamp(0, _events.isEmpty ? 0 : _events.length - 1);
    final visible = _events.take(idx + 1).toList();
    final createdAt = _events.isEmpty ? null : _events.first.at;
    final doneActions =
        visible.where((e) => e.action == 'action_done').length;

    return Scaffold(
      appBar: AppBar(title: Text('ماشین زمان — $_title')),
      body: _events.isEmpty
          ? const Center(child: Text('رویدادی برای این پروژه ثبت نشده است.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── نمای وضعیت در لحظه‌ی انتخابی ──
                  Card(
                    color: AppColors.navyBlue.withValues(alpha: .05),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('لحظه', _events[idx].at),
                          _statCount('رویداد تا اینجا', visible.length),
                          _statCount('اقدام تکمیل‌شده', doneActions),
                          _statCount(
                              'روز از شروع',
                              createdAt == null
                                  ? 0
                                  : _events[idx].at.difference(createdAt).inDays),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── کنترل‌های پخش ──
                  Row(
                    children: [
                      IconButton.filled(
                        tooltip: _playing ? 'توقف' : 'پخش',
                        onPressed: _togglePlay,
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      ),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: (_events.length - 1).toDouble(),
                          divisions: _events.length - 1 < 1
                              ? null
                              : _events.length - 1,
                          value: _t,
                          label: 'رویداد ${PersianUtils.faDigits('${idx + 1}')}',
                          onChanged: (v) {
                            _player?.cancel();
                            setState(() {
                              _t = v;
                              _playing = false;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${PersianUtils.faDigits('${idx + 1}')}/'
                        '${PersianUtils.faDigits('${_events.length}')}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Divider(),

                  // ── خط زمانی رویدادها تا لحظه‌ی انتخابی ──
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final e = visible[visible.length - 1 - i];
                        final isCurrent = e == _events[idx];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent
                                ? AppColors.orange
                                : AppColors.navyBlue.withValues(alpha: .12),
                            child: Icon(_iconOf(e.action),
                                size: 14,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.navyBlue),
                          ),
                          title: Text(_labelOf(e),
                              style: TextStyle(
                                  fontWeight:
                                      isCurrent ? FontWeight.w800 : null)),
                          subtitle: Text(PersianUtils.faDateTime(e.at)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stat(String label, DateTime d) => Column(
        children: [
          Text(PersianUtils.faDateTime(d),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  Widget _statCount(String label, int v) => Column(
        children: [
          Text(PersianUtils.faDigits('$v'),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 20,
                  color: AppColors.navyBlue)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      );

  IconData _iconOf(String action) => switch (action) {
        'create' => Icons.flag_outlined,
        'update' => Icons.edit_outlined,
        'delete' => Icons.delete_outline,
        'action_done' => Icons.check_circle_outline,
        'export_psp' => Icons.file_download_outlined,
        'import_psp' => Icons.file_upload_outlined,
        _ => Icons.history,
      };

  String _labelOf(_Event e) => switch (e.action) {
        'create' => 'ایجاد ${_entityFa(e.entity)}',
        'update' => 'به‌روزرسانی ${_entityFa(e.entity)}',
        'delete' => 'حذف ${_entityFa(e.entity)}',
        'action_done' => 'تکمیل اقدام',
        'export_psp' => 'خروجی فایل .psp',
        'import_psp' => 'ورود فایل .psp',
        _ => e.action,
      };

  String _entityFa(String e) => switch (e) {
        'problem' => 'مسئله',
        'action' => 'اقدام',
        'attachment' => 'پیوست',
        'kb' => 'بانک دانش',
        _ => 'مورد',
      };
}

class _Event {
  const _Event({
    required this.at,
    required this.action,
    required this.entity,
    required this.details,
  });

  final DateTime at;
  final String action;
  final String entity;
  final String details;
}
