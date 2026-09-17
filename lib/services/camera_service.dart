import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraService{
  // Class variables
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  List<CameraDescription> get cameras => _cameras;

// Check if the camera controller is null or uninitialized, and throw an exception or else, the controller is returned.
  CameraController? get controller {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('Camera is not initialized');
    }
    return _cameraController!;
  }

// Initialize the devicee camera and make the controllser the back camera
// If the back camera is not available, then use the first camera.
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false
    );

    return _cameraController!.initialize();
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
    await _cameraController?.dispose();
    _cameraController = null;
  }
}