import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../providers/theme_provider.dart';
import '../../services/psp_archive_service.dart';

/// صفحه‌ی «تنظیمات» — حالت نمایش، زبان، پشتیبان‌گیری و بازیابی (.psp).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  /// اجرای عملیات .psp با نمایش وضعیت و پیام نتیجه.
  Future<void> _runPsp(Future<PspResult> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await operation();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.success ? null : Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنظیمات',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),

                // ── حالت نمایش ──
                _Section(
                  title: 'ظاهر برنامه',
                  icon: Icons.dark_mode_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حالت نمایش',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('سیستم'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('روز'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('شب'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) => ref
                            .read(themeModeProvider.notifier)
                            .setMode(selection.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── زبان ──
                _Section(
                  title: 'زبان',
                  icon: Icons.translate,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check_circle,
                            color: Color(0xFF10B981)),
                        title: const Text('فارسی'),
                        subtitle: const Text('زبان پیش‌فرض — راست‌به‌چپ'),
                        dense: true,
                      ),
                      ListTile(
                        leading: Icon(Icons.circle_outlined,
                            color: theme.colorScheme.onSurfaceVariant),
                        title: const Text('English'),
                        subtitle: const Text('در نقشه‌ی راه — به‌زودی'),
                        dense: true,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── پشتیبان‌گیری و بازیابی ──
                _Section(
                  title: 'پشتیبان‌گیری و بازیابی',
                  icon: Icons.backup_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فایل پروژه‌ی «.psp» شامل دیتابیس کامل، همه‌ی پیوست‌ها و '
                        'متادیتای نسخه است؛ به‌راحتی بین ویندوز و اندروید جابه‌جا می‌شود.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(),
                        ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _runPsp(
                                    ref.read(pspServiceProvider).exportProject),
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text('خروجی فایل پروژه (.psp)'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _runPsp(
                                    ref.read(pspServiceProvider).importProject),
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('بازیابی از فایل (.psp)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// کارت بخش تنظیمات.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
