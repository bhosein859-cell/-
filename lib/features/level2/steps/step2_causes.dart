import 'package:flutter/material.dart';

import '../widgets/fishbone_widget.dart';
import '../widgets/pareto_widget.dart';

/// گام ۲: تحلیل علل — استخوان‌ماهی تعاملی + نمودار پارتو.
class Step2Causes extends StatelessWidget {
  const Step2Causes({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('تحلیل علل (استخوان‌ماهی 6M)',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'روی هر شاخه کلیک کنید تا زیرشاخه اضافه شود؛ زیرشاخه‌ها را با لمس طولانی و کشیدن جابه‌جا کنید. برای زوم، دو انگشت (یا چرخ ماوس در دسکتاپ).',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        const FishboneWidget(),
        const Divider(height: 40),
        Text('نمودار پارتو — اولویت‌بندی علل (قانون ۸۰/۲۰)',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        const ParetoWidget(),
      ],
    );
  }
}
