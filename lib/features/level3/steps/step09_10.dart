import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_utils.dart';
import '../level3_provider.dart';

/// گام ۹ — پیاده‌سازی کامل: سوابق آموزش + تخصیص منابع
class Step9Screen extends ConsumerStatefulWidget {
  const Step9Screen({super.key});

  @override
  ConsumerState<Step9Screen> createState() => _Step9ScreenState();
}

class _Step9ScreenState extends ConsumerState<Step9Screen> {
  Future<void> _addTraining() async {
    final topic = TextEditingController();
    final trainer = TextEditingController();
    final attendee = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سابقه‌ی آموزش'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: topic, decoration: const InputDecoration(labelText: 'موضوع آموزش')),
            TextField(controller: trainer, decoration: const InputDecoration(labelText: 'مدرس')),
            TextField(controller: attendee, decoration: const InputDecoration(labelText: 'شرکت‌کننده(ها)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
        ],
      ),
    );
    if (ok == true && topic.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier).addTraining({
        'topic': topic.text.trim(),
        'trainer': trainer.text,
        'attendee': attendee.text,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
    }
  }

  Future<void> _addResource() async {
    final desc = TextEditingController();
    final amount = TextEditingController();
    var type = 'نیروی انسانی';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('تخصیص منبع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'نیروی انسانی', child: Text('نیروی انسانی')),
                  DropdownMenuItem(value: 'مالی', child: Text('مالی')),
                  DropdownMenuItem(value: 'تجهیزات', child: Text('تجهیزات')),
                ],
                onChanged: (v) => setS(() => type = v ?? 'نیروی انسانی'),
              ),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'شرح')),
              TextField(controller: amount, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مقدار / مبلغ')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
          ],
        ),
      ),
    );
    if (ok == true && desc.text.trim().isNotEmpty) {
      await ref.read(level3WizardProvider.notifier).addResource({
        'type': type,
        'desc': desc.text.trim(),
        'amount': double.tryParse(amount.text) ?? 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('۱) سوابق آموزش', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        OutlinedButton.icon(
            onPressed: _addTraining, icon: const Icon(Icons.school_outlined),
            label: const Text('ثبت آموزش')),
        for (final t in state.trainings)
          ListTile(
            dense: true,
            leading: const Icon(Icons.school, size: 18),
            title: Text('${t['topic']} — ${t['attendee']}'),
            subtitle: Text('مدرس: ${t['trainer']} | ${t['date']}'),
          ),
        if (state.trainings.isEmpty) const Text('آموزشی ثبت نشده است.'),
        const Divider(height: 28),

        Text('۲) تخصیص منابع', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        OutlinedButton.icon(
            onPressed: _addResource, icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('ثبت منبع')),
        for (final r in state.resources)
          ListTile(
            dense: true,
            leading: const Icon(Icons.category, size: 18),
            title: Text('${r['type']}: ${r['desc']}'),
            trailing: Text(PersianUtils.faDigits('${r['amount']}')),
          ),
        if (state.resources.isEmpty) const Text('منبعی تخصیص داده نشده است.'),
      ],
    );
  }
}

/// گام ۱۰ — استانداردسازی: تولید خودکار SOP، مستندات و تاریخ بازنگری
class Step10Screen extends ConsumerStatefulWidget {
  const Step10Screen({super.key});

  @override
  ConsumerState<Step10Screen> createState() => _Step10ScreenState();
}

class _Step10ScreenState extends ConsumerState<Step10Screen> {
  late final TextEditingController _sop;
  final _doc = TextEditingController();
  bool _initialized = false;

  void _init(String text) {
    if (_initialized) return;
    _initialized = true;
    _sop = TextEditingController(text: text);
  }

  @override
  void dispose() {
    if (_initialized) _sop.dispose();
    _doc.dispose();
    super.dispose();
  }

  Future<void> _pickReviewDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      await ref.read(level3WizardProvider.notifier).saveSopL3(reviewDate: date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level3WizardProvider);
    final notifier = ref.read(level3WizardProvider.notifier);
    final theme = Theme.of(context);
    _init(state.sopText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            _sop.text = notifier.autoSopDraft();
            notifier.saveSopL3(text: _sop.text);
          },
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('تولید خودکار پیش‌نویس SOP'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _sop,
          maxLines: 7,
          decoration: const InputDecoration(
              labelText: 'دستورالعمل استاندارد (SOP)',
              hintText: 'پیش‌نویس را ویرایش و نهایی کنید…'),
          onChanged: (v) => notifier.saveSopL3(text: v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickReviewDate,
              icon: const Icon(Icons.event),
              label: const Text('تاریخ بازنگری بعدی'),
            ),
            if (state.sopReviewDate != null) ...[
              const SizedBox(width: 10),
              Text(
                'بازنگری: ${PersianUtils.faDigits(state.sopReviewDate!.toIso8601String().substring(0, 10))}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        const Divider(height: 28),

        Text('مستندات به‌روزشده', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _doc,
                  decoration: const InputDecoration(
                      hintText: 'نام مستند… (مثلاً: نقشه فنی نسخه ۳)')),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_doc.text.trim().isEmpty) return;
                notifier.saveSopL3(doc: _doc.text.trim());
                _doc.clear();
              },
              child: const Text('ثبت'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final d in state.updatedDocs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.description_outlined, size: 18),
            title: Text(d),
          ),
      ],
    );
  }
}
