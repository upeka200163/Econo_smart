import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service to securely store and retrieve sensitive data like API keys.
class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'gemini_api_key';

  /// Saves the given API key securely.
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _keyName, value: apiKey);
  }

  /// Retrieves the securely stored API key.
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _keyName);
  }
}
