import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../data/database/database_helper.dart';

/// ═══════════════════════════════════════════════════════════════
/// پشتیبان‌گیری و بازیابی دیتابیس — کاملاً محلی
/// پشتیبان‌ها در پوشه‌ی «Backups» کنار داده‌های اپ ذخیره می‌شوند.
/// ═══════════════════════════════════════════════════════════════
class BackupService {
  BackupService(this._helper);

  final DatabaseHelper _helper;

  Future<Directory> get _backupDir async {
    final base = await _helper.dataDir;
    final dir = Directory(p.join(base.path, 'Backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// ساخت یک نسخه پشتیبان با برچسب زمانی؛ مسیر فایل را برمی‌گرداند
  Future<String> createBackup({String? note}) async {
    final db = await _helper.database;
    final srcPath = db.path;
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .substring(0, 15);
    final dest = p.join((await _backupDir).path, 'backup_$stamp.db');
    await File(srcPath).copy(dest);
    return dest;
  }

  /// فهرست پشتیبان‌های موجود (جدیدترین اول)
  Future<List<BackupInfo>> listBackups() async {
    final dir = await _backupDir;
    if (!await dir.exists()) return const [];
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db')).toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return [
      for (final f in files)
        BackupInfo(
          path: f.path,
          createdAt: f.lastModifiedSync(),
          sizeBytes: await f.length(),
        ),
    ];
  }

  /// بازیابی دیتابیس از یک پشتیبان (باید اتصال بسته شود؛ در اپ
  /// بلافاصله پس از بازیابی، ری‌استارت نرم پیشنهاد می‌شود)
  Future<void> restore(String backupPath) async {
    if (!await File(backupPath).exists()) {
      throw const FileSystemException('فایل پشتیبان پیدا نشد.');
    }
    final db = await _helper.database;
    final target = db.path;
    await File(backupPath).copy(target);
  }

  /// حذف پشتیبان‌های قدیمی (نگه‌داشتن `keep` مورد آخر)
  Future<void> prune({int keep = 10}) async {
    final all = await listBackups();
    for (final b in all.skip(keep)) {
      await File(b.path).delete();
    }
  }
}

class BackupInfo {
  const BackupInfo({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final DateTime createdAt;
  final int sizeBytes;

  String get sizeMb => (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
}

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));
