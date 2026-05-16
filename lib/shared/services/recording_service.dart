import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  // Request mic permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Start recording — saves to app temp directory
  Future<String?> startRecording() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    final dir = await getTemporaryDirectory();
    final filePath = p.join(
      dir.path,
      'zenly_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    return filePath;
  }

  // Stop recording
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  // Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Clean up
  void dispose() {
    _recorder.dispose();
  }
}
