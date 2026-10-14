import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models/level2_models.dart';
import '../../data/models/level3_models.dart';
import '../level3_state.dart';
import '../level3_provider.dart';

/// گام ۱ — تعریف مسئله + تیم پروژه + بحرانیت + شاخص‌های پایه
class Step1Screen extends ConsumerStatefulWidget {
  const Step1Screen({super.key});

  @override
  ConsumerState<Step1Screen> createState() => _Step1ScreenState();
}

class _Step1ScreenState extends ConsumerState<Step1Screen> {
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final d = ref.read(level3WizardProvider).def;
    _c = {
      'what': TextEditingController(text: d.what),
      'why': TextEditingController(text: d.why),
      'who': TextEditingController(text: d.who),
      'where': TextEditingController(text: d.where),
      'when': TextEditingController(text: d.when),
      'how': TextEditingController(text: d.how),
      'howMuch': TextEditingController(text: d.howMuch),
    };
  }

  @override
  void dispose() {
    _c.values.forEach((x) => x.dispose());
    super.dispose();
  }

  void _saveDefinition() {
    ref.read(level3WizardProvider.notifier).saveBasics(
          def: Definition5W2H(
            what: _c['what']!.text,
            why: _c['why']!.text,
            who: _c['who']!.text,
            where: _c['where']!.text,
            when: _c['when']!.text,
            how: _c['how']!.text,
            howMuch: _c['howMuch']!.text,
          ),
        );
  }

  Future<void> _addTeam() async {
    final name = TextEditingController();
    var role = 'leader';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('عضو جدید تیم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name,
                  decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                items: [
                  for (final e in TeamRoleL3.fa.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setS(() => role = v ?? 'leader'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('افزودن')),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier).addTeamMemberL3(
            TeamMemberL3(
                problemId: ref.read(level3WizardProvider).problemId!,
                name: name.text.trim(),
                role: role),
          );
    }
  }

  Future<void> _addKpi() async {
    final name = TextEditingController();
    final unit = TextEditingController();
    final value = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شاخص کلیدی پایه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'نام شاخص')),
            TextField(controller: unit, decoration: const InputDecoration(labelText: 'واحد')),
            TextField(controller: value, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مقدار فعلی')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier).addKpiL3(Kpi(
            name: name.text.trim(),
            unit: unit.text,
            baseline: double.tryParse(value.text),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    const fields = [
      ('what', 'چه چیزی؟ (What)', 'شرح دقیق مشکل…'),
      ('why', 'چرا؟ (Why)', 'چرا این مسئله اهمیت دارد؟'),
      ('who', 'چه کسی؟ (Who)', 'چه کسانی درگیر هستند؟'),
      ('where', 'کجا؟ (Where)', 'کجا رخ می‌دهد؟'),
      ('when', 'چه زمانی؟ (When)', 'از چه زمانی / در چه شیفتی؟'),
      ('how', 'چگونه؟ (How)', 'چگونه آشکار می‌شود؟'),
      ('howMuch', 'چقدر؟ (How Much)', 'حجم و شدت مشکل؟'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تعریف مسئله با 5W2H', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        ...fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _c[f.$1],
                decoration: InputDecoration(labelText: f.$2, hintText: f.$3),
                onChanged: (_) {},
              ),
            )),
        FilledButton.tonal(
          onPressed: _saveDefinition,
          child: const Text('ذخیره تعریف مسئله'),
        ),
        const Divider(height: 30),

        // بحرانیت
        Text('درجه بحرانیت: ${PersianUtils.faDigits('${state.criticality}')} از ۵',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: state.criticality.toDouble(),
          activeColor: state.criticality >= 4 ? AppColors.level3 : AppColors.orange,
          label: PersianUtils.faDigits('${state.criticality}'),
          onChanged: (v) =>
              notifier.saveBasics(criticality: v.round()),
        ),
        const Divider(height: 30),

        // تیم
        Row(
          children: [
            Text('تیم پروژه (${PersianUtils.faDigits('${state.team.length}')} نفر)',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            OutlinedButton.icon(
                onPressed: _addTeam, icon: const Icon(Icons.person_add_alt),
                label: const Text('افزودن عضو')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in state.team)
              Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text('${t.name} — ${TeamRoleL3.fa[t.role] ?? t.role}'),
                onDeleted: () => notifier.removeTeamMemberL3(t.id!),
              ),
            if (state.team.isEmpty) const Text('هنوز عضوی اضافه نشده است.'),
          ],
        ),
        const Divider(height: 30),

        // شاخص‌ها
        Row(
          children: [
            Text('شاخص‌های کلیدی پایه',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            OutlinedButton.icon(
                onPressed: _addKpi, icon: const Icon(Icons.add),
                label: const Text('افزودن شاخص')),
          ],
        ),
        const SizedBox(height: 8),
        for (final k in state.kpis)
          ListTile(
            dense: true,
            leading: const Icon(Icons.speed, size: 18),
            title: Text('${k.name} (${k.unit})'),
            trailing: Text(PersianUtils.faDigits(
                (k.baseline ?? 0).toStringAsFixed(2))),
          ),
      ],
    );
  }
}

/// گام ۲ — اقدامات مهار + گیت سخت تایید مدیر
class Step2Screen extends ConsumerStatefulWidget {
  const Step2Screen({super.key});

  @override
  ConsumerState<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends ConsumerState<Step2Screen> {
  final _title = TextEditingController();
  final _approver = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _approver.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_title.text.trim().isEmpty) return;
    await ref.read(level3WizardProvider.notifier).addContainment(
          ContainmentAction(
            title: _title.text.trim(),
            start: DateTime.now(),
          ),
        );
    _title.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اقدام مهار، پاسخی فوری و موقت است تا از گسترش آسیب جلوگیری کند؛ '
          'ریشه‌یابی در گام‌های بعد انجام می‌شود.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: 'شرح اقدام مهار… (مثلاً: قرنطینه محموله معیوب)'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('ثبت')),
          ],
        ),
        const SizedBox(height: 10),
        for (final c in state.containment)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: Icon(
                c.approved ? Icons.check_circle : Icons.schedule,
                color: c.approved ? AppColors.success : AppColors.orange,
              ),
              title: Text(c.title),
              subtitle: Text(c.approved
                  ? 'تایید اثربخشی توسط ${c.approvedBy ?? 'مدیر'}'
                  : 'در انتظار تایید مدیر'),
            ),
          ),
        const Divider(height: 28),

        // گیت سخت: تایید مدیر
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: state.containmentApproved
                ? AppColors.success.withValues(alpha: .08)
                : AppColors.level3.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: state.containmentApproved
                    ? AppColors.success
                    : AppColors.level3.withValues(alpha: .5)),
          ),
          child: state.containmentApproved
              ? Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اثربخشی اقدامات مهار توسط مدیر تایید شد ✓ — می‌توانید ادامه دهید.',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.success.shade700),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.level3),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'گیت اجباری: تا زمانی که مدیر اثربخشی اقدامات مهار را تایید نکند، '
                            'ورود به گام تحلیل آماری ممکن نیست.',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: AppColors.level3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _approver,
                            decoration: const InputDecoration(
                                labelText: 'نام مدیر تاییدکننده', hintText: 'مثلاً: مهندس رضایی'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success),
                          onPressed: state.containment.isEmpty
                              ? null
                              : () => notifier
                                  .approveContainment(_approver.text.trim().isEmpty
                                      ? 'مدیر'
                                      : _approver.text.trim()),
                          icon: const Icon(Icons.thumb_up),
                          label: const Text('تایید اثربخشی'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
