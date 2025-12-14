# Voice Chat Implementation Guide

## Overview
This guide documents the voice chat functionality implemented in the AI Chat feature. Users can now speak to the AI assistant and have the AI speak back responses.

## Features Implemented

### 1. Speech-to-Text (User → AI)
- **Microphone Button**: Purple circular button next to send button in input area
- **Visual Feedback**: 
  - Button turns red when listening
  - "Listening..." indicator appears above chat
  - Pulsing shadow effect when active
- **Functionality**:
  - Tap microphone to start recording
  - Tap again (stop icon) to stop and send message
  - Automatic transcription to text field
  - Message sent automatically when recording stops

### 2. Text-to-Speech (AI → User)
- **Auto-Speak**: AI responses are automatically spoken after generation
- **Manual Replay**: Speaker icon on each AI message bubble
  - Tap to play/stop message audio
  - Icon changes from volume_up to volume_off when playing
- **Voice Configuration**:
  - Language: English
  - Speech rate: 0.5 (slower for clarity)
  - Platform-specific voice engine

### 3. UI Components Added

#### Microphone Button (Input Area)
```dart
Location: Next to send button (line ~867)
- Purple gradient when idle
- Red gradient when listening
- Animated shadow and size changes
- Icons: mic_rounded → stop_rounded
```

#### Listening Indicator (Above Messages)
```dart
Location: Above loading indicator (line ~438)
- Red gradient background
- Microphone icon + "Listening..." text
- Circular progress indicator
- Only visible when _isListening = true
```

#### Speaker Button (AI Messages)
```dart
Location: Next to timestamp in AI bubbles (line ~1013)
- Volume icon that changes when speaking
- Blue accent color
- Only appears on AI messages (not user messages)
```

## Technical Implementation

### Packages Used
```yaml
speech_to_text: ^6.6.0
flutter_tts: ^4.0.2
permission_handler: ^11.3.0
```

### State Variables
```dart
final SpeechToText _speech = SpeechToText();
final FlutterTts _flutterTts = FlutterTts();
final RxBool _isListening = false.obs;
final RxBool _isSpeaking = false.obs;
bool _speechEnabled = false;
```

### Key Methods

#### Initialize Speech Recognition
```dart
Future<void> _initSpeech() async {
  // Request microphone permission
  PermissionStatus status = await Permission.microphone.request();
  
  if (status.isGranted) {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  } else {
    // Show permission denied message
  }
}
```

#### Initialize Text-to-Speech
```dart
Future<void> _initTts() async {
  await _flutterTts.setLanguage("en-US");
  await _flutterTts.setSpeechRate(0.5);
  
  _flutterTts.setStartHandler(() {
    _isSpeaking.value = true;
  });
  
  _flutterTts.setCompletionHandler(() {
    _isSpeaking.value = false;
  });
  
  _flutterTts.setErrorHandler((msg) {
    _isSpeaking.value = false;
  });
}
```

#### Start Listening
```dart
Future<void> _startListening() async {
  if (!_speechEnabled) return;
  
  await _speech.listen(
    onResult: (result) {
      messageController.text = result.recognizedWords;
    },
    listenMode: ListenMode.confirmation,
  );
  _isListening.value = true;
}
```

#### Stop Listening
```dart
Future<void> _stopListening() async {
  await _speech.stop();
  _isListening.value = false;
  
  // Auto-send message if text was transcribed
  if (messageController.text.isNotEmpty) {
    _sendMessage();
  }
}
```

#### Speak Text
```dart
Future<void> _speak(String text) async {
  await _flutterTts.speak(text);
}
```

#### Stop Speaking
```dart
Future<void> _stopSpeaking() async {
  await _flutterTts.stop();
  _isSpeaking.value = false;
}
```

#### Auto-Speak AI Responses
```dart
Future<void> _sendMessage() async {
  // ... send message logic ...
  
  // Track message count before sending
  final previousMessageCount = geminiController.chatHistory.length;
  
  // Send message to AI
  await geminiController.sendChatMessage(message);
  
  // Wait for AI response and auto-speak
  Future.delayed(const Duration(milliseconds: 500), () {
    if (geminiController.chatHistory.length > previousMessageCount) {
      final aiMessage = geminiController.chatHistory.last;
      if (!aiMessage.isUser) {
        _speak(aiMessage.text);
      }
    }
  });
}
```

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone for voice chat</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition for voice chat</string>
```

## User Experience Flow

### Speaking to AI
1. User taps purple microphone button
2. Button turns red, "Listening..." banner appears
3. User speaks their message
4. Transcription appears in text field in real-time
5. User taps red stop button
6. Message is sent to AI automatically
7. AI responds with text
8. AI response is automatically spoken

### Replaying AI Responses
1. User sees AI message in chat
2. Taps speaker icon next to timestamp
3. AI message is spoken
4. Icon changes to indicate speaking state
5. Tap again to stop playback

## Testing Checklist
- [ ] Microphone permission requested on first use
- [ ] Speech recognition works and transcribes accurately
- [ ] Text appears in input field during recording
- [ ] Recording stops when stop button tapped
- [ ] Message sends automatically after recording
- [ ] AI responses are automatically spoken
- [ ] Speaker button appears on AI messages only
- [ ] Manual replay works for each AI message
- [ ] Multiple messages can be replayed
- [ ] Stop speaking works correctly
- [ ] Visual indicators (listening banner) show/hide properly
- [ ] Button animations work smoothly
- [ ] Works on both Android and iOS

## Known Limitations
- Speech recognition accuracy depends on:
  - Microphone quality
  - Background noise level
  - User's accent and speaking clarity
  - Internet connection (for cloud-based recognition)
- TTS voice quality varies by platform and language
- Microphone permission must be granted for functionality

## Future Enhancements
- [ ] Add language selection for speech recognition
- [ ] Add voice selection for TTS (male/female, different accents)
- [ ] Add speech rate control
- [ ] Add offline speech recognition fallback
- [ ] Add noise cancellation
- [ ] Add visual waveform animation during recording
- [ ] Add voice activation (hands-free mode)
- [ ] Add voice command shortcuts ("send", "cancel", etc.)

## Troubleshooting

### Permission Issues
If microphone permission is denied:
1. Ask user to open app settings
2. Enable microphone permission manually
3. Restart app

### Speech Recognition Not Working
- Check internet connection (cloud-based recognition)
- Verify microphone hardware is functional
- Check if another app is using microphone
- Restart speech service: `_speech.stop()` then `_speech.initialize()`

### TTS Not Speaking
- Check device volume is not muted
- Verify TTS engine is available on device
- Try different speech rate
- Check if another app is playing audio

### Audio Conflicts
If audio from multiple sources conflicts:
- Stop any playing TTS before starting speech recognition
- Queue TTS messages instead of playing simultaneously
- Implement proper audio session management

## Related Files
- `lib/pages/ai_chat_page.dart` - Main implementation
- `lib/controllers/gemini_controller.dart` - Chat logic
- `pubspec.yaml` - Package dependencies
- `android/app/src/main/AndroidManifest.xml` - Android permissions
- `ios/Runner/Info.plist` - iOS permissions
