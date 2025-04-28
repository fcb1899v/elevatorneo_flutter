import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

/// For Photo
class PhotoManager {

  final BuildContext context;

  PhotoManager({required this.context});

  Future<String?> pickAndCropImage(int row, int col) async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: (context.mounted) ? context.cropPhoto() : "",
            toolbarColor: whiteColor,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: (context.mounted) ? context.cropPhoto() : "",
          ),
          if (context.mounted) WebUiSettings(context: context),
        ],
      );
      if (croppedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = path.basename(croppedFile.path);
        final File croppedImage = await File(croppedFile.path).copy('${directory.path}/$fileName');
        final String croppedImagePath = croppedImage.path;
        if (croppedImagePath.contains('assets/images/room/')) {
          "croppedImage: $croppedImagePath".debugPrint();
          return croppedImagePath;
        } else {
          "croppedImage: ${path.basename(croppedImagePath)}".debugPrint();
          return path.basename(croppedImagePath);
        }
      } else {
        return null;
      }
    }
    return null;
  }
}

class ImageManager {

  Future<List<String>> getImagesList() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final images = prefs.getStringList("roomsKey") ?? initialRoomImages;
    for (int i = 0; i < images.length; i++) {
      if (!(images[i].contains("assets/images/room/"))) {
        final newPath = path.join(directory.path, images[i]);
        if (await File(newPath).exists()) images[i] = newPath;
      }
    }
    "Show images: $images".debugPrint();
    return images;
  }
}