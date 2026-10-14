import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

/// صفحه‌ی «بانک دانش» — آرشیو راه‌حل‌های مسائل حل‌شده.
/// فاز صفر: حالت خالی.
class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'بانک دانش خالی است',
            subtitle:
                'راه‌حل هر مسئله‌ی حل‌شده به‌صورت خودکار به اینجا منتقل می‌شود\nتا در آینده، گره‌های مشابه را سریع‌تر باز کنید.',
          ),
        ),
      ],
    );
  }
}
