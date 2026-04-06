import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Manages the state of the Gemini API key, loading it from environment
/// variables or secure storage.
class ApiProvider extends ChangeNotifier {
  String? _apiKey;
  bool _isLoading = true;

  String? get apiKey => _apiKey;
  bool get isLoading => _isLoading;

  ApiProvider() {
    init();
  }

  /// Initializes the API key by first checking environment variables
  /// and then falling back to secure storage.
  Future<void> init() async {
    // 1. Try to get from --dart-define (Environment)
    const envKey = String.fromEnvironment('GEMINI_API_KEY');

    if (envKey.isNotEmpty) {
      _apiKey = envKey;
    } else {
      // 2. Fallback to Secure Storage
      _apiKey = await StorageService.getApiKey();
    }

    _isLoading = false;
    notifyListeners();
  }
}
