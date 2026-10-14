import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/level2_models.dart';
import '../level2_provider.dart';

/// گام ۳: ریشه‌یابی عمیق — درخت ۵ چرا چندشاخه‌ای.
/// هر شاخه می‌تواند به یک ریشه‌ی مستقل ختم شود و ریشه‌ها
/// قابل اتصال به شاخه‌های نمودار استخوان‌ماهی هستند.
class Step3WhysTree extends ConsumerWidget {
  const Step3WhysTree({super.key});

  Future<void> _addNode(BuildContext context, WidgetRef ref,
      {required String? parentId}) async {
    final state = ref.read(level2WizardProvider);
    final controller = TextEditingController();
    int? fishboneNodeId;

    // شاخه‌های برگ استخوان‌ماهی برای اتصال
    final leaves = state.fishbone.where((n) => !n.isCategory).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(parentId == null ? 'چرای اول (ریشه‌ی درخت)' : 'چرای بعدی (شاخه‌ی جدید)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'پاسخ چرا…'),
              ),
              if (leaves.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: fishboneNodeId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('بدون اتصال به استخوان‌ماهی')),
                    for (final l in leaves)
                      DropdownMenuItem(value: l.id, child: Text('اتصال به: ${l.title}')),
                  ],
                  onChanged: (v) => setS(() => fishboneNodeId = v),
                  decoration: const InputDecoration(labelText: 'اتصال به شاخه‌ی استخوان‌ماهی'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ثبت')),
          ],
        ),
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(level2WizardProvider.notifier)
          .addWhyNode(controller.text.trim(), parentId, fishboneNodeId);
    }
  }

  Widget _node(BuildContext context, WidgetRef ref, WhyTreeNode node, int depth) {
    final state = ref.read(level2WizardProvider);
    final children = state.whysTree.where((n) => n.parentId == node.nodeId).toList();
    final isLeaf = children.isEmpty;
    String? fishTitle;
    if (node.fishboneNodeId != null) {
      final match = state.fishbone.where((n) => n.id == node.fishboneNodeId);
      fishTitle = match.isEmpty ? null : match.first.title;
    }

    return Container(
      margin: EdgeInsets.only(right: depth * 28.0, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLeaf && depth > 0
            ? AppColors.level3.withValues(alpha: .08)
            : AppColors.navyBlue.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLeaf && depth > 0
                ? AppColors.level3.withValues(alpha: .5)
                : AppColors.navyBlue.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLeaf && depth > 0 ? Icons.gps_fixed : Icons.help_outline,
                size: 17,
                color: isLeaf && depth > 0 ? AppColors.level3 : AppColors.navyBlue,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(node.text, style: const TextStyle(fontSize: 13.5))),
              IconButton(
                tooltip: 'افزودن چرای زیرمجموعه',
                icon: const Icon(Icons.add_circle_outline, size: 19),
                onPressed: () => _addNode(context, ref, parentId: node.nodeId),
              ),
              IconButton(
                tooltip: 'حذف شاخه',
                icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.level3),
                onPressed: () => ref
                    .read(level2WizardProvider.notifier)
                    .deleteWhySubtree(node.nodeId),
              ),
            ],
          ),
          if (fishTitle != null)
            Padding(
              padding: const EdgeInsets.only(right: 26, top: 2),
              child: Text(
                '🦴 متصل به استخوان‌ماهی: $fishTitle',
                style: TextStyle(fontSize: 11, color: AppColors.orange),
              ),
            ),
          for (final c in children) _node(context, ref, c, depth + 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(level2WizardProvider);
    final roots = state.whysTree.where((n) => n.parentId == null).toList();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ریشه‌یابی عمیق (درخت ۵ چرا)',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    'هر شاخه می‌تواند به یک ریشه‌ی مستقل برسد؛ ریشه‌ها را به شاخه‌های استخوان‌ماهی متصل کنید.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _addNode(context, ref, parentId: null),
              icon: const Icon(Icons.add),
              label: const Text('شروع درخت جدید'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (roots.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
            ),
            child: const Text('هنوز درختی ساخته نشده است. با «شروع درخت جدید» اولین چرا را بپرسید.'),
          ),
        for (final r in roots) _node(context, ref, r, 0),
        const SizedBox(height: 12),
      ],
    );
  }
}
