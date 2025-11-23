import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionHelper {
  // Enkripsi password dengan SHA-256
  static String encryptPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPassword(String password, String hashedPassword) {
    return encryptPassword(password) == hashedPassword;
  }
}
