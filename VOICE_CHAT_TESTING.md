# Voice Chat Testing Guide

## Quick Test Steps

### Test 1: Speech-to-Text (Microphone Permission)
1. Open AI Chat page
2. Look for purple microphone button next to send button
3. Tap microphone button
4. You should see:
   - Permission dialog requesting microphone access
   - Grant the permission
5. Tap microphone button again
6. You should see:
   - Button turns red
   - "Listening..." banner appears above chat
   - Pulsing shadow effect
7. Speak: "What is my balance?"
8. You should see:
   - Your words appear in the text field in real-time
9. Tap red stop button
10. You should see:
    - Message sent automatically
    - "Listening..." banner disappears
    - AI responds to your message

### Test 2: Auto-Speak AI Response
1. Type a message: "Hello"
2. Send the message
3. Wait for AI response
4. You should hear:
   - AI response is automatically spoken
   - Clear voice with proper English pronunciation

### Test 3: Manual Replay
1. Look at any AI message in the chat
2. Find the small speaker icon next to the timestamp
3. Tap the speaker icon
4. You should hear:
   - Message is spoken again
   - Icon changes from volume_up to volume_off
5. Tap icon again while speaking
6. You should hear:
   - Speaking stops immediately

### Test 4: Image + Voice
1. Tap image button (camera icon)
2. Select a receipt image
3. Tap microphone button
4. Speak: "Scan this receipt"
5. Stop recording
6. You should see:
   - Message with image sent
   - AI analyzes receipt
   - AI response is spoken automatically

### Test 5: Voice Commands
1. Tap microphone
2. Speak: "Set fee for 1 to 500 to 15"
3. Stop recording
4. You should hear:
   - AI confirms the fee change
   - Spoken response

### Test 6: Multiple Voices
1. Send a message and let AI respond (auto-speak)
2. While AI is speaking, tap microphone button
3. Start speaking your next message
4. You should see:
   - Previous TTS stops
   - New recording starts
   - No audio conflicts

## Expected Behaviors

### Microphone Button States
- **Idle**: Purple gradient, microphone icon
- **Listening**: Red gradient, stop icon, pulsing shadow
- **Disabled**: Gray (if permission denied)

### Speaker Button States
- **Idle**: Blue volume_up icon
- **Speaking**: Blue volume_off icon

### Visual Indicators
- **Listening Banner**: Red gradient, "Listening..." text, progress indicator
- **Loading Banner**: Gray, "AI is thinking..." text

### Audio Behaviors
- AI responses auto-speak after generation
- Manual replay works for each message
- Stop speaking works immediately
- Only one audio plays at a time

## Common Issues

### Permission Denied
**Symptom**: Microphone button doesn't respond or shows gray
**Solution**: 
1. Go to device Settings
2. Find app permissions
3. Enable Microphone permission
4. Restart app

### No Transcription
**Symptom**: Recording works but no text appears
**Solution**:
1. Check internet connection
2. Speak clearly and louder
3. Reduce background noise
4. Try again

### No Audio Output
**Symptom**: TTS should play but no sound
**Solution**:
1. Check device volume
2. Check if phone is in silent mode
3. Test with other audio (music, videos)
4. Restart app

### Recognition Inaccurate
**Symptom**: Wrong words transcribed
**Solution**:
1. Speak more slowly
2. Speak more clearly
3. Reduce background noise
4. Use shorter sentences

## Platform-Specific Notes

### Android
- Uses Google Speech Recognition (requires internet)
- Uses Android TTS engine
- Permission dialog shows on first use
- Can change TTS voice in system settings

### iOS
- Uses Apple Speech Recognition (requires internet)
- Uses iOS TTS engine (Siri voice)
- Permission dialog shows on first use
- Respects system voice settings

## Performance Checklist
- [ ] UI remains responsive during recording
- [ ] No lag when starting/stopping recording
- [ ] Smooth button animations
- [ ] Quick transcription (< 1 second delay)
- [ ] Clear audio output
- [ ] No echo or feedback
- [ ] Battery usage reasonable
- [ ] Memory usage stable

## Success Criteria
✅ Microphone permission requested and granted
✅ Speech recognition transcribes accurately
✅ Recording can be stopped manually
✅ Message sends automatically after recording
✅ AI responses auto-speak
✅ Speaker icon appears on AI messages
✅ Manual replay works
✅ Audio stops when requested
✅ Visual indicators show correct states
✅ No crashes or errors

## Next Steps After Testing
1. Gather user feedback on:
   - Voice quality
   - Recognition accuracy
   - Useful features
   - Missing features
2. Consider enhancements:
   - Language selection
   - Voice selection (male/female)
   - Speech rate control
   - Offline mode
   - Voice commands
3. Monitor analytics:
   - Feature usage rate
   - Error frequency
   - User satisfaction
