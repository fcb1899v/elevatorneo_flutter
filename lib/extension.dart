// ===== Extension methods for LETS ELEVATOR NEO =====
// String, BuildContext, int, List<int>, List<String>, bool, List<bool>, List<T>.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'constant.dart';

part 'l10n_extension.dart';
part 'size_extension.dart';

// ===== StringExt: String, SharedPreferences, image path and style helpers =====
extension StringExt on String {

  // --- Debug Utilities ---
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  // --- SharedPreferences Helpers ---
  // All methods include debug logging
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }

  // --- Image Path Helpers ---
  // Methods for creating and managing image assets and file-based images
  Image cropperImage() => Image.file(File(this), fit: BoxFit.cover);
  Image fittedAssetImage() => Image.asset(this, fit: BoxFit.cover);
  Image roomImage() => contains("image_cropper") ? cropperImage(): fittedAssetImage();

  // --- Elevator Style Helpers ---
  // Methods for generating elevator component image paths based on style and configuration
  String elevatorFrame(bool isOutside) => "${assetsElevator}elevatorFrame_$this${isOutside ? "Outside": ""}.png";
  String doorFrame() => "${assetsElevator}doorFrame_$this.png";
  String leftDoor(String glassStyle) => "${assetsElevator}doorLeft_$this${glassStyle == "use" ? "WithGlass": ""}.png";
  String rightDoor(String glassStyle) => "${assetsElevator}doorRight_$this${glassStyle == "use" ? "WithGlass": ""}.png";
  String backGroundImage(String glassStyle) => "$assetsSettings${this}Background${glassStyle == "use" ? "WithGlass": ""}.png";
  String insideElevator() => "${assetsElevator}inside_$this.png";

  // --- Button Shape Helpers ---
  // Methods for managing button shape configurations and indices
  int buttonShapeIndex() => buttonShapeList.contains(this) ? buttonShapeList.indexOf(this): 0;
}

