// ===== ImageManager: image list, settings persistence and floor configuration =====

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

/// Bundled images stay as asset paths; anything else is a photo in Documents
bool isBundledImage(String value) => value.contains(assetsRoom);

/// The form saved to storage: bundled paths as-is, photos as a file name only
String storedImagePath(String value) {
  if (isBundledImage(value)) return value;
  return path.basename(value);
}

/// The form read from storage: photos joined to the current Documents path
String resolvedImagePath(String stored, String documentsPath) {
  if (isBundledImage(stored)) return stored;
  return path.join(documentsPath, path.basename(stored));
}

Future<String> _defaultDocumentsPath() async {
  return (await getApplicationDocumentsDirectory()).path;
}

class ImageManager {
  ImageManager({Future<String> Function()? documentsPathProvider})
      : _documentsPath = documentsPathProvider ?? _defaultDocumentsPath;

  // Injected so tests can point Documents at a temporary folder
  final Future<String> Function() _documentsPath;

  // --- Image List Management ---

  /// Load and validate floor image list from storage
  Future<List<String>> getImagesList() async {
    final prefs = await SharedPreferences.getInstance();
    final documentsPath = await _documentsPath();
    final stored = prefs.getStringList("floorsKey");
    if (stored == null) return initialFloorImages;
    final images = List<String>.from(stored);
    for (int i = 0; i < images.length; i++) {
      if (!isBundledImage(images[i])) {
        final newPath = resolvedImagePath(images[i], documentsPath);
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
    // The picker offers only the gap between neighbouring buttons, so only it is accepted.
    // Nothing else has to move.
    if (!isInFloorGap(currentList, newIndex, newValue)) return currentList;
    final newList = List<int>.from(currentList)..[newIndex] = newValue;
    final prefs = await SharedPreferences.getInstance();
    "newNumber: $newValue".debugPrint();
    "numbersKey".setSharedPrefListInt(prefs, newList);
    return newList;
  }

  /// Save floor stop configuration
  Future<List<bool>> saveFloorStops({
    required List<bool> currentList,
    required bool newValue,
    required int newIndex,
  }) async {
    if (!newValue && isOnlyStop(currentList, newIndex)) return currentList;
    final prefs = await SharedPreferences.getInstance();
    final newList = List<bool>.from(currentList);
    newList[newIndex] = newValue;
    "newStop: $newValue".debugPrint();
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
      // Every entry is stored in the file-name form, not only the one replaced
      final newList = currentList.map(storedImagePath).toList();
      newList[newIndex] = storedImagePath(newValue);
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