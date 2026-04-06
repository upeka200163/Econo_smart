import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider for managing Gemini API key across the app
class ApiProvider extends ChangeNotifier {
  static const String _keyStorageKey = 'gemini_api_key';
  static const String _apiKeyEnvVar = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _apiKey;
  bool _isLoading = true;
  String? _error;

  String? get apiKey => _apiKey;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ApiProvider() {
    _initialize();
  }

  /// Public method to re-initialize (useful for reloading after key changes)
  Future<void> init() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First try to get from environment variable (for Flutter run --dart-define)
      if (_apiKeyEnvVar.isNotEmpty) {
        _apiKey = _apiKeyEnvVar;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Then try to get from secure storage
      _apiKey = await _storage.read(key: _keyStorageKey);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load API key: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _keyStorageKey, value: apiKey);
      _apiKey = apiKey;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save API key: $e';
      notifyListeners();
    }
  }

  /// Clear stored API key
  Future<void> clearApiKey() async {
    try {
      await _storage.delete(key: _keyStorageKey);
      _apiKey = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear API key: $e';
      notifyListeners();
    }
  }
}
