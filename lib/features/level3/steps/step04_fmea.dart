import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../level3_provider.dart';
import '../widgets/fmea_widget.dart';

/// گام ۴ — جدول پیش‌بینی حالت‌ها و اثرات خرابی (FMEA)
class Step4Screen extends ConsumerWidget {
  const Step4Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level3WizardProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RPN به‌صورت خودکار محاسبه می‌شود (شدت × وقوع × شناسایی). '
          'حالات با RPN بالا (۱۰۰≤) بحرانی هستند و اقدام اصلاحی پیشنهادی دریافت می‌کنند.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        FmeaWidget(key: ValueKey(state.problemId)),
      ],
    );
  }
}
