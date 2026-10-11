import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/landing_page.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  try {
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
      home: const LandingPage(),
    );
  }
}

void logError(String code, String? message) {
  debugPrint('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

