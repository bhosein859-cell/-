import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/level2_models.dart';
import '../level2_provider.dart';

/// گام ۱: تعریف کامل مسئله — فرم 5W2H + تیم حل مسئله + شاخص‌های پایه (Baseline KPI).
class Step1Definition extends ConsumerStatefulWidget {
  const Step1Definition({super.key});

  @override
  ConsumerState<Step1Definition> createState() => _Step1DefinitionState();
}

class _Step1DefinitionState extends ConsumerState<Step1Definition> {
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final d = ref.read(level2WizardProvider).def;
    _c = {
      'what': TextEditingController(text: d.what),
      'why': TextEditingController(text: d.why),
      'where': TextEditingController(text: d.where),
      'when': TextEditingController(text: d.when),
      'who': TextEditingController(text: d.who),
      'how': TextEditingController(text: d.how),
      'howMuch': TextEditingController(text: d.howMuch),
    };
  }

  @override
  void dispose() {
    _c.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _saveDef() {
    ref.read(level2WizardProvider.notifier).saveDefinition(Definition5W2H(
          what: _c['what']!.text,
          why: _c['why']!.text,
          where: _c['where']!.text,
          when: _c['when']!.text,
          who: _c['who']!.text,
          how: _c['how']!.text,
          howMuch: _c['howMuch']!.text,
        ));
  }

  static const List<Map<String, String>> _fields = [
    {'key': 'what', 'fa': 'چه چیزی؟ (What)', 'hint': 'شرح دقیق مسئله…'},
    {'key': 'why', 'fa': 'چرا؟ (Why)', 'hint': 'چرا مسئله مهم است…'},
    {'key': 'where', 'fa': 'کجا؟ (Where)', 'hint': 'محل بروز…'},
    {'key': 'when', 'fa': 'چه زمانی؟ (When)', 'hint': 'زمان/تناوب بروز…'},
    {'key': 'who', 'fa': 'چه کسی؟ (Who)', 'hint': 'افراد درگیر…'},
    {'key': 'how', 'fa': 'چگونه؟ (How)', 'hint': 'چگونه بروز می‌کند…'},
    {'key': 'howMuch', 'fa': 'چقدر؟ (How Much)', 'hint': 'شدت/هزینه…'},
  ];

  Future<void> _addTeam() async {
    final name = TextEditingController();
    String role = 'member';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('افزودن عضو تیم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: role,
              items: [
                for (final e in TeamMember.roleFa.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => role = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('افزودن')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref
          .read(level2WizardProvider.notifier)
          .addTeamMember(TeamMember(name: name.text.trim(), role: role));
    }
  }

  Future<void> _addKpi() async {
    final name = TextEditingController();
    final unit = TextEditingController();
    final baseline = TextEditingController();
    final target = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شاخص پایه (Baseline KPI)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام شاخص')),
            TextField(controller: unit, decoration: const InputDecoration(labelText: 'واحد (٪، عدد، دقیقه…)')),
            TextField(controller: baseline, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مقدار فعلی (قبل از اقدام)')),
            TextField(controller: target, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'هدف (اختیاری)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(level2WizardProvider.notifier).addKpi(Kpi(
            name: name.text.trim(),
            unit: unit.text,
            baseline: double.tryParse(baseline.text),
            target: double.tryParse(target.text),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── فرم 5W2H ──
        Text('تعریف کامل مسئله (5W2H)',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final f in _fields)
                SizedBox(
                  width: c.maxWidth > 700 ? (c.maxWidth - 28) / 2 : c.maxWidth,
                  child: TextField(
                    controller: _c[f['key']],
                    onChanged: (_) => _saveDef(), // ذخیره‌ی خودکار
                    maxLines: f['key'] == 'what' ? 2 : 1,
                    decoration: InputDecoration(labelText: f['fa'], hintText: f['hint']),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        // ── تیم حل مسئله ──
        Row(
          children: [
            Text('تیم حل مسئله',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            FilledButton.icon(
                onPressed: _addTeam,
                icon: const Icon(Icons.group_add),
                label: const Text('افزودن عضو')),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < state.team.length; i++)
              Chip(
                avatar: CircleAvatar(
                    backgroundColor: AppColors.navyBlue,
                    child: const Icon(Icons.person, size: 16, color: Colors.white)),
                label: Text(
                    '${state.team[i].name} • ${TeamMember.roleFa[state.team[i].role]}'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () =>
                    ref.read(level2WizardProvider.notifier).removeTeamMember(i),
              ),
            if (state.team.isEmpty)
              const Text('هنوز عضوی اضافه نشده؛ یک تیم چندنقشی بسازید.'),
          ],
        ),
        const SizedBox(height: 26),

        // ── شاخص‌های پایه ──
        Row(
          children: [
            Text('شاخص‌های اولیه (Baseline KPI)',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            FilledButton.icon(
                onPressed: _addKpi,
                icon: const Icon(Icons.monitor_heart_outlined),
                label: const Text('افزودن شاخص')),
          ],
        ),
        const SizedBox(height: 10),
        if (state.kpis.isEmpty)
          const Text('شاخصی ثبت نشده؛ بدون شاخص پایه، بهبود قابل اندازه‌گیری نیست.'),
        for (var i = 0; i < state.kpis.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_outlined, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${state.kpis[i].name} — مقدار فعلی: ${state.kpis[i].baseline ?? '—'} ${state.kpis[i].unit}'
                    '${state.kpis[i].target != null ? ' | هدف: ${state.kpis[i].target}' : ''}',
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ref.read(level2WizardProvider.notifier).removeKpi(i)),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
