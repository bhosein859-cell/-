import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// ابزارهای سفارشی کاربر (Custom Wizards)
/// ویرایشگر بصری برای ساخت ویزارد حل مسئله‌ی اختصاصی هر صنعت؛
/// مراحل و نوع ابزار هر مرحله را کاربر تعریف می‌کند و در دیتابیس
/// ذخیره و برای استفاده‌ی مجدد در دسترس است.
/// ═══════════════════════════════════════════════════════════════
class CustomWizardScreen extends ConsumerStatefulWidget {
  const CustomWizardScreen({super.key});

  @override
  ConsumerState<CustomWizardScreen> createState() => _CustomWizardScreenState();
}

class _CustomWizardScreenState extends ConsumerState<CustomWizardScreen> {
  List<Map<String, Object?>> _wizards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final rows = await db.query('custom_wizards', orderBy: 'id DESC');
    setState(() {
      _wizards = rows;
      _loading = false;
    });
  }

  Future<void> _openEditor([Map<String, Object?>? existing]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _WizardEditorScreen(existing: existing),
      ),
    );
    await _load();
  }

  Future<void> _play(Map<String, Object?> w) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _WizardPlayerScreen(wizard: w)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧰 ویزاردهای سفارشی'),
        actions: [
          IconButton(
            tooltip: 'ویزارد جدید',
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wizards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.build_circle_outlined,
                          size: 64, color: Colors.black26),
                      const SizedBox(height: 10),
                      const Text('ویزاردی نساخته‌اید؛ برای صنعت خودتان یکی بسازید.'),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('ساخت اولین ویزارد'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _wizards.length,
                  itemBuilder: (context, i) {
                    final w = _wizards[i];
                    final steps = jsonDecode(w['steps_json'] as String? ?? '[]')
                        as List;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_tree_outlined,
                            color: AppColors.navyBlue),
                        title: Text(w['name'] as String? ?? ''),
                        subtitle: Text(
                            '${(w['industry'] as String?) ?? 'عمومی'} • '
                            '${PersianUtils.faDigits('${steps.length}')} مرحله'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'اجرا',
                              icon: const Icon(Icons.play_circle_outline,
                                  color: AppColors.success),
                              onPressed: () => _play(w),
                            ),
                            IconButton(
                              tooltip: 'ویرایش',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditor(w),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// ویرایشگر بصری مراحل
class _WizardEditorScreen extends ConsumerStatefulWidget {
  const _WizardEditorScreen({this.existing});

  final Map<String, Object?>? existing;

  @override
  ConsumerState<_WizardEditorScreen> createState() => _WizardEditorScreenState();
}

class _WizardEditorScreenState extends ConsumerState<_WizardEditorScreen> {
  final _name = TextEditingController();
  final _industry = TextEditingController();
  final List<Map<String, dynamic>> _steps = [];

  static const Map<String, String> _tools = {
    'text': 'شرح متنی',
    'checklist': 'چک‌لیست',
    'why': 'تحلیل چرا',
    'fishbone': 'استخوان‌ماهی',
    'kpi': 'شاخص‌ها',
    'sketch': 'ترسیم دستی',
  };

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _name.text = widget.existing!['name'] as String? ?? '';
      _industry.text = widget.existing!['industry'] as String? ?? '';
      final steps = jsonDecode(
          widget.existing!['steps_json'] as String? ?? '[]') as List;
      _steps.addAll(steps.map((s) => Map<String, dynamic>.from(s as Map)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    super.dispose();
  }

  void _addStep() {
    setState(() => _steps.add({'title': '', 'tool': 'text'}));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('نام ویزارد الزامی است.')));
      return;
    }
    final db = await ref.read(databaseProvider).database;
    final values = {
      'name': _name.text.trim(),
      'industry': _industry.text.trim(),
      'steps_json': jsonEncode(_steps),
    };
    if (widget.existing == null) {
      await db.insert('custom_wizards', values);
    } else {
      await db.update('custom_wizards', values,
          where: 'id = ?', whereArgs: [widget.existing!['id']]);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'ویزارد جدید'
            : 'ویرایش «${widget.existing!['name']}»'),
        actions: [
          FilledButton.icon(
              onPressed: _save, icon: const Icon(Icons.save), label: const Text('ذخیره')),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name,
              decoration: const InputDecoration(labelText: 'نام ویزارد')),
          const SizedBox(height: 10),
          TextField(controller: _industry,
              decoration: const InputDecoration(labelText: 'صنعت (مثلاً نفت و گاز)')),
          const Divider(height: 28),
          Row(
            children: [
              Text('مراحل (${PersianUtils.faDigits('${_steps.length}')})',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              OutlinedButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('افزودن مرحله')),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _steps.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.navyBlue,
                            child: Text(PersianUtils.faDigits('${i + 1}'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                                labelText: 'عنوان مرحله', isDense: true),
                            controller: TextEditingController(
                                text: _steps[i]['title'] as String? ?? ''),
                            onChanged: (v) => _steps[i]['title'] = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.level3),
                          onPressed: () => setState(() => _steps.removeAt(i)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _steps[i]['tool'] as String? ?? 'text',
                      decoration: const InputDecoration(labelText: 'ابزار مرحله'),
                      items: [
                        for (final e in _tools.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged: (v) =>
                          setState(() => _steps[i]['tool'] = v ?? 'text'),
                    ),
                  ],
                ),
              ),
            ),
          if (_steps.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('حداقل یک مرحله تعریف کنید.'),
            )),
        ],
      ),
    );
  }
}

