// =============================
// ImageManager: Image and settings management for elevator simulator
//
// Handles image list management, settings persistence, and floor configuration.
// Key features: image storage, settings persistence, floor configuration
// =============================

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

class ImageManager {

  // --- Image List Management ---

  /// Load and validate floor image list from storage
  Future<List<String>> getImagesList() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final images = prefs.getStringList("floorsKey");
    if (images == null) return initialFloorImages;
    for (int i = 0; i < images.length; i++) {
      if (!(images[i].contains("assets/images/room/"))) {
        final newPath = path.join(directory.path, images[i]);
        images[i] = (await File(newPath).exists()) ? newPath: initialFloorImages[i];
        "newPath[$i]: ${images[i]}".debugPrint();
      }
    }
    "getImagesList: $images".debugPrint();
    return images;
  }

  // --- Floor Configuration Management ---

  /// Save floor number with validation (no duplicates, range check)
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

  /// Save floor stop configuration
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

  /// Save image path with persistence
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

  // --- Settings Persistence ---

  /// Save string setting if value changed
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

  /// Save integer setting if value changed
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