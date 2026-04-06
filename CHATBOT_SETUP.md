# Financial Chatbot Setup Guide

## Overview
The Financial Chatbot page integrates Google's Gemini API to provide financial advice and guidance within the EconoSmart app.

## Features
- 💬 Real-time chat with AI financial assistant
- 📊 Budget tips, investment ideas, and expense tracking guidance
- 🔄 Conversation history within the session
- 🧹 Clear chat history option
- 💡 Suggested prompts for quick access

## Setup Instructions

### 1. Install Dependencies
Before using the chatbot, ensure you have the Gemini package installed:

```bash
flutter pub get
```

The following dependency has been added to `pubspec.yaml`:
```yaml
google_generative_ai: ^0.4.7
```

### 2. Get Your Gemini API Key
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click on "Create API Key"
3. Generate a new API key
4. Copy the key (keep it secure!)

### 3. Configure the API Key

#### Option A: Environment Variable (Recommended for Development)
```bash
# On Windows (PowerShell)
$env:GEMINI_API_KEY = "your-api-key-here"
flutter run

# On macOS/Linux
export GEMINI_API_KEY="your-api-key-here"
flutter run
```

#### Option B: Pass at Runtime
```dart
// In your main.dart or navigation
ChatbotPage(geminiApiKey: 'your-api-key-here')
```

#### Option C: Secure Configuration (Recommended for Production)
Store the API key in a secure configuration file:

```dart
// Create lib/config/api_config.dart
class ApiConfig {
  static const String geminiApiKey = 'your-api-key-here';
}
```

Then import and use:
```dart
import 'package:econosmart/config/api_config.dart';

ChatbotPage(geminiApiKey: ApiConfig.geminiApiKey)
```

### 4. Build and Run
```bash
flutter clean
flutter pub get
flutter run
```

## Usage

### Accessing the Chatbot
- Tab the chatbot icon (🤖) in the bottom navigation bar
- Or navigate from any screen using the bottom nav

### Supported Topics
The chatbot is trained to help with:
- 💰 Budgeting and financial planning
- 📈 Investment strategies
- 💸 Expense tracking and management
- 📊 Economic trends and news interpretation
- 💼 Wealth management advice

### Example Queries
- "Give me budgeting tips"
- "What are good investment strategies?"
- "How can I better track my expenses?"
- "Explain what causes inflation"
- "What's the best way to save for retirement?"

## Architecture

### Files Created
- **`lib/chatbot_service.dart`** - Service layer for Gemini API communication
- **`lib/chatbot_page.dart`** - UI for the chatbot interface
- **`lib/bottom_nav.dart`** - Updated navigation with chatbot tab

### ChatbotService Class
```dart
ChatbotService(apiKey: 'your-key') // Initialize
await chatbotService.sendMessage(userMessage) // Send message
chatbotService.clearHistory() // Clear chat history
chatbotService.dispose() // Clean up resources
```

## Important Notes

⚠️ **API Key Security**
- Never commit your API key to version control
- Use environment variables or secure configuration files
- Rotate keys regularly
- Monitor usage in [Google Cloud Console](https://console.cloud.google.com)

⚠️ **Rate Limits**
- Free tier has usage limits
- Check [pricing page](https://ai.google.dev/pricing) for details
- Implement rate limiting if needed in production

⚠️ **Cost**
- Gemini API usage incurs charges after free tier
- Monitor your usage and set up billing alerts

## Troubleshooting

### Error: "Gemini API Key not provided"
- Ensure GEMINI_API_KEY environment variable is set
- Or pass `geminiApiKey` parameter to ChatbotPage

### No Response from Chatbot
- Check internet connection
- Verify API key is valid
- Check API quota in Google Cloud Console
- Review rate limits

### Build Errors
```bash
# Try these commands
flutter clean
flutter pub get
flutter pub upgrade google_generative_ai
```

## Future Enhancements
- [ ] Persist chat history to Firestore
- [ ] Support multiple conversations
- [ ] Add voice input/output
- [ ] Export chat as PDF
- [ ] Integration with user's expense data
- [ ] Real-time market data integration

## Support
For API issues, visit: https://aistudio.google.com/
For Flutter issues, visit: https://flutter.dev/community
