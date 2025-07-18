// =============================
// Extension Methods for LETS ELEVATOR NEO
//
// 1. StringExt      : String utilities, SharedPreferences helpers, image path helpers, style helpers
// 2. ContextExt     : BuildContext utilities, localization, UI helpers
// 3. IntExt         : Integer utilities for floor, button, and elevator logic
// 4. ListIntExt     : List<int> helpers for floor and button matrix
// 5. ListStringExt  : List<String> helpers for room images and names
// 6. BoolExt        : Boolean helpers for UI and logic
// 7. ListBoolExt    : List<bool> helpers for button images
// 8. ListDynamicExt : Generic List<T> matrix helpers
// =============================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'constant.dart';

// =============================
// StringExt: String utilities, SharedPreferences helpers, image path helpers, style helpers
// =============================
extension StringExt on String {

  // --- Debug Utilities ---
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  // --- SharedPreferences Helpers ---
  // Comprehensive set of methods for storing and retrieving data from SharedPreferences
  // All methods include debug logging for development tracking
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

// =============================
// ContextExt: BuildContext utilities, localization, UI helpers
// =============================
extension ContextExt on BuildContext {

  // --- Navigation & UI Basics ---
  // Core navigation and UI utility methods for screen management and responsive design
  void pushFadeReplacement(Widget page) {
    AudioManager().playEffectSound(asset: changeSound, volume: 1.0);
    Navigator.pushAndRemoveUntil(this, PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 500),
    ),
    (route) => false);
  }
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double widthResponsible() => (width() < height() / 2) ? width(): height() / 2;
  Orientation orientation() => MediaQuery.of(this).orientation;
  void popPage() => Navigator.pop(this);

  // --- Localization & Fonts ---
  // Language detection and font selection based on current locale
  String lang() => Localizations.localeOf(this).languageCode;
  String font() =>
      (lang() == "ja") ? "notoJP":
      (lang() == "zh") ? "notoSC":
      (lang() == "ko") ? "bmDohyeon":
      "roboto";

  // --- Localized Strings ---
  // Comprehensive collection of localized strings for all app features
  // Common app strings
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String openDoor() => AppLocalizations.of(this)!.openDoor;
  String closeDoor() => AppLocalizations.of(this)!.closeDoor;
  String upFloor() => AppLocalizations.of(this)!.upFloor;
  String downFloor() => AppLocalizations.of(this)!.downFloor;
  String pushNumber() => AppLocalizations.of(this)!.pushNumber;
  String emergency() => AppLocalizations.of(this)!.emergency;
  String return1st() => AppLocalizations.of(this)!.return1st;
  String basement(int counter) => (counter < 0) ? AppLocalizations.of(this)!.basement: "";
  String floor(String number) => AppLocalizations.of(this)!.floor(number);
  String notStop() => AppLocalizations.of(this)!.notStop;
  String eVMile() => AppLocalizations.of(this)!.eVMile;
  String eVMileRanking() => AppLocalizations.of(this)!.eVMileRanking;
  String earnMile(String number) => AppLocalizations.of(this)!.earnMile(number);
  String aboutEVMile() => AppLocalizations.of(this)!.aboutEVMile;
  // Room names
  String rooftop() => AppLocalizations.of(this)!.rooftop;
  String vip() => AppLocalizations.of(this)!.vip;
  String restaurant() => AppLocalizations.of(this)!.restaurant;
  String spa() => AppLocalizations.of(this)!.spa;
  String arcade() => AppLocalizations.of(this)!.arcade;
  String foodCourt() => AppLocalizations.of(this)!.foodCourt;
  String indoorPark() => AppLocalizations.of(this)!.indoorPark;
  String supermarket() => AppLocalizations.of(this)!.supermarket;
  String station() => AppLocalizations.of(this)!.station;
  String parking() => AppLocalizations.of(this)!.parking;
  String apparel() => AppLocalizations.of(this)!.apparel;
  String electronics() => AppLocalizations.of(this)!.electronics;
  String outdoor() => AppLocalizations.of(this)!.outdoor;
  String book() => AppLocalizations.of(this)!.bookstore;
  String candy() => AppLocalizations.of(this)!.candy;
  String toy() => AppLocalizations.of(this)!.toy;
  String luxury() => AppLocalizations.of(this)!.luxury;
  String sports() => AppLocalizations.of(this)!.sports;
  String gym() => AppLocalizations.of(this)!.gym;
  String sweets() => AppLocalizations.of(this)!.sweets;
  String furniture() => AppLocalizations.of(this)!.furniture;
  String cinema() => AppLocalizations.of(this)!.cinema;
  // Room image names
  String nameParking() => AppLocalizations.of(this)!.nameParking;
  String nameStation() => AppLocalizations.of(this)!.nameStation;
  String nameSupermarket() => AppLocalizations.of(this)!.nameSupermarket;
  String nameIndoorPark() => AppLocalizations.of(this)!.nameIndoorPark;
  String nameFoodCourt() => AppLocalizations.of(this)!.nameFoodCourt;
  String nameArcade() => AppLocalizations.of(this)!.nameArcade;
  String nameSpa() => AppLocalizations.of(this)!.nameSpa;
  String nameRestaurant() => AppLocalizations.of(this)!.nameRestaurant;
  String nameVip() => AppLocalizations.of(this)!.nameVip;
  String nameRooftop() => AppLocalizations.of(this)!.nameRooftop;
  String nameApparel() => AppLocalizations.of(this)!.nameApparel;
  String nameElectronics() => AppLocalizations.of(this)!.nameElectronics;
  String nameOutdoor() => AppLocalizations.of(this)!.nameOutdoor;
  String nameBook() => AppLocalizations.of(this)!.nameBookstore;
  String nameCandy() => AppLocalizations.of(this)!.nameCandy;
  String nameToy() => AppLocalizations.of(this)!.nameToy;
  String nameLuxury() => AppLocalizations.of(this)!.nameLuxury;
  String nameSports() => AppLocalizations.of(this)!.nameSports;
  String nameGym() => AppLocalizations.of(this)!.nameGym;
  String nameSweets() => AppLocalizations.of(this)!.nameSweets;
  String nameFurniture() => AppLocalizations.of(this)!.nameFurniture;
  String nameCinema() => AppLocalizations.of(this)!.nameCinema;
  // Sound and audio helpers
  String soundPlace(String room) =>
      (room == imageParking) ? parking():
      (room == imageStation) ? station():
      (room == imageSuper) ? supermarket():
      (room == imagePark) ? indoorPark():
      (room == imageFood) ? foodCourt():
      (room == imageArcade) ? arcade():
      (room == imageSpa) ? spa():
      (room == imageRest) ? restaurant():
      (room == imageVip) ? vip():
      (room == imageTop) ? rooftop():
      (room == imageApparel) ? apparel():
      (room == imageElectro) ? electronics():
      (room == imageOutdoor) ? outdoor():
      (room == imageBook) ? book():
      (room == imageCandy) ? candy():
      (room == imageToy) ? toy():
      (room == imageLuxury) ? luxury():
      (room == imageSports) ? sports():
      (room == imageGym) ? gym():
      (room == imageSweets) ? sweets():
      (room == imageFurnit) ? furniture():
      (room == imageCinema) ? cinema():
      "";
  String soundFloor(int counter) =>
      (counter == max) ? "":
      (lang() == "en") ? floor("${counter.enRankNumber()}${basement(counter)}"):
      (lang() == "es") ? "${counter.esRankNumber()}${basement(counter)}":
      (lang() == "fr") ? "${counter.frRankNumber()}${basement(counter)}":
      floor("${basement(counter)}${counter.abs()}");
  String openingSound(int counter, String room) =>
      "${soundFloor(counter)}${soundPlace(room)}${openDoor()}";
  // Room name lists
  List<String> initialRoomName() => [
    nameParking(), nameStation(), nameSupermarket(), nameArcade(), nameFoodCourt(),
    nameBook(), nameSpa(), nameRestaurant(), nameVip(), nameRooftop(),
  ];
  List<String> addRoomName() => [
    nameApparel(), nameElectronics(), nameIndoorPark(), nameOutdoor(), nameCandy(),
    nameToy(), nameLuxury(), nameSports(), nameGym(), nameSweets(),
    nameFurniture(), nameCinema()
  ];
  List<String> roomNameList() => [...initialRoomName(), ...addRoomName()];
  // Menu and settings
  String settings() => AppLocalizations.of(this)!.settings;
  String glass() => AppLocalizations.of(this)!.glass;
  String back() => AppLocalizations.of(this)!.back;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String stop() => AppLocalizations.of(this)!.stop;
  String bypass() => AppLocalizations.of(this)!.bypass;
  String edit() => AppLocalizations.of(this)!.edit;
  String ranking() => AppLocalizations.of(this)!.ranking;
  String changeNumber() => AppLocalizations.of(this)!.changeNumber;
  String changeBasementNumber() => AppLocalizations.of(this)!.changeBasementNumber;
  String changeNumberTitle(bool isBasement) => isBasement ? changeBasementNumber(): changeNumber();
  String changeImage() => AppLocalizations.of(this)!.changeImage;
  String selectPhoto() => AppLocalizations.of(this)!.selectPhoto;
  String cropPhoto() => AppLocalizations.of(this)!.cropPhoto;
  String terms() => AppLocalizations.of(this)!.terms;
  String letsElevator() => AppLocalizations.of(this)!.aboutLetsElevator;
  String officialPage() =>  AppLocalizations.of(this)!.officialPage;
  String officialShop() => AppLocalizations.of(this)!.officialShop;
  String movingElevator() => AppLocalizations.of(this)!.movingElevator;
  String photoAccessRequired() => AppLocalizations.of(this)!.photoAccessRequired;
  String photoAccessPermission() => AppLocalizations.of(this)!.photoAccessPermission;
  String earnMilesAfterAdTitle(String number) => AppLocalizations.of(this)!.earnMilesAfterAdTitle(number);
  String earnMilesAfterAdDesc(String number) => AppLocalizations.of(this)!.earnMilesAfterAdDesc(number);
  String landingPageLink() => (lang() == "ja") ? landingPageJa: landingPageEn;
  String privacyPolicyLink() => (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn;
  String youtubeLink() => (lang() == "ja") ? youtubeJa: youtubeEn;
  String notConnectedInternet() => AppLocalizations.of(this)!.notConnectedInternet;
  String notSignedInGameCenter() => AppLocalizations.of(this)!.notSignedInGameCenter(
    (Platform.isIOS || Platform.isMacOS) ? "Game Center": "Play Games"
  );
  // Menu links and titles
  List<String> linkLogos() => [
    if (Platform.isAndroid) youtubeLogo,
    landingPageLogo,
    privacyPolicyLogo,
    if (lang() == "ja") shopPageLogo,
  ];
  List<String> linkLinks() => [
    if (Platform.isAndroid) youtubeLink(),
    landingPageLink(),
    privacyPolicyLink(),
    if (lang() == "ja") shopLink,
  ];
  List<String> linkTitles() => [
    if (Platform.isAndroid) "Youtube",
    officialPage(),
    terms(),
    if (lang() == "ja") officialShop(),
  ];
  List<String> menuTitles() => [
    settings(),
    eVMileRanking(),
    earnMile(earnMiles),
  ];

  // --- UI Layout & Sizing ---
  // Comprehensive set of responsive UI sizing methods for all app components
  // Progress indicator
  double circleSize() => widthResponsible() * 0.08;
  double circleStrokeWidth() => widthResponsible() * 0.01;
  // App bar
  double homeAppBarHeight() => height() * 0.07;
  double homeAppBarIconSize() => widthResponsible() * 0.09;
  double homeAppBarIconMarginLeft() => widthResponsible() * 0.02;
  double homeAppBarPointFontSize() => widthResponsible() * 0.08;
  double homeAppBarPointMarginLeft() => widthResponsible() * 0.04;
  double homeAppBarPointMarginBottom() => widthResponsible() * 0.01;
  double homeAppBarMenuButtonSize() => widthResponsible() * 0.09;
  double homeAppBarMenuButtonMargin() => widthResponsible() * 0.045;
  // Tooltip
  double tooltipIconSize() => widthResponsible() * 0.04;
  double tooltipHeight() => widthResponsible() * 0.09;
  double tooltipMarginLeft() => widthResponsible() * 0.01;
  double tooltipTitleFontSize() => widthResponsible() * 0.05;
  double tooltipDescFontSize() => widthResponsible() *0.04;
  double tooltipTitleMargin() => widthResponsible() * 0.01;
  double tooltipPaddingSize() => widthResponsible() * 0.04;
  double tooltipMarginSize() => widthResponsible() * 0.02;
  double tooltipBorderRadius() => widthResponsible() * 0.04;
  double tooltipOffsetSize() => widthResponsible() * 0.02;
  // Elevator layout
  double elevatorWidth() => widthResponsible();
  double elevatorHeight() => widthResponsible() * 16/9;
  double doorWidth() => widthResponsible() * 0.355;
  double doorMarginLeft() => widthResponsible() * 0.023;
  double doorMarginTop() => widthResponsible() * 0.193;
  double upDownDoorMarginTop() => widthResponsible() * 0.191;
  double elevatorMarginTop() => widthResponsible() * 0.045;
  double changeMarginTop() => widthResponsible() * 0.145;
  double roomWidth() => widthResponsible() * 0.73;
  double roomHeight() => roomWidth() * 16/9;
  double floorHeight() => widthResponsible() * 1.57;
  double sideFrameWidth() => widthResponsible() * 0.024;
  double sideSpacerWidth() => (width() - elevatorWidth()) / 2;
  double outsideMarginTop(int counter, int max) =>
      elevatorMarginTop() - (max - counter - (counter < 0 ? 1: 0)) * floorHeight();
  double insideMarginTop(int counter, int max) =>
      elevatorMarginTop() + changeMarginTop() - (max - counter - (counter < 0 ? 1: 0)) * floorHeight();
  double imageMarginTop(bool isOutside, int counter, int max) =>
      (isOutside) ? outsideMarginTop(counter, max): insideMarginTop(counter, max);
  // Display
  double displayHeight() => widthResponsible() * 0.24;
  double displayWidth()  => widthResponsible() * 0.18;
  double displayArrowHeight(int buttonStyle) => widthResponsible() * 0.06;
  double displayArrowMarginTop(int buttonStyle) => widthResponsible() * 0.04;
  double displayNumberHeight() => widthResponsible() * 0.10;
  double displayNumberMarginTop(int buttonStyle) => widthResponsible() * 0.035;
  double displayNumberMarginRight(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.012: 0.015);
  double displayNumberFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.06: 0.06);
  double displayMarginFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.03);
  double displayAlphabetFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.065: 0.1);
  double displayAlphabetMargin(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.02);
  // Hall Lamp
  double hallLampHeight() => widthResponsible() * 0.32;
  // Buttons
  double buttonPanelWidth() => widthResponsible() * 0.23;
  double buttonPanelHeight() => widthResponsible() * 1.05;
  double buttonPanelMarginTop() => widthResponsible() * 0.1;
  double buttonPanelMarginLeft() => widthResponsible() * 0.76;
  double buttonSize() => widthResponsible() * 0.08;
  double operationButtonSize() => widthResponsible() * 0.085;
  double operationButtonMargin() => widthResponsible() * 0.05;
  double upDownButtonMargin() => widthResponsible() * 0.05;
  double floorButtonMargin() => widthResponsible() * 0.02;
  double floorButtonNumberFontSize(int i) =>
      widthResponsible() * floorButtonNumberSizeFactor[i] * 0.03;
  double floorButtonNumberBottomMargin(int i) =>
      widthResponsible() * floorButtonNumberMarginFactor[i] * 0.01;
  double floorButtonNumberMarginTop(int i) =>
      floorButtonNumberMarginFactor[i] < 0 ? 0: widthResponsible() * (0.002 + floorButtonNumberMarginFactor[i]);
  double floorButtonNumberMarginBottom(int i) =>
      floorButtonNumberMarginFactor[i] > 0 ? 0: -1 * widthResponsible() * floorButtonNumberMarginFactor[i];
  double changeViewMarginTop() => widthResponsible() * 0.028;
  double changeViewMarginLeft() => widthResponsible() * 0.32;
  // AdMob
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? (height() / 8 - 25): 100;
  double admobWidth() => widthResponsible() - 100;
  // Menu
  double menuButtonSize() => widthResponsible() * 0.28;
  double menuButtonMargin() => widthResponsible() * 0.06;
  double menuMarginTop() => height() * 0.02;
  double menuMarginBottom() => height() * 0.25;
  double menuAlertTitleFontSize()  => (widthResponsible() * 0.06 > 36) ? 36: widthResponsible() * 0.06;
  double menuAlertDescFontSize()   => (widthResponsible() * 0.032 > 14) ? 14: widthResponsible() * 0.032;
  double menuAlertSelectFontSize() => (widthResponsible() * 0.040 > 24) ? 24: widthResponsible() * 0.040;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() * 0.025;
  double menuLinksMargin() => widthResponsible() * 0.01;
  // SnackBar
  double snackBarFontSize() => widthResponsible() * 0.04;
  double snackBarBorderRadius() => widthResponsible()  * 0.05;
  double snackBarPadding() => widthResponsible()  * 0.02;
  double snackBarSideMargin(TextPainter textPainter) => (widthResponsible() * 0.9 - textPainter.size.width) / 2;
  double snackBarBottomMargin() => height() * 0.03;
  // Settings
  // App Bar
  double settingsAppBarHeight() => height() * 0.07;
  double settingsAppBarFontSize() => height() * 0.032;
  double settingsAppBarBackButtonSize() => height() * 0.05;
  double settingsAppBarBackButtonMargin() => height() * 0.01;
  // Select top button
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  double settingsSelectBorderWidth() => height() * 0.002;
  double settingsSelectIconMargin() => height() * 0.004;
  double settingsSelectIconSize() => height() * 0.036;
  // Common
  double settingsLockFontSize() => height() * 0.03;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  // Change floor image
  double settingsFloorImageLockWidth() => height() * 0.18;
  double settingsFloorImageLockHeight() => height() * 0.20;
  double settingsFloorImageHeight() => height() * 0.19;
  double settingsFloorImageWidth() => settingsFloorImageHeight() * 9 / 16;
  double settingsFloorImageMargin() => height() * 0.01;
  double settingsArrowMarginTop() => height() * 0.03;
  // Change button number
  double settingsButtonSize() => height() * 0.07;
  double settingsButtonNumberSize()   => height() * 0.075;
  double settingsButtonNumberHideWidth() => height() * 0.165;
  double settingsButtonNumberHideHeight() => height() * 0.085;
  double settingsButtonNumberHideMargin() => height() * 0.009;
  double settingsButtonNumberFontSize() => height() * 0.03;
  double settingsButtonNumberMargin() => height() * 0.015;
  double settingsButtonNumberLockWidth() => height() * 0.20;
  double settingsButtonNumberLockHeight() => height() * 0.11;
  // Change floor stop
  double settingsFloorStopFontSize() => height() * 0.015;
  double settingsFloorStopMargin() => height() * 0.005;
  double settingsFloorStopToggleScale() => height() * 0.001;
  // Change button style
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.08;
  // Change button shape
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.02;
  double settingsButtonShapeMarginTop() => height() * 0.03;
  double settingsButtonShapeMarginBottom() => height() * 0.025;
  double settingsButtonShapeLockHeight() => height() * 0.19;
  double settingsButtonShapeLockWidth() => width() * 0.9;
  double settingsButtonShapeLockMarginTop() => height() * 0.114;
  // Change background image
  double settingsBackgroundHeight() => height() * 0.27;
  double settingsBackgroundWidth() => settingsBackgroundHeight() * 0.62;
  double settingsBackgroundMargin() => height() * 0.015;
  double settingsBackgroundLockHeight() => settingsBackgroundHeight() + height() * 0.017;
  double settingsBackgroundLockWidth() => width() * 0.9;
  double settingsBackgroundLockMargin() => height() * 0.292;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  double settingsGlassFontSize() => height() * 0.03;
  double settingsGlassShadowShift() => height() * 0.002;
  // Settings Alert Dialog
  double settingsAlertTitleFontSize() => widthResponsible() * 0.05;
  double settingsAlertFontSize() => widthResponsible() * 0.05;
  double settingsAlertDescFontSize() => widthResponsible() * 0.04;
  double settingsAlertCloseIconSize() =>  widthResponsible() * 0.1;
  double settingsAlertCloseIconSpace() =>  widthResponsible() * 0.05;
  double settingsAlertSelectFontSize() => widthResponsible() * 0.05;
  double settingsAlertFloorNumberPickerHeight() => widthResponsible() * 0.4;
  double settingsAlertFloorNumberHeight() => widthResponsible() * 0.16;
  double settingsAlertFloorNumberFontSize() => widthResponsible() * 0.1;
  double settingsAlertImageSelectHeight() => widthResponsible() * 0.4;
  double settingsAlertDropdownMargin() => widthResponsible() * 0.01;
  double settingsAlertIconSize() => widthResponsible() * 0.06;
  double settingsAlertIconMargin() => widthResponsible() * 0.01;
  double settingsAlertLockFontSize() => widthResponsible() * 0.07;
  double settingsAlertLockIconSize() => widthResponsible() * 0.05;
  double settingsAlertLockSpaceSize() => widthResponsible() * 0.02;
  double settingsAlertLockBorderWidth() => widthResponsible() * 0.002;
  double settingsAlertLockBorderRadius() => widthResponsible() * 0.04;
  // Divider
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
}

