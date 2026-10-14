import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_utils.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/attachment.dart';
import '../../../data/repositories/problem_repository.dart';
import '../level2_provider.dart';

/// گام ۷: استانداردسازی — ثبت SOP، پیوست فایل دستورالعمل، تاریخ بازبینی بعدی.
class Step7Standardization extends ConsumerStatefulWidget {
  const Step7Standardization({super.key});

  @override
  ConsumerState<Step7Standardization> createState() => _Step7StandardizationState();
}

class _Step7StandardizationState extends ConsumerState<Step7Standardization> {
  late final TextEditingController _sop;

  @override
  void initState() {
    super.initState();
    _sop = TextEditingController(text: ref.read(level2WizardProvider).sopText);
  }

  @override
  void dispose() {
    _sop.dispose();
    super.dispose();
  }

  Future<void> _attachSopFile() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'پیوست دستورالعمل (SOP)',
      type: FileType.any,
    );
    if (picked == null || picked.files.single.path == null) return;

    final source = File(picked.files.single.path!);
    final dir = await DatabaseHelper.instance.attachmentsDir;
    final storedName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source.path)}';
    await source.copy(p.join(dir.path, storedName));

    final state = ref.read(level2WizardProvider);
    await ref.read(problemRepositoryProvider).insertAttachment(Attachment(
          problemId: state.problemId!,
          fileName: p.basename(source.path),
          filePath: storedName,
          uploadedBy: 1,
        ));
    await ref.read(level2WizardProvider.notifier).saveSop(attachmentName: p.basename(source.path));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('دستورالعمل پیوست شد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(level2WizardProvider);
    final notifier = ref.read(level2WizardProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('استانداردسازی — دستورالعمل جدید (SOP)',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('راه‌حل موفق را به یک دستورالعمل دائمی تبدیل کنید تا مشکل تکرار نشود.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextField(
                controller: _sop,
                maxLines: 8,
                onChanged: (v) => notifier.saveSop(text: v), // ذخیره خودکار
                decoration: const InputDecoration(
                  hintText: 'متن دستورالعمل جدید: مراحل کار، مسئولین، نکات کنترلی…',
                ),
              ),
              const SizedBox(height: 16),

              // پیوست فایل SOP
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _attachSopFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('پیوست فایل دستورالعمل'),
                  ),
                  if (state.sopAttachmentName != null)
                    Chip(
                      avatar: const Icon(Icons.description, size: 16, color: AppColors.orange),
                      label: Text(state.sopAttachmentName!),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // تاریخ بازبینی بعدی
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat, color: AppColors.navyBlue),
                title: const Text('تاریخ بازبینی بعدی استاندارد'),
                subtitle: Text(
                  state.sopReviewDate == null
                      ? 'تعیین نشده'
                      : PersianUtils.faDate(state.sopReviewDate!),
                ),
                trailing: OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: state.sopReviewDate ??
                          DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) await notifier.saveSop(reviewDate: d);
                  },
                  child: const Text('انتخاب تاریخ'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
