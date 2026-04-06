import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:econosmart/providers/api_provider.dart';
import 'package:econosmart/chatbot_page.dart';
import 'package:econosmart/chatbot_service.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/bottom_nav.dart';
import 'package:econosmart/config/api_config.dart';

/// Floating chatbot button that appears on every screen
class FloatingChatbotButton extends StatelessWidget {
  const FloatingChatbotButton({super.key});

  void _openChatbot(BuildContext context) {
    final apiProvider = context.read<ApiProvider>();

    final String? effectiveApiKey = (apiProvider.apiKey != null &&
            apiProvider.apiKey!.isNotEmpty)
        ? apiProvider.apiKey
        : (ApiConfig.geminiApiKey.isNotEmpty ? ApiConfig.geminiApiKey : null);

    if (apiProvider.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading chatbot...')),
      );
      return;
    }

    if (effectiveApiKey == null || effectiveApiKey.isEmpty) {
      _showApiKeyDialog(context);
      return;
    }

    // If API key is available, open chatbot in modal bottom sheet
    final chatbotService = ChatbotService(apiKey: effectiveApiKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Chatbot content
                Expanded(
                  child: ChatbotPage(chatbotService: chatbotService),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your Gemini API key to enable the chatbot.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await context.read<ApiProvider>().saveApiKey(key);
                Navigator.pop(context);
                // Re-open chatbot now that key is set
                _openChatbot(context);
              }
            },
            child: const Text('Save & Open'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _openChatbot(context),
      backgroundColor: AppColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 6,
      child: const Icon(Icons.forum_rounded, size: 28),
    );
  }
}

/// Wrapper widget to add floating chatbot to any screen
class ScreenWithChatbot extends StatelessWidget {
  final Widget child;
  final int bottomNavIndex;

  const ScreenWithChatbot({
    Key? key,
    required this.child,
    required this.bottomNavIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: bottomNavIndex >= 0 && bottomNavIndex < 5
          ? BottomNavWidget(currentIndex: bottomNavIndex)
          : null,
      floatingActionButton: const FloatingChatbotButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