// =============================
// IntExt: Integer utilities for floor, button, and elevator logic
// =============================
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
      'centésimo ${(this % 100).esRankNumberOver20()} ';
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
    'centième ${(this % 100).frRankNumberOver20()} ';

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
      [for (int i = -6; i <= 163; i++) if (i != 0) ((this == i) ? elevatorStyle.insideElevator(): imageDark).fittedAssetImage()];

  // --- Display Helpers ---
  // Methods for formatting display text and symbols for elevator status
  String displayNumber() =>
      (this == max || this == 0) ? "":
      (this < 0) ? "${abs()}":
      "$this";
  String displayAlphabet() =>
      (this == max) ? "R":
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
  // Comprehensive set of methods for managing floor button states and elevator navigation logic
  /// Generate button display text (R for roof, G for ground, B+number for basement, number for floors)
  String buttonNumber() =>
      (this == max) ? "R":
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

// =============================
// ListIntExt: List<int> helpers for floor and button matrix
// =============================
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

  // --- Floor Selection Helpers ---
  // Methods for calculating floor ranges and selections based on button matrix positions
  int selectFirstFloor(int row, int col) =>
      (row == 3 && col == 3) ? min: this[reversedButtonIndex[row][col] - 1] + 1;
  int selectLastFloor(int row, int col) =>
      (row == 0 && col == 3) ? max: this[reversedButtonIndex[row][col] + 1] - 1;
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}

