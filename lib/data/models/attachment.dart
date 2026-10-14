import 'dart:convert';

import 'model_utils.dart';

/// مدل پیوست (عکس، PDF، ویدیو و...) وابسته به یک مسئله.
class Attachment {
  const Attachment({
    this.id,
    required this.problemId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    this.sizeBytes,
    this.uploadedBy,
    this.createdAt,
    this.metadata = const {},
  });

  final int? id;
  final int problemId;
  final String fileName;

  /// مسیر نسبی داخل پوشه‌ی `attachments` (برای انتقالپذیری در فایل .psp)
  final String filePath;
  final String? mimeType;
  final int? sizeBytes;
  final int? uploadedBy;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(
        id: m['id'] as int?,
        problemId: m['problem_id'] as int,
        fileName: m['file_name'] as String,
        filePath: m['file_path'] as String,
        mimeType: m['mime_type'] as String?,
        sizeBytes: m['size_bytes'] as int?,
        uploadedBy: m['uploaded_by'] as int?,
        createdAt: parseDbDate(m['created_at']),
        metadata: decodeJsonMap(m['metadata']),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'problem_id': problemId,
        'file_name': fileName,
        'file_path': filePath,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'uploaded_by': uploadedBy,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'metadata': jsonEncode(metadata),
      };
}
