import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/services/image_picker_service.dart';
import 'package:lumascanner/scan_preview_screen.dart';
import 'package:lumascanner/services/camera_service.dart';

class CameraScreen extends StatefulWidget{
  final bool returnPreviewPages;
  const CameraScreen({super.key, this.returnPreviewPages = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver{
  final List<XFile> captured = [];
  final ImagePickerService imagePickerService = ImagePickerService();
  final cameraService = CameraService();
  bool isReady = false;
  bool permissionDenied = false;
  bool isFlashOn = false;
  bool suggestLowLight = false;
  DateTime luminanceCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      await cameraService.initializeCamera();
      if (mounted) {
        setState((){
          isReady = true;
        });
       startMonitoring();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          permissionDenied = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraService.controller?.stopImageStream();
    cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      cameraService.dispose();
      setState(() {
        isReady = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Widget circleIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18)
      )
    );
  }

  void startMonitoring() {
    cameraService.controller!.startImageStream((CameraImage image) {
    if (DateTime.now().difference(luminanceCheck) < const Duration(seconds: 1)) return;
    luminanceCheck = DateTime.now();

    final brightness = avgLuminance(image);

    final isDark = brightness < 60; 
    if (isDark != suggestLowLight && mounted) {
      setState(() => suggestLowLight = isDark && !isFlashOn);
    }
  });
}

double avgLuminance(CameraImage image) {
  final yPlane = image.planes[0].bytes;
  int totalVal = 0;
  for (int i = 0; i < yPlane.length; i += 10) {
    totalVal += yPlane[i];
  }
  return totalVal / (yPlane.length / 10);
}


  Future<void> onCapture() async {
    try {
      final imagePath = await cameraService.capturePhoto();
      setState(() {
        captured.add(XFile(imagePath));
      });
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> controlFlash() async {
  if (cameraService.controller == null || !cameraService.controller!.value.isInitialized) {
    return;
  }

  try {
    final flashState = isFlashOn ? FlashMode.off : FlashMode.torch;
    await cameraService.setFlashLight(flashState);

    if (mounted) {
      setState(() => isFlashOn = !isFlashOn);
    }
  } catch (e) {
    debugPrint('Flash toggle failed: $e');
  }
}

  Future<void> pickImagesFromGallery() async {
    final picked = await imagePickerService.pickMultipleImageFromGallery();
    if (picked.isNotEmpty && mounted) {
      setState(() {
        captured.addAll(picked);
      });
    }
  }

  void openPreviewPages() {
    if (widget.returnPreviewPages) {
      Navigator.pop(context, captured);
      
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanPreviewScreen(images: captured),
        )
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    if (permissionDenied) {
      return const Scaffold(
        body: Center(
          child: Text('Camera permission denied or unavailable.')
        )
      );
    }
    if (!isReady) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator()
        )
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraService.controller!.value.previewSize!.height,
                height: cameraService.controller!.value.previewSize!.width,
                child: CameraPreview(cameraService.controller!),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  circleIconButton(
                    icon: Icons.close,
                    onPressed: () => Navigator.pop(context),
                  ),
                    circleIconButton(
                    icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onPressed: controlFlash,
                  )
                ],
              )
            )
          ),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: importButton(),
                  ),
                  captureButton(),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: reviewButton(),
                  )
                ]
              ),
            ),
          ),
          if (suggestLowLight)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  controlFlash();
                  setState(() => suggestLowLight = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, color: Colors.amber, size: 16),
                      SizedBox(width: 6),
                      Text('Light is low, tap to turn on flash.', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget importButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5)
          ),
          child: IconButton(
            onPressed: pickImagesFromGallery, 
            icon: const Icon(
              Icons.photo_library_outlined,
              color: Colors.white,
              size: 20,
            )
          )
        ),
        const SizedBox(height: 4,),
        const Text('Import', style: TextStyle(color: Colors.white, fontSize: 12))
      ]
    );
  }

  Widget captureButton() {
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: 4)
          ]
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2.5)              
            )
          )
        )
      )
    );
  }

  Widget reviewButton() {
    final hasPages = captured.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: hasPages ? openPreviewPages : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade800,
                  image: hasPages ? DecorationImage(
                    image: FileImage(File(captured.last.path)),
                    fit: BoxFit.cover,
                  )
                  : null
                ),
                child: !hasPages
                  ? const Icon(Icons.insert_drive_file_outlined, color: Colors.white38, size: 18)
                  : null,
              ),
              if (hasPages) 
                Positioned(
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color:  Color(0xFF1D9E75),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                      '${captured.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    )
                  )
                )
            ],
          )
        ),
        const SizedBox(height: 4,),
        Text(
          'Preview',
          style: TextStyle(
            color: hasPages ? Colors.blueAccent: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          )
        )
      ],
    );
  }
}