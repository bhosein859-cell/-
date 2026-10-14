import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// ═══════════════════════════════════════════════════════════════
/// سرویس اشتراک‌گذاری فایل .psp — بدون اینترنت
///   ۱. کد QR: برای فایل‌های کوچک، خود محتوا؛ وگرنه متادیتای انتقال
///   ۲. شبکه محلی (LAN): سرور HTTP موقت بین ویندوز و اندروید
///   ۳. اشتراک بومی (واتس‌اپ/ایمیل/بلوتوث): از برگه‌ی اشتراک سیستم
/// ═══════════════════════════════════════════════════════════════
class ShareService {
  /// ── ۱. کد QR ──
  /// برای فایل‌های تا سقف ~۱٫۵ کیلوبایت (فایل فشرده‌ی متادیتا)، خود
  /// محتوا در QR جا می‌شود؛ برای فایل بزرگ‌تر، مسیر + راهنما پیشنهاد
  /// می‌شود تا از روش شبکه محلی استفاده شود.
  static Future<QrShareResult> buildQr(Uint8List fileBytes, String fileName) async {
    const maxInline = 1500;
    if (fileBytes.length <= maxInline) {
      // base64url کوتاه و قابل اسکن
      final payload = 'GG1:${base64Url.encode(fileBytes)}';
      return QrShareResult(inline: true, data: payload, fileName: fileName);
    }
    return QrShareResult(
      inline: false,
      data: 'GerehGosha|psp|${fileName}|${fileBytes.length}',
      fileName: fileName,
    );
  }

  /// رندر تصویر QR (مثلاً برای ذخیره/نمایش)
  static Future<Uint8List> renderQrPng(String data, {double size = 320}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );
    final img = await painter.toImage(size);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// ── ۲. سرور شبکه محلی ──
  static HttpServer? _server;

  /// شروع سرو فایل روی شبکه محلی؛ آدرس کامل را برمی‌گرداند
  static Future<LanShareInfo> serveFile(String filePath) async {
    await stopLan();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    final file = File(filePath);
    final name = p.basename(filePath);

    server.listen((req) async {
      final res = req.response;
      res.headers.contentType = ContentType.binary;
      res.headers.set('Content-Disposition', 'attachment; filename="$name"');
      res.headers.set('Access-Control-Allow-Origin', '*');
      res.contentLength = await file.length();
      await res.addStream(file.openRead());
      await res.close();
    });

    final ip = await _localIp();
    return LanShareInfo(
      url: 'http://$ip:${server.port}/$name',
      port: server.port,
    );
  }

  static Future<void> stopLan() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// آی‌پی دستگاه در شبکه محلی (اولین آدرس غیر لوپ‌بک)
  static Future<String> _localIp() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final i in interfaces) {
      for (final a in i.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
    return '127.0.0.1';
  }

  /// ── ۳. اشتراک بومی (اندروید/ویندوز) ──
  /// برگه‌ی اشتراک سیستم‌عامل: واتس‌اپ، ایمیل، بلوتوث و…
  static Future<void> shareFile(String filePath, {String subject = ''}) async {
    final xfile = XFile(filePath);
    await Share.shareXFiles(
      [xfile],
      subject: subject.isEmpty ? 'فایل پروژه گره‌گشا' : subject,
      text: 'ارسال‌شده توسط نرم‌افزار گره‌گشا — ساخته‌ی حسین بختیاری',
    );
  }

  /// آماده‌سازی برای ایمیل: کپی فایل در پوشه دانلود برای پیوست دستی
  static Future<String> prepareForEmail(String filePath, Directory downloads) async {
    final dest = p.join(downloads.path, p.basename(filePath));
    await File(filePath).copy(dest);
    return dest;
  }
}

class QrShareResult {
  const QrShareResult(
      {required this.inline, required this.data, required this.fileName});

  /// آیا محتوا مستقیم داخل QR جا شد؟
  final bool inline;
  final String data;
  final String fileName;
}

class LanShareInfo {
  const LanShareInfo({required this.url, required this.port});

  final String url;
  final int port;
}