/// اجرای ویزارد سفارشی — گام‌به‌گام با ذخیره‌ی پاسخ‌ها
class _WizardPlayerScreen extends ConsumerStatefulWidget {
  const _WizardPlayerScreen({required this.wizard});

  final Map<String, Object?> wizard;

  @override
  ConsumerState<_WizardPlayerScreen> createState() => _WizardPlayerScreenState();
}

class _WizardPlayerScreenState extends ConsumerState<_WizardPlayerScreen> {
  late final List<Map<String, dynamic>> _steps;
  final Map<int, String> _answers = {};
  int _idx = 0;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _steps = List<Map<String, dynamic>>.from(
        (jsonDecode(widget.wizard['steps_json'] as String? ?? '[]') as List)
            .map((s) => Map<String, dynamic>.from(s as Map)));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _next() {
    _answers[_idx] = _input.text;
    _input.clear();
    if (_idx < _steps.length - 1) {
      setState(() {
        _idx++;
        _input.text = _answers[_idx] ?? '';
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final db = await ref.read(databaseProvider).database;
    await db.insert('problems', {
      'title': '${widget.wizard['name']} — اجرای جدید',
      'level': 1,
      'status': 'open',
      'priority': 'medium',
      'owner_id': 1,
      'created_by': 1,
      'metadata': jsonEncode({
        'custom_wizard_id': widget.wizard['id'],
        'wizard_answers': _answers,
      }),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ پاسخ‌ها در مسئله‌ی جدید ثبت شد.')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_idx];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wizard['name'] as String? ?? ''),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_idx + 1) / _steps.length,
            color: AppColors.orange,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مرحله ${PersianUtils.faDigits('${_idx + 1}')} از '
                '${PersianUtils.faDigits('${_steps.length}')}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 8),
            Text(step['title'] as String? ?? 'مرحله',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: switch (step['tool'] as String? ?? 'text') {
                  'checklist' => 'موارد چک‌لیست (هر مورد در یک خط)',
                  'why' => 'پاسخ «چرا؟»',
                  'kpi' => 'مقدار شاخص',
                  'sketch' => 'توضیح ترسیم (ترسیم کامل از اتاق ابزار)',
                  _ => 'توضیحات این مرحله',
                },
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (_idx > 0)
                  OutlinedButton(
                    onPressed: () {
                      _answers[_idx] = _input.text;
                      _input.clear();
                      setState(() {
                        _idx--;
                        _input.text = _answers[_idx] ?? '';
                      });
                    },
                    child: const Text('قبلی'),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _next,
                  icon: Icon(_idx == _steps.length - 1
                      ? Icons.flag
                      : Icons.arrow_back),
                  iconAlignment: IconAlignment.end,
                  label: Text(_idx == _steps.length - 1 ? 'پایان' : 'بعدی'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
