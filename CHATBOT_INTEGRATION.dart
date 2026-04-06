// Integration Examples for Chatbot with API Key

import 'package:flutter/material.dart';
import 'package:econosmart/chatbot_page.dart';
import 'package:econosmart/chatbot_service.dart'; // Required for ChatbotService
import 'package:econosmart/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:econosmart/providers/api_provider.dart'; // For Global Provider Example
import 'storage_service.dart'; // For Secure Storage Example

// Example 1: Using Environment Variable (Recommended for Development)
// Run with: flutter run --dart-define=GEMINI_API_KEY=your-key
// The chatbot will automatically pick it up from the ApiProvider.

// In your navigation or screen:
void navigateToChatbot(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatbotPage(
        // This example is now outdated as ChatbotScreen handles it.
        chatbotService: ChatbotService(apiKey: ApiConfig.geminiApiKey),
      ),
    ),
  );
}

// Example 3: Using Secure Storage (Best for Production)
// First, add dependency to pubspec.yaml:
// flutter_secure_storage: ^9.0.0 (or latest)
// This is already integrated into ApiProvider.
class SecureApiKeyManager {
  static const String _keyName = 'gemini_api_key';
  static const storage = FlutterSecureStorage(); // Corrected: added const

  static Future<void> saveApiKey(String apiKey) async {
    await storage.write(key: _keyName, value: apiKey);
  }

  static Future<String?> getApiKey() async {
    return await storage.read(key: _keyName);
  }

  static Future<void> deleteApiKey() async {
    await storage.delete(key: _keyName);
  }
}

// Usage:
Future<void> navigateToChatbotSecure(BuildContext context) async {
  final apiKey = await SecureApiKeyManager.getApiKey();
  if (apiKey == null) {
    // Handle missing key
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key not configured')),
    );
    return;
  }

  // This example is now outdated as ChatbotScreen handles it.
  // If you were to use this directly, you'd do:
  // if (context.mounted) {
  //   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatbotPage(chatbotService: ChatbotService(apiKey: apiKey))));
  // }
}

// Example 4: Global Provider Pattern (for complex apps)
// This is already implemented in your main.dart and ApiProvider.

class ApiKeyProvider extends ChangeNotifier {
  String? _apiKey;

  String? get apiKey => _apiKey;

  Future<void> initialize() async {
    // Try to get from environment first
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      _apiKey = envKey;
    } else {
      // Then try secure storage (using the StorageService from your project)
      _apiKey = await SecureApiKeyManager.getApiKey();
    }
    notifyListeners();
  }
}

// In main.dart:
// This section is already implemented in your actual main.dart
/* 
void main() async { 
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); 
   
  final apiKeyProvider = ApiKeyProvider(); // This would be your ApiProvider
  await apiKeyProvider.initialize(); // Call init on your ApiProvider
   
  runApp( 
    MultiProvider( 
      providers: [ 
        ChangeNotifierProvider<ApiKeyProvider>.value( // Use your ApiProvider here
          value: apiKeyProvider, 
        ), 
      ],
      child: const EconoSmartApp(),
    ),
  );
}
*/

// Then use it in screens:
// This section is already implemented in your actual ChatbotScreen
/* 
class MyChatbotPage extends StatelessWidget { 
  @override 
  Widget build(BuildContext context) { 
    final apiKey = context.watch<ApiKeyProvider>().apiKey; // Use your ApiProvider
     
    if (apiKey == null) { 
      return const Scaffold( // Added const
        body: Center( 
          child: Text('API Key not configured'), 
        ), 
      ); 
    } 
     
    return ChatbotPage(chatbotService: ChatbotService(apiKey: apiKey)); // Updated constructor
  } 
} 
*/

// ============================================
// QUICK START: Choose Your Integration Method
// ============================================

// For Quick Testing:
// 1. Set environment variable: GEMINI_API_KEY=your-key
// 2. Run: flutter run --dart-define=GEMINI_API_KEY=your-key
// 3. Navigate to chatbot via bottom nav

// For Development:
// The ApiProvider already handles loading from --dart-define.
// If you want to hardcode for quick testing (not recommended), use ApiConfig.

// For Production:
// 1. Use flutter_secure_storage
// 2. Save key securely during app setup
// 3. Retrieve and pass to ChatbotPage when needed

// ============================================
// Environment Setup Commands
// ============================================

/*
# Windows (PowerShell):
$env:GEMINI_API_KEY = "sk-..."
flutter run

# Windows (Command Prompt):
set GEMINI_API_KEY=sk-...
flutter run

# macOS/Linux:
export GEMINI_API_KEY="sk-..."
flutter run

# Or create .env file with:
GEMINI_API_KEY=sk-...

# Then use flutter_dotenv package to load it
*/