// =============================
// ListStringExt: List<String> helpers for room images and names
// =============================
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
      [for (int i = -6; i <= 163; i++) if (i != 0) i.roomImage(floorNumbers, this)];

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

// =============================
// BoolExt: Boolean helpers for UI and logic
// =============================
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

  // --- Basement Floor Helpers ---
  // Methods for handling basement floor logic and floor number calculations
  int floorSymbol() => this ? -1: 1;
  int selectedFloorNumber(int index) => floorSymbol() * (index + 1);
  int selectFirstFloor(List<int> floorNumbers, int buttonIndex) =>
      this ? 1: floorNumbers[buttonIndex - 1] + 1;
  int selectLastFloor(List<int> floorNumbers, int buttonIndex)  =>
      this ? 5: floorNumbers[buttonIndex + 1];
  int selectDiffFloor(List<int> floorNumbers, int buttonIndex) =>
      selectLastFloor(floorNumbers, buttonIndex) - selectFirstFloor(floorNumbers, buttonIndex);
  int selectInitialIndex(List<int> floorNumbers, int buttonIndex) =>
      this ? -1 * (floorNumbers[buttonIndex] + 1): (floorNumbers[buttonIndex] - selectFirstFloor(floorNumbers, buttonIndex));

  // --- Button Shape Factors ---
  // Methods for calculating UI scaling factors based on button shape configurations
  double floorButtonShapeFactor() => this ? 1.2: 1;
  double buttonMarginShapeFactor() => this ? 0.5: 1;
  double operationTopMarginShapeFactor() => this ? 3: 1.6;
  double operationSideMarginShapeFactor() => this ? 1.8: 0.8;
  double emergencyBottomMarginShapeFactor() => this ? 1.8: 0.8;

  // --- Menu Interaction ---
  // Methods for handling menu interactions with sound and vibration feedback
  Future<bool> pressedMenu() async {
    await AudioManager().playEffectSound(asset: selectSound, volume: 1.0);
    await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    return !this;
  }
}

// =============================
// ListBoolExt: List<bool> helpers for button images
// =============================
extension ListBoolExt on List<bool> {

  // --- Operation Button Images ---
  // Methods for generating operation button image lists based on button states and styles
  List<String> operationButtonImage(int buttonStyle) => [
    this[0].openBackGround(buttonStyle),
    this[1].closeBackGround(buttonStyle),
    this[2].phoneBackGround(buttonStyle),
  ];
}

// =============================
// ListDynamicExt: Generic List<T> matrix helpers
// =============================
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
