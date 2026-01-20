import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static final _secureStorage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _sosPinKey = 'sos_pin';

  // Save SOS PIN
  Future<void> saveSosPin(String pin) async {
    await _secureStorage.write(key: _sosPinKey, value: pin);
  }

  // Read SOS PIN
  Future<String?> getSosPin() async {
    return await _secureStorage.read(key: _sosPinKey);
  }

  // Delete SOS PIN
  Future<void> deleteSosPin() async {
    await _secureStorage.delete(key: _sosPinKey);
  }

  // Check if SOS PIN exists
  Future<bool> hasSosPin() async {
    final pin = await _secureStorage.read(key: _sosPinKey);
    return pin != null && pin.isNotEmpty;
  }
}