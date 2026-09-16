import 'package:camera/camera.dart';

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

// Initialize the devicee camera and make the controller the back camera
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
    final image = await controller!.takePicture();
    return image.path;
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}