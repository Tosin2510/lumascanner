import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker picker = ImagePicker();

  Future<List<XFile>> pickMultipleImageFromGallery() async {
    return picker.pickMultiImage();
  }

  Future<XFile?> pickSingleImageFromGallery() async {
    return picker.pickImage(source: ImageSource.gallery);
  }
}