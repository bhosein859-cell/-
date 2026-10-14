import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../level3_provider.dart';
import '../widgets/stat_charts.dart';

/// گام ۳ — تحلیل آماری پیشرفته: هیستوگرام، نمودار کنترل، پراکندگی و
/// جعبه‌ای + ایمپورت داده از Excel.
class Step3Screen extends ConsumerWidget {
  const Step3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تحلیل آماری تصمیم‌ها را بر پایه داده قرار می‌دهد؛ '
          'نمودار مناسب را انتخاب، داده‌ها را وارد یا از Excel ایمپورت کنید.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        StatAnalysisPanel(key: ValueKey(state.problemId)),
      ],
    );
  }
}
