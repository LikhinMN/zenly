# Zenly

A minimal voice-to-text app built with Flutter. Record speech, stream it to Groq Whisper for transcription, optionally refine it with Gemini, and save/share transcripts locally.

## Features
- One-tap recording with live waveform and timer.
- Chunked speech capture with voice activity detection to skip silence.
- Cloud transcription using Groq Whisper (`whisper-large-v3`).
- Optional transcript cleanup/refinement using Gemini.
- Local transcript history stored in Hive with delete/share/copy.

## How It Works
1. Audio is recorded in 5-second chunks.
2. A speech detector filters out low-signal chunks.
3. Valid chunks are sent to Groq for transcription and merged live.
4. On stop, the transcript is shown, can be refined, saved, and shared.

## Tech Stack
- Flutter + Dart
- State: `flutter_riverpod`
- Storage: `hive` / `hive_flutter`
- Audio: `record`
- HTTP: `dio`
- Sharing: `share_plus`
- Env config: `flutter_dotenv`

## Project Structure
- `lib/main.dart`: App entry point and theme.
- `lib/features/recording/`: Recording UI and flow.
- `lib/features/transcription/`: Transcript UI + improvement logic.
- `lib/shared/services/`: Recording, speech detection, storage, API clients.
- `assets/`: App icons and splash assets.

## Setup
### Prerequisites
- Flutter SDK (Dart 3.11+)
- Android Studio or a connected device/emulator

### Environment Variables
Create a `.env` file in the project root:

```env
GROQ_TOKEN=your_groq_api_key
GEMINI_API_KEY=your_gemini_api_key
```

Both keys are required for transcription + refinement. If you only need transcription, you can leave `GEMINI_API_KEY` empty and skip the refine action.

### Install Dependencies
```sh
flutter pub get
```

### Run
```sh
flutter run
```

## Permissions
- Android: `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE` are declared in `android/app/src/main/AndroidManifest.xml`.
- iOS: add `NSMicrophoneUsageDescription` in `ios/Runner/Info.plist` if you plan to run on iOS.

## Usage
- Tap the mic button to start recording.
- Speak; the live transcript updates as chunks complete.
- Tap stop to view the transcript, optionally refine it, then save/share.
- Saved transcripts appear on the home list and can be deleted by swiping.

## Troubleshooting
- If transcription fails, confirm the `.env` keys are present and valid.
- If the mic permission dialog does not appear, check OS settings.
- If transcripts are empty, try speaking louder or longer to pass the speech detector thresholds.

## Development Notes
- Transcripts are stored locally in Hive (`transcripts` box).
- Chunk duration is set to 5s in `RecordingScreen`.
- Speech detection thresholds are configurable in `SpeechDetectorConfig`.

## License
This project is currently private and not configured for publishing.
