import 'package:flutter/material.dart';

import '../../core/utils/persian_utils.dart';

/// کارت انتخاب سطح مسئله در ویزارد «مشکل جدید».
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.color,
    this.onSelect,
  });

  /// شماره سطح: ۱، ۲ یا ۳
  final int level;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color color;

  /// در فاز صفر هنوز فعال نیست (دکمه غیرفعال)
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 340,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نشان سطح
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    PersianUtils.faDigits('$level'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('سطح ${PersianUtils.faDigits('$level')}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 17, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(bullet, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSelect, // فاز صفر: غیرفعال
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(onSelect == null ? 'شروع (به‌زودی)' : 'شروع ویزارد'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color.withValues(alpha: .25),
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
