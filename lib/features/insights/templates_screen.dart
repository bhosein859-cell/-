import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/template_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// قالب‌ها — کپی از پروژه‌های قبلی به عنوان الگو و شروع سریع
/// ═══════════════════════════════════════════════════════════════
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  List<Map<String, Object?>> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await ref.read(templateServiceProvider).listTemplates();
    setState(() {
      _templates = rows;
      _loading = false;
    });
  }

  Future<void> _startFrom(Map<String, Object?> t) async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شروع از روی قالب'),
        content: TextField(
          controller: title,
          decoration: InputDecoration(
            labelText: 'عنوان مسئله‌ی جدید',
            hintText: (t['title'] as String? ?? '').replaceAll(' (الگو)', ''),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ایجاد مسئله')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(templateServiceProvider)
          .startFromTemplate(t['id'] as int, title.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✓ مسئله‌ی جدید با ساختار قالب ساخته شد.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 قالب‌های آماده')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? const Center(
                  child: Text(
                    'قالبی وجود ندارد.\n'
                    'در صفحه‌ی هر پروژه، گزینه‌ی «کپی به عنوان قالب» را بزنید.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _templates.length,
                  itemBuilder: (context, i) {
                    final t = _templates[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.copy_all,
                            color: AppColors.level2),
                        title: Text((t['title'] as String? ?? '')
                            .replaceAll(' (الگو)', '')),
                        subtitle: const Text('الگو — فقط ساختار، بدون داده'),
                        trailing: FilledButton.tonal(
                          onPressed: () => _startFrom(t),
                          child: const Text('شروع از این قالب'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
