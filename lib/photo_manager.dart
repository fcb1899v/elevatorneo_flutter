// =============================
// PhotoManager: Photo selection and processing for elevator simulator
//
// Handles photo selection from gallery, cropping, and permission management.
// Key features: gallery selection, aspect ratio cropping, permission handling
// =============================

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constant.dart';
import 'extension.dart';
import 'image_manager.dart';

class PhotoManager {

  final BuildContext context;

  PhotoManager({required this.context});

  // --- Photo Selection and Processing ---

  /// Select and crop image from gallery with 9:16 aspect ratio
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

  // --- Permission Management ---

  /// Show permission alert dialog for photo access
  void photoPermissionAlert() => showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.photoAccessRequired(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.settingsAlertTitleFontSize(),
          fontFamily: context.font(),
        ),
      ),
      content: Text(context.photoAccessPermission(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.settingsAlertFontSize(),
          fontFamily: context.font(),
        ),
      ),
      actions: [
        TextButton(
          child: Text(context.ok(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
          onPressed: () => openAppSettings(),
        ),
        TextButton(
          child: Text(context.cancel(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
          onPressed: () => context.popPage(),
        ),
      ],
    ),
  );

  // --- Photo Selection Workflow ---

  /// Complete photo selection workflow with permission handling
  Future<List<String>> selectMyPhoto({
    required int row,
    required int col,
    required List<String> currentList
  }) async {
    final photoPermission = await Permission.photos.status;
    "photoPermission: $photoPermission";
    if (Platform.isAndroid || photoPermission.isGranted) {
      final String? savedImagePath = await pickAndCropImage(row, col);
      return ImageManager().saveImagePath(
        currentList: currentList,
        newValue: savedImagePath,
        newIndex: buttonIndex(row, col),
      );
    } else if (photoPermission.isDenied) {
      await Permission.photos.request();
      return currentList;
    } else {
      photoPermissionAlert();
      return currentList;
    }
  }
} 