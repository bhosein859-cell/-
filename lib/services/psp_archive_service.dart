import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../data/database/database_helper.dart';
import '../data/database/schema.dart';

/// نتیجه‌ی عملیات اکسپورت/ایمپورت.
class PspResult {
  const PspResult({required this.success, required this.message, this.filePath});

  final bool success;
  final String message;
  final String? filePath;
}

/// متادیتای فایل پروژه — محتوای `manifest.json` داخل آرشیو.
class PspManifest {
  const PspManifest({
    required this.format,
    required this.formatVersion,
    required this.appName,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdBy,
    required this.exportedAt,
    this.note,
  });

  final String format;
  final int formatVersion;
  final String appName;
  final String appVersion;
  final int schemaVersion;

  /// سازنده‌ی بسته — همیشه «حسین بختیاری» درج می‌شود
  final String createdBy;
  final String exportedAt;
  final String? note;

  Map<String, dynamic> toJson() => {
        'format': format,
        'format_version': formatVersion,
        'app_name': appName,
        'app_version': appVersion,
        'schema_version': schemaVersion,
        'created_by': createdBy,
        'exported_at': exportedAt,
        if (note != null) 'note': note,
      };

  factory PspManifest.fromJson(Map<String, dynamic> json) => PspManifest(
        format: json['format'] as String? ?? '',
        formatVersion: json['format_version'] as int? ?? 1,
        appName: json['app_name'] as String? ?? '',
        appVersion: json['app_version'] as String? ?? '',
        schemaVersion: json['schema_version'] as int? ?? Schema.version,
        createdBy: json['created_by'] as String? ?? '',
        exportedAt: json['exported_at'] as String? ?? '',
        note: json['note'] as String?,
      );
}

/// سرویس فایل اختصاصی `.psp` — بسته‌ی پروژه‌ی گره‌گشا
/// (Gereh-Gosha Project Package).
///
/// ساختار داخلی فایل (یک آرشیو ZIP استاندارد با پسوند `.psp`):
/// ```
/// نمونه.psp
/// ├── manifest.json       ← متادیتا: فرمت، نسخه، سازنده، تاریخ، نسخه‌ی اسکیمای دیتابیس
/// ├── database.sqlite     ← نسخه‌ی پشتیبان کامل دیتابیس محلی آن پروژه
/// └── attachments/        ← همه‌ی پیوست‌ها (عکس، PDF، ویدیو و...)
/// ```
///
/// این سرویس روی ویندوز و اندروید به یک شکل کار می‌کند
/// (کتابخانه‌ی `archive` پیاده‌سازی خالص Dart است و به ابزار سیستمی نیاز ندارد).
class PspArchiveService {
  PspArchiveService({required DatabaseHelper database}) : _db = database;

  final DatabaseHelper _db;

  static const String manifestEntry = 'manifest.json';
  static const String dbEntry = 'database.sqlite';
  static const String attachmentsPrefix = 'attachments/';

  /// شناسه‌ی فرمت — هنگام ایمپورت اعتبارسنجی می‌شود
  static const String formatId = 'gereh-gosha-psp';

  // ════════════════════════════ خروجی (Export) ════════════════════════════

  /// ساخت فایل `.psp` و ذخیره‌ی آن در مسیری که کاربر انتخاب می‌کند.
  Future<PspResult> exportProject() async {
    try {
      // ۱) انتخاب مقصد ذخیره توسط کاربر (ویندوز: دیالوگ Save | اندروید: SAF)
      final outPath = await FilePicker.platform.saveFile(
        dialogTitle: 'ذخیره‌ی فایل پروژه‌ی گره‌گشا',
        fileName: 'gereh-gosha-${_stamp(DateTime.now())}.psp',
      );
      if (outPath == null || outPath.isEmpty) {
        return const PspResult(success: false, message: 'ذخیره توسط کاربر لغو شد.');
      }

      // ۲) بستن امن دیتابیس و آماده‌سازی فایل‌ها
      final dbPath = await _db.resolveDbPath();
      final attachments = await _db.attachmentsDir;
      await _db.close(); // ⚠️ قبل از کپی، اتصال حتماً بسته شود

      // ۳) ساخت آرشیو در حافظه
      final archive = Archive();

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final bytes = await dbFile.readAsBytes();
        archive.addFile(ArchiveFile(dbEntry, bytes.length, bytes));
      }

      if (await attachments.exists()) {
        await for (final entity
            in attachments.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final relative =
                p.relative(entity.path, from: attachments.path).replaceAll(r'\', '/');
            final bytes = await entity.readAsBytes();
            archive.addFile(
                ArchiveFile('$attachmentsPrefix$relative', bytes.length, bytes));
          }
        }
      }

      // ۴) manifest.json — هویت بسته
      final manifest = PspManifest(
        format: formatId,
        formatVersion: AppConstants.pspFormatVersion,
        appName: AppConstants.appName,
        appVersion: AppConstants.appVersionEn,
        schemaVersion: Schema.version,
        createdBy: AppConstants.creator,
        exportedAt: DateTime.now().toUtc().toIso8601String(),
      );
      final manifestBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      );
      archive.addFile(
          ArchiveFile(manifestEntry, manifestBytes.length, manifestBytes));

