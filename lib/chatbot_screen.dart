import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:econosmart/providers/api_provider.dart';
import 'package:econosmart/chatbot_page.dart'; // The actual chatbot UI
import 'package:econosmart/chatbot_service.dart'; // To instantiate the service
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/bottom_nav.dart';
import 'package:econosmart/config/api_config.dart';

/// This screen acts as a wrapper for the ChatbotPage, handling the
/// provisioning of the Gemini API key using ApiProvider.
class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = context.watch<ApiProvider>();

    // Priority: 1. User entered key in Provider, 2. Hardcoded key in ApiConfig
    final String? effectiveApiKey = (apiProvider.apiKey != null &&
            apiProvider.apiKey!.isNotEmpty)
        ? apiProvider.apiKey
        : (ApiConfig.geminiApiKey.isNotEmpty ? ApiConfig.geminiApiKey : null);

    if (apiProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.inputBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
      );
    }

    if (effectiveApiKey == null || effectiveApiKey.isEmpty) {
      return _ApiKeyMissingView();
    }

    // If API key is available, instantiate ChatbotService and pass it to ChatbotPage
    final chatbotService = ChatbotService(apiKey: effectiveApiKey);
    return ChatbotPage(chatbotService: chatbotService);
  }
}

/// A view displayed when the Gemini API key is missing or not configured.
class _ApiKeyMissingView extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  _ApiKeyMissingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
        title: const Text(
          'EcoNo Smart chatbot',
          style: TextStyle(color: AppColors.textDark),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                'API Key Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please enter your Gemini API key to enable the chatbot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Paste Gemini API Key here',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final key = _controller.text.trim();
                  if (key.isNotEmpty) {
                    await context.read<ApiProvider>().saveApiKey(key);
                  }
                },
                child: const Text('Save Key'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const BottomNavWidget(currentIndex: 4), // Assuming chatbot is index 4
    );
  }
}
