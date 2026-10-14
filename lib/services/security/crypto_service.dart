import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;

/// ═══════════════════════════════════════════════════════════════
/// سرویس رمزنگاری گره‌گشا — کاملاً آفلاین
///
/// • فایل‌های .psp با AES-256-CBC رمز می‌شوند.
/// • کلید از رمز عبور کاربر با ۱۰هزار دور هش (سبکِ استاندارد) ساخته
///   می‌شود؛ هیچ کلیدی روی دیسک ذخیره نمی‌شود.
/// • قالب فایل: «سرآیند + نسخه + نمک + بردار آغازین + متن رمزشده»
/// ═══════════════════════════════════════════════════════════════
class CryptoService {
  static const List<int> _magic = [0x47, 0x47, 0x45, 0x50]; // 'GGEP'
  static const int _version = 1;
  static const int _iterations = 10000;

  static final Random _rng = Random.secure();

  /// اشتقاق کلید ۲۵۶ بیتی از رمز عبور + نمک (هش زنجیره‌ای)
  static Uint8List deriveKey(String password, Uint8List salt) {
    var data = utf8.encode(password) + salt;
    for (var i = 0; i < _iterations; i++) {
      data = crypto.sha256.convert(data).bytes;
    }
    return Uint8List.fromList(data);
  }

  static Uint8List _randomBytes(int n) =>
      Uint8List.fromList(List.generate(n, (_) => _rng.nextInt(256)));

  /// رمزگذاری هر بایت‌هایی (مثلاً کل فایل .psp)
  static Uint8List encryptBytes(Uint8List plain, String password) {
    if (password.isEmpty) return plain;
    final salt = _randomBytes(16);
    final iv = _randomBytes(16);
    final key = deriveKey(password, salt);
    final encrypter = enc.Encrypter(
        enc.AES(enc.Key(Uint8List.fromList(key)), mode: enc.AESMode.cbc));
    final cipher = encrypter.encryptBytes(plain, iv: enc.IV(Uint8List.fromList(iv)));
    return Uint8List.fromList([
      ..._magic,
      _version,
      ...salt,
      ...iv,
      ...cipher.bytes,
    ]);
  }

  /// رمزگشایی؛ اگر فایل رمز نشده باشد همان را برمی‌گرداند.
  /// در صورت رمز اشتباه، `CryptoException` پرتاب می‌شود.
  static Uint8List decryptBytes(Uint8List data, String password) {
    if (data.length < 5 ||
        data[0] != _magic[0] ||
        data[1] != _magic[1] ||
        data[2] != _magic[2] ||
        data[3] != _magic[3]) {
      return data; // فایل بدون رمز
    }
    final salt = data.sublist(5, 21);
    final iv = data.sublist(21, 37);
    final body = data.sublist(37);
    final key = deriveKey(password, salt);
    final encrypter = enc.Encrypter(
        enc.AES(enc.Key(Uint8List.fromList(key)), mode: enc.AESMode.cbc));
    try {
      return Uint8List.fromList(
          encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(body)),
              iv: enc.IV(Uint8List.fromList(iv))));
    } catch (_) {
      throw const CryptoException('رمز عبور اشتباه است یا فایل خراب شده.');
    }
  }

  /// آیا این بایت‌ها یک فایل رمزگذاری‌شده‌ی گره‌گشاست؟
  static bool isEncrypted(Uint8List data) =>
      data.length > 5 &&
      data[0] == _magic[0] &&
      data[1] == _magic[1] &&
      data[2] == _magic[2] &&
      data[3] == _magic[3];

  /// هش رمز عبور برای جدول کاربران (با نمک)
  static String hashPassword(String password, String salt) =>
      crypto.sha256.convert(utf8.encode('$salt:$password')).toString();
}

class CryptoException implements Exception {
  const CryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}
