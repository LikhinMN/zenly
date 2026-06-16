# Zenly

A calm, minimal voice-to-text application and system-wide Android keyboard. Built with Flutter for the main UI and native Kotlin for the Android Input Method Service (IME), Zenly allows you to effortlessly capture thoughts via voice and transcribe them locally or directly into any app using Groq Whisper.

## Features

### 🎙️ Main App (Flutter)
- **Calm Focus UI**: A minimal, distraction-free interface built around a single accent color.
- **Reliable Recording**: One-tap recording with dynamic waveform visuals.
- **Accurate Transcription**: Powered by Groq's `whisper-large-v3` model.
- **History Management**: Locally stored transcripts using Hive with swipe-to-delete.
- **Onboarding & Settings**: Smooth first-launch experience with easy API key management and deep-links to Android keyboard settings.

### ⌨️ Zenly Voice Keyboard (Native Android Kotlin)
- **Type Anywhere**: A system-wide Android custom keyboard that allows you to dictate text into *any* app's text field.
- **Voice-First Design**: A prominent mic button and live audio waveform integrated directly into the keyboard.
- **Manual Key Row**: Includes essential manual keys (Space, Backspace, Enter, and Globe/Switch Keyboard) for quick edits without switching back to a standard QWERTY keyboard.
- **Fast & Lightweight**: Built natively in Kotlin to avoid the cold-start and memory overhead of embedding a Flutter engine in an IME.
- **Shared State**: Securely syncs your API keys from the Flutter app via `EncryptedSharedPreferences`.

## How It Works
1. Audio is recorded and voice activity detection (VAD) monitors silence.
2. Once recording stops, the audio file is sent directly to Groq for near-instant transcription.
3. In the main app, the transcript is saved to history and can be refined or shared.
4. In the keyboard, the transcribed text is automatically injected into the active text field using Android's `InputConnection`.

## Tech Stack
- **Main App**: Flutter + Dart
- **Native Keyboard**: Kotlin + Android SDK (`InputMethodService`)
- **State Management**: `flutter_riverpod`
- **Storage**: `hive` / `hive_flutter` + Android `EncryptedSharedPreferences`
- **Audio Capture**: `record` (Flutter) + `AudioRecord` (Kotlin)
- **Networking**: `dio` (Flutter) + `OkHttp` (Kotlin)
- **Environment**: `flutter_dotenv`

## Setup

### Prerequisites
- Flutter SDK (Dart 3.11+)
- Android Studio or a connected Android device/emulator
- **Note**: Zenly is currently Android-only. Support for iOS, Web, and Desktop has been removed to focus on the native Android keyboard experience.

### Environment Variables
Create a `.env` file in the project root:

```env
GROQ_TOKEN=your_groq_api_key
GEMINI_API_KEY=your_gemini_api_key
```

### Install Dependencies
```sh
flutter pub get
```

### Run
```sh
flutter run
```

## Enabling the Keyboard
1. Launch the Zenly app and complete the onboarding flow to grant Microphone permissions and sync your API keys.
2. Tap "Open Keyboard Settings" in the app (or go to Android Settings > System > Languages & input > On-screen keyboard).
3. Toggle on **Zenly Voice Keyboard**.
4. Open any app with a text field, switch to the Zenly keyboard using the system globe icon, and tap the mic to start dictating!

## Development Notes
- **App/IME Bridge**: The Flutter app syncs the Groq token to the native IME via a `MethodChannel` inside `MainActivity.kt`.
- **UI Architecture**: The Flutter app uses `MainScaffold` for bottom-tab navigation and `AppTheme` for its central design language.
- **Native IME Code**: All native keyboard logic, including VAD and OkHttp requests, is located in `android/app/src/main/kotlin/com/likhinmn/zenly/ime/`.

## License
This project is currently private and not configured for publishing.
