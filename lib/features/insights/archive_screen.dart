import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// بایگانی مسائل — پروژه‌های بسته‌شده بدون حذف، در دسترس و جستجوپذیر
/// ═══════════════════════════════════════════════════════════════
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await ref.read(databaseProvider).database;
    final rows = await db.query('problems',
        where: 'is_archived = 1', orderBy: 'updated_at DESC');
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _toggle(int id, bool archived) async {
    final db = await ref.read(databaseProvider).database;
    await db.update('problems', {'is_archived': archived ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🗄 بایگانی مسائل')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text('بایگانی خالی است.\n'
                      'از لیست پروژه‌های بسته‌شده می‌توانید موارد را بایگانی کنید.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final r = _rows[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.archive_outlined,
                            color: AppColors.navyBlue),
                        title: Text(r['title'] as String? ?? ''),
                        subtitle: Text(
                            'سطح ${PersianUtils.faDigits('${r['level']}')}'
                            ' • بسته‌شده در ${PersianUtils.faDigits((r['resolved_at'] as String? ?? '—').substring(0, 10))}'),
                        trailing: TextButton(
                          onPressed: () => _toggle(r['id'] as int, false),
                          child: const Text('بازگردانی'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
