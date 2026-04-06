import 'package:google_generative_ai/google_generative_ai.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatbotService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  final List<ChatMessage> _chatHistory = [];

  ChatbotService({required String apiKey}) {
    _initializeModel(apiKey);
  }

  void _initializeModel(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    _chatSession = _model.startChat();
  }

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  Future<String> sendMessage(String userMessage) async {
    try {
      // Add user message to history
      _chatHistory.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      // Get response from Gemini
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      final responseText =
          response.text ?? 'Sorry, I could not generate a response.';

      // Add bot response to history
      _chatHistory.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      return responseText;
    } catch (e) {
      final errorMessage = 'Error: ${e.toString()}';
      _chatHistory.add(
        ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      return errorMessage;
    }
  }

  void clearHistory() {
    _chatHistory.clear();
    _chatSession = _model.startChat();
  }

  void dispose() {
    _chatHistory.clear();
  }
}
