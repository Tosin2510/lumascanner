import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker picker = ImagePicker();

  Future<List<XFile>> pickMultipleImageFromGallery() async {
    try {
      final pickedImages = await picker.pickMultiImage();
      return pickedImages.where((image) => File(image.path).existsSync()).toList();
    } on PlatformException catch (e) {
      debugPrint('Image pick failed: ${e.code}');
      return [];
    }
  }

  Future<XFile?> pickSingleImageFromGallery() async {
    try {
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return null;
      if (!File(pickedImage.path).existsSync()) return null;
      return pickedImage;
    } on PlatformException catch (e) {
      debugPrint('Image pick failed: ${e.code}');
      return null;
    }
  }
}