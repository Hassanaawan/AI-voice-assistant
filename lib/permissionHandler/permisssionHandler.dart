import 'package:permission_handler/permission_handler.dart';

// ... inside your _VoiceAssistantScreenState class ...

Future<bool> _checkAndRequestPermissions() async {
  var status = await Permission.microphone.status;
  if (status.isDenied) {
    status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    } else {
      print("Microphone permission not granted.");
      // Optionally show a dialog explaining why permission is needed
      return false;
    }
  } else if (status.isGranted) {
    return true;
  } else {
    return false; // Permission permanently denied or restricted
  }
}
