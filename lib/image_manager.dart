import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  void photoPermissionAlert() => showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.photoAccessRequired(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.settingsAlertTitleFontSize(),
          fontFamily: normalFont,
        ),
      ),
      content: Text(context.photoAccessPermission(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.settingsAlertFontSize(),
          fontFamily: normalFont,
        ),
      ),
      actions: [
        TextButton(
          child: Text(context.ok(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: normalFont,
              fontWeight: FontWeight.bold
            ),
          ),
          onPressed: () => openAppSettings(),
        ),
        TextButton(
          child: Text(context.cancel(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: normalFont,
            ),
          ),
          onPressed: () => context.popPage(),
        ),
      ],
    ),
  );

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

class ImageManager {

  Future<List<String>> getImagesList() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final images = prefs.getStringList("floorsKey");
    if (images == null) return initialRoomImages;
    for (int i = 0; i < images.length; i++) {
      if (!(images[i].contains("assets/images/room/"))) {
        final newPath = path.join(directory.path, images[i]);
        images[i] = (await File(newPath).exists()) ? newPath: initialRoomImages[i];
        "newPath[$i]: ${images[i]}".debugPrint();
      }
    }
    "getImagesList: $images".debugPrint();
    return images;
  }

  Future<List<int>> saveFloorNumber({
    required List<int> currentList,
    required int newValue,
    required int newIndex,
  }) async {
    if (!currentList.contains(newValue) && newValue != 0 && min <= newValue && newValue <= max) {
      final prefs = await SharedPreferences.getInstance();
      final newList = List<int>.from(currentList);
      newList[newIndex] = newValue;
      "newNumber: $newValue".debugPrint();
      "numbersKey".setSharedPrefListInt(prefs, newList);
      return newList;
    } else {
      return currentList;
    }
  }

  Future<List<bool>> saveFloorStops({
    required List<bool> currentList,
    required bool newValue,
    required int newIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = List<bool>.from(currentList);
    newList[newIndex] = newValue;
    "newNumber: $newValue".debugPrint();
    "stopsKey".setSharedPrefListBool(prefs, newList);
    return newList;
  }

  Future<List<String>> saveImagePath({
    required List<String> currentList,
    required String? newValue,
    required int newIndex,
  }) async {
    if (newValue != null) {
      final prefs = await SharedPreferences.getInstance();
      final newList = List<String>.from(currentList);
      newList[newIndex] = newValue;
      "newPath: $newValue".debugPrint();
      "floorsKey".setSharedPrefListString(prefs, newList);
      final images = await getImagesList();
      return images;
    } else {
      return currentList;
    }
  }

  Future<String> changeSettingsStringValue({
    required String key,
    required String current,
    required String next,
  }) async {
    if (next != current) {
      final prefs = await SharedPreferences.getInstance();
      key.setSharedPrefString(prefs, next);
      return next;
    } else {
      return current;
    }
  }

  Future<int> changeSettingsIntValue({
    required String key,
    required int current,
    required int next,
  }) async {
    if (next != current) {
      final prefs = await SharedPreferences.getInstance();
      key.setSharedPrefInt(prefs, next);
      return next;
    } else {
      return current;
    }
  }
}