// ===== ContextExt: BuildContext and UI helpers =====
// (localization -> L10nContextExt in l10n_extension.dart)
extension ContextExt on BuildContext {
  // --- Navigation & UI Basics ---
  // Core navigation and UI utility methods for screen management and responsive design
  void pushFadeReplacement(Widget page) {
    AudioManager().playEffectSound(asset: changeSound, volume: 1.0);
    Navigator.pushAndRemoveUntil(this, PageRouteBuilder(
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 500),
    ),
    (route) => false);
  }
  /// Push over the current screen, keeping it underneath. The purchase page
  /// has to come back to whatever opened it: the menu, or a settings tab with
  /// a lock the user just tapped. pushFadeReplacement would erase that
  void pushPage(Widget page) {
    AudioManager().playEffectSound(asset: changeSound, volume: 1.0);
    Navigator.push(this, PageRouteBuilder(
      // Not opaque: HomePage stays painted underneath.
      // Its banner, on HomePage's own Stack, keeps showing through the strip the page leaves.
      opaque: false,
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }
  Orientation orientation() => MediaQuery.of(this).orientation;
  void popPage() => Navigator.pop(this);
}


// ===== IntExt: Integer utilities for floor, button, and elevator logic =====
extension IntExt on int {

  // --- Floor/Rank String Generation ---
  // Methods for generating ordinal suffixes in English and Spanish for floor announcements
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";
  // Spanish ordinal number generation for floor announcements
  String esRankNumber() => //1~199
  (this == 0) ? '':
  (this == 1) ? 'primer ' :
  (this == 2) ? 'segundo ' :
  (this == 3) ? 'tercer ' :
  (this == 4) ? 'cuarto ' :
  (this == 5) ? 'quinto ' :
  (this == 6) ? 'sexto ' :
  (this == 7) ? 'séptimo ' :
  (this == 8) ? 'octavo ' :
  (this == 9) ? 'noveno ' :
  (this == 10) ? 'décimo ' :
  (this == 11) ? 'undécimo ' :
  (this == 12) ? 'duodécimo ' :
  (this == 13) ? 'decimotercero ' :
  (this == 14) ? 'decimocuarto ' :
  (this == 15) ? 'decimoquinto ' :
  (this == 16) ? 'decimosexto ' :
  (this == 17) ? 'decimoséptimo ' :
  (this == 18) ? 'decimoctavo ' :
  (this == 19) ? 'decimonoveno ' :
  (this == 20) ? 'vigésimo ':
  (this < 100) ? esRankNumberOver20():
  esRankNumberOver100();
  String esRankNumberOver20() =>
      (this < 100) ? "${
          (this < 30) ? 'vigésimo ':
          (this < 40) ? 'trigésimo ':
          (this < 50) ? 'cuadragésimo ':
          (this < 60) ? 'quincuagésimo ':
          (this < 70) ? 'sexagésimo ':
          (this < 80) ? 'septuagésimo ':
          (this < 90) ? 'octogésimo ':
          'nonagésimo '
      } ${(this % 10).esRankNumber()} ":
      esRankNumberOver100();
  String esRankNumberOver100() =>
      (this % 100 == 0) ? 'centésimo ':
      'centésimo ${(this % 100).esRankNumber()} ';
  // French ordinal number generation for floor announcements
  String frRankNumber() => //1~199
    (this == 0) ? '':
    (this == 1) ? 'premier ' :
    (this == 2) ? 'deuxième ' :
    (this == 3) ? 'troisième ' :
    (this == 4) ? 'quatrième ' :
    (this == 5) ? 'cinquième ' :
    (this == 6) ? 'sixième ' :
    (this == 7) ? 'septième ' :
    (this == 8) ? 'huitième ' :
    (this == 9) ? 'neuvième ' :
    (this == 10) ? 'dixième ' :
    (this == 11) ? 'onzième ' :
    (this == 12) ? 'douzième ' :
    (this == 13) ? 'treizième ' :
    (this == 14) ? 'quatorzième ' :
    (this == 15) ? 'quinzième ' :
    (this == 16) ? 'seizième ' :
    (this == 17) ? 'dix-septième ' :
    (this == 18) ? 'dix-huitième ' :
    (this == 19) ? 'dix-neuvième ' :
    (this == 20) ? 'vingtième ':
    (this < 100) ? frRankNumberOver20():
    frRankNumberOver100();
  String frRankNumberOver20() =>
    (this < 100) ? "${
      (this < 30) ? 'vingtième ':
      (this < 40) ? 'trentième ':
      (this < 50) ? 'quarantième ':
      (this < 60) ? 'cinquantième ':
      (this < 70) ? 'soixantième ':
      (this < 80) ? 'soixante-dixième ':
      (this < 90) ? 'quatre-vingtième ':
      'quatre-vingt-dixième '
    } ${(this % 10).frRankNumber()} ":
    frRankNumberOver100();
  String frRankNumberOver100() =>
    (this % 100 == 0) ? 'centième ':
    'centième ${(this % 100).frRankNumber()} ';

  // --- Settings & Button Helpers ---
  // Methods for managing settings UI and button image paths based on style configurations
  String selected(int i) => (this == i) ? "Pressed": "";
  String settingsButton(int i) => "$assetsSettings${settingsItemList[i]}Settings${selected(i)}.png";
  String openButton() => "${assetsButton}open${this + 1}.png";
  String closeButton() => "${assetsButton}close${this + 1}.png";
  String alertButton() => "${assetsButton}phone${this + 1}.png";
  String upButton() => "${assetsButton}up${this + 1}.png";
  String downButton() => "${assetsButton}down${this + 1}.png";
  String pressedOpenButton() => "${assetsButton}open${this + 1}Pressed.png";
  String pressedCloseButton() => "${assetsButton}close${this + 1}Pressed.png";
  String pressedAlertButton() => "${assetsButton}phone${this + 1}Pressed.png";
  String pressedUpButton() => "${assetsButton}up${this + 1}Pressed.png";
  String pressedDownButton() => "${assetsButton}down${this + 1}Pressed.png";

  // --- Elevator Inside Image Generation ---
  // Methods for generating elevator interior images for all floor levels
  List<Image> insideImages(String elevatorStyle) =>
      [for (int i = min; i <= max; i++) if (i != 0) ((this == i) ? elevatorStyle.insideElevator(): imageDark).fittedAssetImage()];

  // --- Display Helpers ---
  // Methods for formatting display text and symbols for elevator status
  String displayNumber(bool isTop) =>
      (isTop || this == 0) ? "":
      (this < 0) ? "${abs()}":
      "$this";
  String displayAlphabet(bool isTop) =>
      isTop ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B":
      "";

  // --- Image Display ---
  // Methods for managing arrow and movement indicator images
  String upArrow() => "${assetsElevator}up${this + 1}.png";
  String downArrow() => "${assetsElevator}down${this + 1}.png";
  String arrowImage(bool isMoving, int nextFloor, int buttonStyle) =>
      (isMoving && this < nextFloor) ? buttonStyle.upArrow():
      (isMoving && this > nextFloor) ? buttonStyle.downArrow():
      transpImage;

  // --- Speed Calculation ---
  // Methods for calculating elevator movement speed based on distance and operation count
  int elevatorSpeed(int count, int nextFloor) {
    int l = (this - nextFloor).abs();
    return (count < 2 || l < 2) ? 2000:
    (count < 5 || l < 5) ? 1000:
    (count < 10 || l < 10) ? 500:
    (count < 20 || l < 20) ? 250: 100;
  }

  // --- Button Logic ---
  /// Generate button text (R roof, G ground, B+number basement, number for floors)
  String buttonNumber(bool isTop) =>
      isTop ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";
  /// Check if this floor is currently selected in the button lists
  bool isSelected(List<bool> isAboveSelectedList, isUnderSelectedList) =>
      (this > 0) ? isAboveSelectedList[this]: isUnderSelectedList[this * (-1)];
  /// Clear all floor selections above the current floor (used when elevator moves up)
  void clearUpperFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = max; j > this - 1; j--) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }
  /// Clear all floor selections below the current floor (used when elevator moves down)
  void clearLowerFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = min; j < this + 1; j++) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }
  /// Get list of floors from current floor to target floor when moving upward
  List<int> upFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this + 1; i < nextFloor + 1; i++) {
      floorList.add(i);
    }
    return floorList;
  }
  /// Get list of floors from current floor to target floor when moving downward
  List<int> downFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this - 1; i > nextFloor - 1; i--) {
      floorList.add(i);
    }
    return floorList;
  }
  /// Find the next floor to visit when elevator is moving upward
  /// Prioritizes floors above current position, then wraps to lowest selected floor
  int upNextFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    int nextFloor = max;
    // First, look for selected floors above current position
    for (int k = this + 1; k < max + 1; k++) {
      bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (k < nextFloor && isSelected) nextFloor = k;
    }
    // If no floors found above, check if max floor is selected
    if (nextFloor == max) {
      bool isMaxSelected = max.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (isMaxSelected) {
        nextFloor = max;
      } else {
        // Wrap around to lowest selected floor
        nextFloor = min;
        bool isMinSelected = min.isSelected(isAboveSelectedList, isUnderSelectedList);
        for (int k = min; k < this; k++) {
          bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
          if (k > nextFloor && isSelected) nextFloor = k;
        }
        if (isMinSelected) nextFloor = min;
      }
    }
    // Check if any floors are selected at all
    bool allFalse = true;
    for (int k = 0; k < isAboveSelectedList.length; k++) {
      if (isAboveSelectedList[k]) allFalse = false;
    }
    for (int k = 0; k < isUnderSelectedList.length; k++) {
      if (isUnderSelectedList[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }
  /// Find the next floor to visit when elevator is moving downward
  /// Prioritizes floors below current position, then wraps to highest selected floor
  int downNextFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    int nextFloor = min;
    // First, look for selected floors below current position
    for (int k = min; k < this; k++) {
      bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (k > nextFloor && isSelected) nextFloor = k;
    }
    // If no floors found below, check if min floor is selected
    if (nextFloor == min) {
      bool isMinSelected = min.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (isMinSelected) {
        nextFloor = min;
      } else {
        // Wrap around to highest selected floor
        nextFloor = max;
        bool isMaxSelected = max.isSelected(isAboveSelectedList, isUnderSelectedList);
        for (int k = max; k > this; k--) {
          bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
          if (k < nextFloor && isSelected) nextFloor = k;
        }
        if (isMaxSelected) nextFloor = max;
      }
    }
    // Check if any floors are selected at all
    bool allFalse = true;
    for (int k = 0; k < isAboveSelectedList.length; k++) {
      if (isAboveSelectedList[k]) allFalse = false;
    }
    for (int k = 0; k < isUnderSelectedList.length; k++) {
      if (isUnderSelectedList[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }
  /// Mark this floor as selected in the appropriate button list
  void trueSelected(List<bool> isAboveSelectedList, isUnderSelectedList) {
    if (this > 0) isAboveSelectedList[this] = true;
    if (this < 0) isUnderSelectedList[this * (-1)] = true;
  }
  /// Mark this floor as not selected in the appropriate button list
  void falseSelected(List<bool> isAboveSelectedList, isUnderSelectedList) {
    if (this > 0) isAboveSelectedList[this] = false;
    if (this < 0) isUnderSelectedList[this * (-1)] = false;
  }
  /// Check if this floor is the only selected floor in all button lists
  bool onlyTrue(List<bool> isAboveSelectedList, isUnderSelectedList) {
    bool listFlag = false;
    if (isSelected(isAboveSelectedList, isUnderSelectedList)) listFlag = true;
    if (this > 0) {
      // Check if any other floors are selected
      for (int k = 0; k < isAboveSelectedList.length; k++) {
        if (k != this && isAboveSelectedList[k]) listFlag = false;
      }
      for (int k = 0; k < isUnderSelectedList.length; k++) {
        if (isUnderSelectedList[k]) listFlag = false;
      }
    }
    if (this < 0) {
      // Check if any other floors are selected
      for (int k = 0; k < isUnderSelectedList.length; k++) {
        if (k != this * (-1) && isUnderSelectedList[k]) listFlag = false;
      }
      for (int k = 0; k < isAboveSelectedList.length; k++) {
        if (isAboveSelectedList[k]) listFlag = false;
      }
    }
    return listFlag;
  }
  
  // --- Room Image Helpers ---
  // Methods for managing room images and floor-to-room mappings
  bool isButtonContain(List<int> floorNumbers) => floorNumbers.contains(this);
  String roomImageFile(List<int> floorNumbers, List<String> rooms) => rooms[floorNumbers.indexOf(this)];
  Image roomImage(List<int> floorNumbers, List<String> rooms) =>
    (!isButtonContain(floorNumbers)) ? imageFloor.fittedAssetImage():
      roomImageFile(floorNumbers, rooms).roomImage();
}

// ===== ListIntExt: List<int> helpers for floor and button matrix =====
extension ListIntExt on List<int> {

  // --- Floor Matrix Helpers ---
  // Methods for converting flat floor number lists to 2D matrix format for UI display
  List<List<int>> floorNumbersList() => [
    [this[8], this[9]],
    [this[6], this[7]],
    [this[4], this[5]],
    [this[2], this[3]],
    [this[1], this[0]],
  ];

  /// A button sits between its neighbours, except the two ends. The bottom one
  /// runs down to min, and the top one up to max; their other limit comes from
  /// how many buttons have to fit on the far side of the fixed 1F
  /// The picker stops at the neighbouring buttons, so no other floor has to move
  int selectFirstFloor(int row, int col) {
    final i = reversedButtonIndex[row][col];
    // this[i - 1] is never -1 unless i is 1F, which cannot be selected.
    // So the result never lands on floor 0, which does not exist.
    if (i == 0) return min;
    return this[i - 1] + 1;
  }
  int selectLastFloor(int row, int col) {
    final i = reversedButtonIndex[row][col];
    if (i == floorButtonCount - 1) return max;
    final last = this[i + 1] - 1;
    return (last == 0) ? -1 : last;
  }
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}

// ===== ListStringExt: List<String> helpers for room images and names =====
extension ListStringExt on List<String> {

  // --- Room Matrix Helpers ---
  // Methods for converting flat room name lists to 2D matrix format for UI display
  List<List<String>> roomsList() => [
    [this[8], this[9]],
    [this[6], this[7]],
    [this[4], this[5]],
    [this[2], this[3]],
    [this[1], this[0]],
  ];
  // Methods for generating floor images and managing room image selections
  List<Image> floorImages(List<int> floorNumbers) =>
      [for (int i = min; i <= max; i++) if (i != 0) i.roomImage(floorNumbers, this)];

  // --- Room Image Selection ---
  // Methods for managing room image availability and selection logic
  Iterable<String> remainIterable(List<String> roomImages, int buttonIndex) =>
      where((image) => !roomImages.contains(image) || roomImages[buttonIndex] == image);
  int roomIndex(List<String> roomImages, int buttonIndex) =>
      indexOf(roomImages[buttonIndex]);
  int remainIndex(List<String> roomImages, int buttonIndex) =>
      indexOf(remainImage(roomImages, buttonIndex));
  String remainImage(List<String> roomImages, int buttonIndex) =>
      remainIterable(roomImages, buttonIndex).toList()[0];
  String selectedRoomImage(List<String> roomImages, int buttonIndex) =>
      (roomIndex(roomImages, buttonIndex) == -1) ?
      remainImage(roomImages, buttonIndex):
      roomImages[buttonIndex];
  
  // --- Room Name Helpers ---
  // Methods for retrieving and managing room names based on image mappings
  String roomName(BuildContext context, String image) =>
      context.roomNameList()[floorImageList.indexOf(image)];
}

// ===== BoolExt: Boolean helpers for UI and logic =====
extension BoolExt on bool {

  // --- Button State Helpers ---
  // Methods for managing button pressed states and generating appropriate image paths
  String pressed() => this ? 'Pressed': '';
  String numberBackground(int buttonStyle, String buttonShape) => "$assetsButton$buttonShape${buttonStyle + 1}${pressed()}.png";
  String openBackGround(int buttonStyle) => this ? buttonStyle.pressedOpenButton(): buttonStyle.openButton();
  String closeBackGround(int buttonStyle) => this ? buttonStyle.pressedCloseButton(): buttonStyle.closeButton();
  String phoneBackGround(int buttonStyle) => this ? buttonStyle.pressedAlertButton(): buttonStyle.alertButton();
  String upBackGround(int buttonStyle) => this ? buttonStyle.pressedUpButton(): buttonStyle.upButton();
  String downBackGround(int buttonStyle) => this ? buttonStyle.pressedDownButton(): buttonStyle.downButton();
  Color numberColor(int i) => this ? numberColorList[i]: whiteColor;
  Color floorButtonNumberColor(String buttonShape) => numberColor(buttonShape.buttonShapeIndex());

  // --- Button Shape Factors ---
  // Methods for calculating UI scaling factors based on button shape configurations
  double floorButtonShapeFactor() => this ? 1.2: 1;
  double buttonMarginShapeFactor() => this ? 0.5: 1;
  double operationTopMarginShapeFactor() => this ? 3: 1.6;
  double operationSideMarginShapeFactor() => this ? 1.8: 0.8;
  double emergencyBottomMarginShapeFactor() => this ? 1.8: 0.8;
}

// ===== ListBoolExt: List<bool> helpers for button images =====
extension ListBoolExt on List<bool> {

  // --- Operation Button Images ---
  // Methods for generating operation button image lists based on button states and styles
  List<String> operationButtonImage(int buttonStyle) => [
    this[0].openBackGround(buttonStyle),
    this[1].closeBackGround(buttonStyle),
    this[2].phoneBackGround(buttonStyle),
  ];

  List<bool> setOperationButtonLamp(bool isOn, int i) => [
    (i == 0) ? isOn: this[0],
    (i == 1) ? isOn: this[1],
    (i == 2) ? isOn: this[2],
  ];
}

// ===== ListDynamicExt: Generic List<T> matrix helpers =====
extension ListDynamicExt<T> on List<T> {

  // --- Matrix Conversion ---
  // Generic methods for converting lists to matrix formats with various configurations
  List<List<T>> toMatrix(int n) =>
      [for (var i = 0; i < length; i += n) sublist(i, (i + n <= length) ? i + n : length)];
  List<List<T>> toReversedMatrix(int n) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += n) {
      final end = (i + n).clamp(0, length);
      final chunk = (i == 0) ? sublist(i, end).reversed.toList(): sublist(i, end);
      chunks.add(chunk);
    }
    return chunks.reversed.toList();
  }
}
