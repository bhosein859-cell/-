import 'dart:convert';

/// توابع کمکی مشترک برای تبدیل ردیف‌های دیتابیس به مدل‌ها.

/// تبدیل متن تاریخ ذخیره‌شده در دیتابیس به [DateTime].
DateTime? parseDbDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());

/// تبدیل ستون‌های متادیتای JSON به نقشه (با تحمل خطا).
Map<String, dynamic> decodeJsonMap(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  } catch (_) {
    return {};
  }
}

/// تبدیل ستون‌های آرایه‌ی JSON (مثل برچسب‌ها) به لیست رشته.
List<String> decodeJsonList(dynamic value) {
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.map((e) => e.toString()).toList();
    return const [];
  } catch (_) {
    return const [];
  }
}
