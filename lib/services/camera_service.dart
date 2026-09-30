import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService{
  CameraController? cameraController;
  List<CameraDescription> _cameras = [];
  List<CameraDescription> get cameras => _cameras; // Added this getter for the list of accessible cameras on a device.

  CameraController? get controller {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception('Camera is not initialized');
    }
    return cameraController!;
  }

// If the back camera is not available, then the first camera available should be used.
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first
    );

    cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false
    );

    return cameraController!.initialize();
  }

  Future<void> setFlashLight(FlashMode flash) async {
    await controller!.setFlashMode(flash);
  }

  Future<String> capturePhoto() async {
    final XFile image = await controller!.takePicture();
    final appDir = await getApplicationDocumentsDirectory();
    final scanDocsDir = Directory(path.join(appDir.path, 'scan_docs'));
    if (!await scanDocsDir.exists()) {
      await scanDocsDir.create(recursive: true);
    }
    final name = 'scan${DateTime.now().millisecondsSinceEpoch}.jpg';
    final anotherPath = path.join(scanDocsDir.path, name);
    await File(image.path).copy(anotherPath);
    await File(image.path).delete();

    return anotherPath;
  }

  Future<void> dispose() async {
    await cameraController?.dispose();
    cameraController = null;
  }
}