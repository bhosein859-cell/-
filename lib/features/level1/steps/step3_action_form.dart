import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_utils.dart';
import '../level1_provider.dart';

/// مرحله ۳: اقدام فوری — چه کاری انجام شد؟ چه کسی؟ چه زمانی؟ + وضعیت.
class Step3ActionForm extends ConsumerStatefulWidget {
  const Step3ActionForm({super.key});

  @override
  ConsumerState<Step3ActionForm> createState() => _Step3ActionFormState();
}

class _Step3ActionFormState extends ConsumerState<Step3ActionForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _byController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(level1WizardProvider);
    _titleController = TextEditingController(text: s.actionTitle);
    _byController = TextEditingController(text: s.actionBy);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _byController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level1WizardProvider);
    final notifier = ref.read(level1WizardProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اقدام فوری',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'برای حل این مشکل چه کاری انجام شد (یا در حال انجام است)؟',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              // ── چه کاری انجام شد؟ ──
              Text('چه کاری انجام شد؟',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(actionTitle: v)),
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'مثلاً: واشر تعویض و اتصال محکم شد'),
              ),
              const SizedBox(height: 20),

              // ── چه کسی انجام داد؟ ──
              Text('چه کسی انجام داد؟',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(
                controller: _byController,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(actionBy: v)),
                decoration:
                    const InputDecoration(hintText: 'نام انجام‌دهنده'),
              ),
              const SizedBox(height: 20),

              // ── چه زمانی؟ ──
              Text('چه زمانی؟',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: .3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      PersianUtils.faDateTime(state.actionAt),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => notifier.update(
                          (s) => s.copyWith(actionAt: DateTime.now())),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('اکنون'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── وضعیت اقدام ──
              Text('وضعیت اقدام',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'in_progress',
                    label: Text('در حال انجام'),
                    icon: Icon(Icons.hourglass_top),
                  ),
                  ButtonSegment(
                    value: 'done',
                    label: Text('انجام شد'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {state.actionStatus},
                onSelectionChanged: (sel) => notifier
                    .update((s) => s.copyWith(actionStatus: sel.first)),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}
