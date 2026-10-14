import 'dart:convert';
import 'dart:io';

/// ═══════════════════════════════════════════════════════════════
/// معماری پلاگین گره‌گشا — آماده برای ابزارهای تخصصی صنایع
///
/// هر پلاگین یک پوشه محلی است که شامل یک مانیفست `plugin.json`
/// می‌باشد؛ بدون نیاز به اینترنت نصب و فعال می‌شود. ابزارهای تخصصی
/// (مثل نفت و گاز) در آینده با همین قرارداد اضافه می‌شوند و سرویس‌های
/// اصلی از طریق «لایه سرویس» (Repository/Provider) به آن‌ها نقطه‌ی
/// اتصال استاندارد می‌دهند (معماری تمیز، آماده برای API/ERP).
/// ═══════════════════════════════════════════════════════════════
class PluginRegistry {
  static final List<PluginInfo> _plugins = [];

  /// اسکن پوشه‌ی پلاگین‌ها و بارگذاری مانیفست‌ها
  static Future<List<PluginInfo>> discover(Directory pluginsDir) async {
    _plugins.clear();
    if (!await pluginsDir.exists()) return const [];
    await for (final entry in pluginsDir.list()) {
      if (entry is! Directory) continue;
      final manifest = File('${entry.path}/plugin.json');
      if (!await manifest.exists()) continue;
      try {
        final j = jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
        _plugins.add(PluginInfo(
          id: j['id'] as String? ?? 'unknown',
          name: j['name'] as String? ?? entry.path.split('/').last,
          industry: j['industry'] as String? ?? '',
          version: j['version'] as String? ?? '1.0.0',
          entryPoints: List<String>.from(j['entry_points'] as List? ?? const []),
          enabled: j['enabled'] as bool? ?? true,
          path: entry.path,
        ));
      } catch (_) {}
    }
    return List.unmodifiable(_plugins);
  }

  static List<PluginInfo> get loaded => List.unmodifiable(_plugins);

  /// فعال/غیرفعال کردن با بازنویسی مانیفست
  static Future<void> setEnabled(PluginInfo plugin, bool enabled) async {
    final manifest = File('${plugin.path}/plugin.json');
    final j = jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    j['enabled'] = enabled;
    await manifest.writeAsString(const JsonEncoder.withIndent('  ').convert(j));
    final i = _plugins.indexWhere((p) => p.id == plugin.id);
    if (i >= 0) {
      _plugins[i] = PluginInfo(
        id: plugin.id,
        name: plugin.name,
        industry: plugin.industry,
        version: plugin.version,
        entryPoints: plugin.entryPoints,
        enabled: enabled,
        path: plugin.path,
      );
    }
  }
}

class PluginInfo {
  const PluginInfo({
    required this.id,
    required this.name,
    required this.industry,
    required this.version,
    required this.entryPoints,
    required this.enabled,
    required this.path,
  });

  final String id;
  final String name;
  final String industry;
  final String version;
  final List<String> entryPoints;
  final bool enabled;
  final String path;
}
