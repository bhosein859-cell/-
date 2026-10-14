import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// تعیین پوشه‌ی Downloads کاربر — مشترک بین خروجی‌های Word و Excel.
///
/// ویندوز: پوشه‌ی Downloads واقعی | اندروید: Downloads عمومی با فال‌بک امن.
Future<Directory> resolveDownloadsDir() async {
  if (Platform.isAndroid) {
    try {
      final pub = Directory('/storage/emulated/0/Download');
      if (await pub.exists()) {
        final probe = File(p.join(pub.path, '.gerehgosha_probe'));
        await probe.writeAsString('ok');
        await probe.delete();
        return pub;
      }
    } catch (_) {
      // بدون دسترسی مستقیم → فال‌بک
    }
    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      final dir = Directory(p.join(ext.path, 'Download'));
      await dir.create(recursive: true);
      return dir;
    }
  } else {
    try {
      final dl = await getDownloadsDirectory();
      if (dl != null) return dl;
    } catch (_) {
      // فال‌بک به اسناد
    }
  }
  return getApplicationDocumentsDirectory();
}
