# Gemini AI Setup Guide

## Overview
This guide will help you integrate Google's Gemini AI into your Flutter application.

## Prerequisites
- Flutter SDK installed
- A Google Cloud Platform account
- Google AI Studio access

## Step 1: Get Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click on "Get API Key" or "Create API Key"
4. Copy your API key

## Step 2: Configure the API Key

### Option A: Direct Configuration (for testing)
Open `lib/services/gemini_service.dart` and replace:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```
with your actual API key:
```dart
static const String _apiKey = 'AIzaSy...your-actual-key';
```

### Option B: Environment Variables (recommended for production)
1. Create a `.env` file in the root of your project:
```
GEMINI_API_KEY=your-api-key-here
```

2. Add flutter_dotenv to pubspec.yaml:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

3. Update pubspec.yaml assets:
```yaml
flutter:
  assets:
    - .env
```

4. Modify `gemini_service.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final String _apiKey;

  GeminiService() {
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
  }
}
```

5. Load .env in main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

## Step 3: Usage Examples

### Basic Text Generation
```dart
final geminiController = Get.put(GeminiController());
await geminiController.generateResponse("What is Flutter?");
print(geminiController.currentResponse.value);
```

### Chat Conversation
```dart
final geminiController = Get.put(GeminiController());
await geminiController.sendChatMessage("Hello, how are you?");
// Messages are stored in geminiController.chatHistory
```

### Financial Analysis
```dart
final geminiController = Get.put(GeminiController());
final advice = await geminiController.getFinancialAdvice(
  balance: 50000.0,
  expenses: 15000.0,
  income: 30000.0,
);
print(advice);
```

### Receipt Image Analysis
```dart
import 'dart:io';

final imageBytes = await File('path/to/receipt.jpg').readAsBytes();
final geminiController = Get.put(GeminiController());
final analysis = await geminiController.analyzeReceiptImage(imageBytes);
print(analysis);
```

## Step 4: Add AI Features to Your Dashboard

### Option 1: Add AI Chat Button to Dashboard
Add this to your `dashboard_page.dart`:

```dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIChatPage()),
    );
  },
  backgroundColor: Colors.blue[700],
  child: const Icon(Icons.psychology_outlined),
),
```

### Option 2: Add AI Insights Widget
```dart
// In dashboard_page.dart
Obx(() {
  final geminiController = Get.find<GeminiController>();
  return FutureBuilder<String?>(
    future: geminiController.getFinancialAdvice(
      balance: dashController.totalBalance.value,
      expenses: dashController.totalExpenses.value,
      income: dashController.totalIncome.value,
    ),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Financial Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(snapshot.data ?? ''),
              ],
            ),
          ),
        );
      }
      return const CircularProgressIndicator();
    },
  );
}),
```

## Step 5: Available Models

- **gemini-pro**: Text-only input and output
- **gemini-pro-vision**: Text and image input, text output

## API Limits (Free Tier)
- 60 requests per minute
- 1,500 requests per day
- Rate limits may vary by region

## Security Best Practices

1. **Never commit API keys to version control**
   - Add `.env` to `.gitignore`
   ```
   # .gitignore
   .env
   ```

2. **Use environment variables for production**

3. **Implement API key rotation**

4. **Monitor API usage** on Google AI Studio

5. **Add error handling** for API failures

## Troubleshooting

### Error: "API key not valid"
- Verify your API key in Google AI Studio
- Check if the key is correctly set in `gemini_service.dart`
- Ensure the key has the necessary permissions

### Error: "Resource exhausted"
- You've exceeded the API quota
- Wait for the rate limit to reset
- Consider upgrading to a paid plan

### Error: "Model not found"
- Verify the model name (e.g., 'gemini-pro')
- Check if the model is available in your region

## Additional Resources

- [Google AI Studio](https://makersuite.google.com/)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Package Documentation](https://pub.dev/packages/google_generative_ai)

## Support

For issues related to:
- Gemini API: [Google AI Support](https://ai.google.dev/support)
- Flutter Package: [GitHub Issues](https://github.com/google/generative-ai-dart/issues)
