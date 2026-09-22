import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/camera_screen.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
    // This part ensures that the camera is initialized before the app starts.
    WidgetsFlutterBinding.ensureInitialized();
    // Checks for available cameras, i only need the back camera in this case.
    cameras = await availableCameras();
  } on CameraException catch (e){
    logError(e.code, e.description);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaScanner',
      home: const CameraScreen(),
    );
  }
}

// This functions is used to log the errors that are related to the camera.
void logError(String code, String? message) {
  debugPrint('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

