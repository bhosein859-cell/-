import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../level1_provider.dart';
import '../level1_state.dart';

/// مرحله ۱: ثبت مشکل — عنوان، توضیح، محل، اولویت و پیوست تصویر.
///
/// اصل سادگی: فیلدهای کم، دکمه‌های بزرگ.
class Step1ProblemForm extends ConsumerStatefulWidget {
  const Step1ProblemForm({super.key});

  @override
  ConsumerState<Step1ProblemForm> createState() => _Step1ProblemFormState();
}

class _Step1ProblemFormState extends ConsumerState<Step1ProblemForm> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null) {
        ref.read(level1WizardProvider.notifier).update(
              (s) => s.copyWith(
                pendingAttachments: [...s.pendingAttachments, picked],
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('دسترسی به تصویر ممکن نشد: $e')),
        );
      }
    }
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
              // ── عنوان ─
              Text('مشکل چه بود؟',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.title,
                onChanged: (v) => notifier.update((s) => s.copyWith(title: v)),
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'مثلاً: نشتی کوچک روغن از دستگاه پرس',
                ),
              ),
              const SizedBox(height: 20),

              // ── توضیح کوتاه ──
              Text('توضیح کوتاه (اختیاری)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.description,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(description: v)),
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'یک جمله کافی است.'),
              ),
              const SizedBox(height: 20),

              // ── محل / دپارتمان ──
              Text('محل / دپارتمان',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: state.location,
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(location: v)),
                decoration: const InputDecoration(hintText: 'مثلاً: خط تولید ۲'),
              ),
              const SizedBox(height: 20),

              // ── اولویت ──
              Text('اولویت',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.priority,
                items: [
                  for (final e in Level1Priorities.faLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) {
                  if (v != null) notifier.update((s) => s.copyWith(priority: v));
                },
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 24),

              // ── پیوست تصویر ──
              Text('عکس مشکل (اختیاری)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // نمایش عکس‌های انتخاب‌شده
                  for (final x in state.pendingAttachments)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(x.path),
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          left: 2, // در RTL گوشه‌ی بیرونی
                          child: GestureDetector(
                            onTap: () => notifier.update((s) => s.copyWith(
                                pendingAttachments: s.pendingAttachments
                                    .where((e) => e.path != x.path)
                                    .toList())),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: AppColors.level3,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // دکمه‌های افزودن: دوربین فقط در اندروید
                  if (Platform.isAndroid)
                    _PickTile(
                      icon: Icons.photo_camera,
                      label: 'دوربین',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  _PickTile(
                    icon: Icons.photo_library_outlined,
                    label: Platform.isAndroid ? 'گالری' : 'انتخاب تصویر',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

/// دکمه‌ی بزرگ انتخاب پیوست
class _PickTile extends StatelessWidget {
  const _PickTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: .35),
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}