      // ۵) فشرده‌سازی و ذخیره با پسوند .psp
      final encoded = ZipEncoder().encode(archive);
      if (encoded == null) {
        return const PspResult(success: false, message: 'خطا در فشرده‌سازی آرشیو.');
      }
      await File(outPath).writeAsBytes(encoded, flush: true);

      // ۶) ثبت رویداد در تاریخچه‌ی تغییرات
      await _db.logAudit(action: 'export_psp', details: {'file': outPath});

      return PspResult(
        success: true,
        message: 'فایل پروژه با موفقیت ذخیره شد.',
        filePath: outPath,
      );
    } catch (e) {
      return PspResult(success: false, message: 'خطا در ساخت فایل پروژه: $e');
    }
  }

  // ════════════════════════════ ورودی (Import) ════════════════════════════

  /// بازیابی کامل اپلیکیشن از یک فایل `.psp`.
  Future<PspResult> importProject() async {
    try {
      // ۱) انتخاب فایل توسط کاربر
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'انتخاب فایل پروژه‌ی گره‌گشا (.psp)',
        type: FileType.any,
      );
      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.single.path == null) {
        return const PspResult(success: false, message: 'فایلی انتخاب نشد.');
      }
      final source = File(picked.files.single.path!);
      if (!source.path.toLowerCase().endsWith('.psp')) {
        return const PspResult(
            success: false, message: 'پسوند فایل باید «.psp» باشد.');
      }

      // ۲) باز کردن آرشیو و اعتبارسنجی فرمت
      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(await source.readAsBytes());
      } catch (_) {
        return const PspResult(
            success: false, message: 'فایل انتخاب‌شده یک آرشیو معتبر نیست.');
      }

      final manifestFile = archive.findFile(manifestEntry);
      if (manifestFile == null) {
        return const PspResult(
            success: false,
            message: 'فایل پروژه معتبر نیست (manifest.json یافت نشد).');
      }
      final manifest = PspManifest.fromJson(jsonDecode(
              utf8.decode(manifestFile.content as List<int>))
          as Map<String, dynamic>);
      if (manifest.format != formatId) {
        return const PspResult(
            success: false, message: 'این فایل متعلق به گره‌گشا نیست.');
      }

      // ۳) پشتیبان‌گیری خودکار از وضعیت فعلی قبل از جایگزینی
      final dbPath = await _db.resolveDbPath();
      final attachments = await _db.attachmentsDir;
      await _db.close();

      if (await File(dbPath).exists()) {
        await File(dbPath).copy('$dbPath.backup-${_stamp(DateTime.now())}');
      }

      // ۴) استخراج: دیتابیس جایگزین و پیوست‌ها بازنویسی می‌شوند
      if (await attachments.exists()) {
        await attachments.delete(recursive: true);
      }
      await attachments.create(recursive: true);

      for (final entry in archive.files) {
        if (!entry.isFile) continue;
        final data = entry.content as List<int>;

        final String destPath;
        if (entry.name == dbEntry) {
          destPath = dbPath;
        } else if (entry.name.startsWith(attachmentsPrefix)) {
          final relative = entry.name.substring(attachmentsPrefix.length);
          if (relative.isEmpty) continue;
          destPath = _safeJoin(attachments.path, relative);
        } else {
          continue; // manifest و فایل‌های ناشناخته ذخیره نمی‌شوند
        }

        final out = File(destPath);
        await out.create(recursive: true);
        await out.writeAsBytes(data, flush: true);
      }

      // ۵) ثبت رویداد بازیابی در دیتابیسِ تازه‌وارده‌شده
      await _db.logAudit(
        action: 'import_psp',
        details: {
          'exported_at': manifest.exportedAt,
          'created_by': manifest.createdBy,
          'app_version': manifest.appVersion,
        },
      );

      return const PspResult(success: true, message: 'پروژه با موفقیت بازیابی شد.');
    } catch (e) {
      return PspResult(success: false, message: 'خطا در بازیابی فایل پروژه: $e');
    }
  }

  // ════════════════════════════ ابزارهای داخلی ════════════════════════════

  /// محافظت در برابر حملات مسیر (Path Traversal) هنگام استخراج آرشیو.
  String _safeJoin(String base, String relative) {
    final result = p.normalize(p.join(base, relative));
    if (!p.isWithin(base, result)) {
      throw ArgumentError('مسیر غیرمجاز در آرشیو: $relative');
    }
    return result;
  }

  /// مهر زمانی برای نام فایل‌ها: 20261007-1430
  String _stamp(DateTime t) =>
      '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}'
      '-${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}';
}
