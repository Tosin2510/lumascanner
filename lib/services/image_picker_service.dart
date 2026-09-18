import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<List<XFile>> pickMultipleImageFromGallery() async {
    return _picker.pickMultiImage();
  }

  Future<XFile?> pickSingleImageFromGallery() async {
    return _picker.pickImage(source: ImageSource.gallery);
  }
}