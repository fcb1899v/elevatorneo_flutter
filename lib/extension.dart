import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'constant.dart';
import 'sound_manager.dart';

extension StringExt on String {

  ///Common
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  //SharedPreferences this is key
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

  //this is imagePath
  Image cropperImage() => Image.file(File(this), fit: BoxFit.cover);
  Image fittedAssetImage() => Image.asset(this, fit: BoxFit.cover);
  Image roomImage() => contains("image_cropper") ? cropperImage(): fittedAssetImage();

  //this is style
  String elevatorFrame(bool isOutside) => "${assetsElevator}elevatorFrame_$this${isOutside ? "Outside": ""}.png";
  String doorFrame() => "${assetsElevator}doorFrame_$this.png";
  String leftDoor(String glassStyle) => "${assetsElevator}doorLeft_$this${glassStyle == "use" ? "WithGlass": ""}.png";
  String rightDoor(String glassStyle) => "${assetsElevator}doorRight_$this${glassStyle == "use" ? "WithGlass": ""}.png";
  String backGroundImage(String glassStyle) => "$assetsSettings${this}Background${glassStyle == "use" ? "WithGlass": ""}.png";
  String insideElevator() => "${assetsElevator}inside_$this.png";
  List<String> insideElevatorImages(List<int> floorNumbers, int counter) =>
      List.generate(initialFloorImages.length, (i) => (counter == floorNumbers[i]) ? insideElevator(): imageDark);

  //this is buttonShape
  int buttonShapeIndex() => buttonShapeList.contains(this) ? buttonShapeList.indexOf(this): 0;
}

extension ContextExt on BuildContext {

  void pushFadeReplacement(Widget page) {
    AudioManager().playEffectSound(index: 0, asset: changeModeSound, volume: 1.0);
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

  ///Common
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double widthResponsible() => (width() < height() / 2) ? width(): height() / 2;
  void popPage() => Navigator.pop(this);

  ///Language String
  String lang() => Localizations.localeOf(this).languageCode;
  String ttsLang() =>
      (lang() != "en") ? lang(): "en";
  String ttsVoice() =>
      (lang() == "ja") ? "ja-JP":
      (lang() == "ko") ? "ko-KR":
      (lang() == "zh") ? "zh-CN":
      "en-US";
  String voiceName(bool isAndroid) =>
      isAndroid ? (
          lang() == "ja" ? "ja-JP-language":
          lang() == "ko" ? "ko-KR-language":
          lang() == "zh" ? "ko-CN-language":
          "en-US-language"
      ): (
          lang() == "ja" ? "Kyoko":
          lang() == "ko" ? "Yuna":
          lang() == "zh" ? "Lili":
          "Samantha"
      );

  ///Localized String
  //Common
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

  ///Room
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

  ///Room Image Name
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
      floor("${basement(counter)}${counter.abs()}");
  String openingSound(int counter, String room) =>
      "${soundFloor(counter)}${soundPlace(room)}${openDoor()}";

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

  ///Menu
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

  List<String> linkLogos() => [
    // if (lang() == "ja") twitterLogo,
    // if (lang() == "ja") instagramLogo,
    if (Platform.isAndroid) youtubeLogo,
    landingPageLogo,
    privacyPolicyLogo,
    if (lang() == "ja") shopPageLogo,
  ];
  List<String> linkLinks() => [
    // if (lang() == "ja") elevatorTwitter,
    // if (lang() == "ja") elevatorInstagram,
    if (Platform.isAndroid) youtubeLink(),
    landingPageLink(),
    privacyPolicyLink(),
    if (lang() == "ja") shopLink,
  ];
  List<String> linkTitles() => [
    // if (lang() == "ja") "X",
    // if (lang() == "ja") "Instagram",
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

  ///Progress Indicator
  double circleSize() => ((height() > width()) ? width(): height()) * 0.1;
  double circleStrokeWidth() => ((height() > width()) ? width(): height()) * 0.012;

  ///AppBar
  double homeAppBarHeight() => height() * 0.07;
  double homeAppBarIconSize() => widthResponsible() * 0.09;
  double homeAppBarIconMarginLeft() => widthResponsible() * 0.02;
  double homeAppBarPointFontSize() => widthResponsible() * 0.08;
  double homeAppBarPointMarginLeft() => widthResponsible() * 0.04;
  double homeAppBarPointMarginBottom() => widthResponsible() * 0.01;
  double homeAppBarMenuButtonSize() => widthResponsible() * 0.09;
  double homeAppBarMenuButtonMargin() => widthResponsible() * 0.045;

  ///Tooltip
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

  ///Elevator
  double elevatorWidth() => widthResponsible();
  double elevatorHeight() => widthResponsible() * 16/9;
  double doorWidth() => widthResponsible() * 0.355;
  double doorMarginLeft() => widthResponsible() * 0.023;
  double doorMarginTop() => widthResponsible() * 0.193;
  double upDownDoorMarginTop() => widthResponsible() * 0.191;
  double imageMarginTop() => widthResponsible() * 0.045;
  double changeMarginTop() => widthResponsible() * 0.145;
  double roomWidth() => widthResponsible() * 0.73;
  double roomHeight() => roomWidth() * 16/9;
  double floorHeight() => widthResponsible() * 1.57;
  double sideFrameWidth() => widthResponsible() * 0.024;
  double sideSpacerWidth() => (width() - elevatorWidth()) / 2;

  ///Display
  double displayHeight() => widthResponsible() * 0.24;
  double displayWidth()  => widthResponsible() * 0.18;
  double displayArrowHeight(int buttonStyle) => widthResponsible() * 0.06;
  double displayArrowMarginTop(int buttonStyle) => widthResponsible() * 0.04;
  double displayNumberHeight() => widthResponsible() * 0.10;
  double displayNumberMarginTop(int buttonStyle) => widthResponsible() * 0.035;
  double displayNumberMarginRight(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.012: 0.015);
  double displayNumberFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.063: 0.063);
  double displayMarginFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.03);
  double displayAlphabetFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.065: 0.1);
  double displayAlphabetMargin(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.02);

  ///Buttons
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
      floorButtonNumberMarginFactor[i] < 0 ? 0: widthResponsible() * floorButtonNumberMarginFactor[i];
  double floorButtonNumberMarginBottom(int i) =>
      floorButtonNumberMarginFactor[i] > 0 ? 0: -1 * widthResponsible() * floorButtonNumberMarginFactor[i];
  double changeViewMarginTop() => widthResponsible() * 0.032;
  double changeViewMarginLeft() => widthResponsible() * 0.32;

  ///Admob
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? (height() / 8 - 25): 100;
  double admobWidth() => widthResponsible() - 100;

  ///Menu
  double menuButtonSize() => widthResponsible() * 0.28;
  double menuButtonMargin() => widthResponsible() * 0.06;
  double menuMarginTop() => height() * 0.02;
  double menuMarginBottom() => height() * 0.25;
  double menuAlertTitleFontSize()  => (widthResponsible() * 0.06 > 36) ? 36: widthResponsible() * 0.06;
  double menuAlertDescFontSize()   => (widthResponsible() * 0.032 > 14) ? 14: widthResponsible() * 0.032;
  double menuAlertSelectFontSize() => (widthResponsible() * 0.040 > 24) ? 24: widthResponsible() * 0.040;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() * (lang() == "en" ? 0.030: 0.025);
  double menuLinksMargin() => widthResponsible() * 0.01;

  ///Settings
  //App Bar
  double settingsAppBarHeight() => height() * 0.07;
  double settingsAppBarFontSize() => height() * (lang() == "en" ? 0.045: 0.032);
  double settingsAppBarBackButtonSize() => height() * 0.05;
  double settingsAppBarBackButtonMargin() => height() * 0.01;
  //Select top button
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonIconSize() => height() * 0.03;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  //Common
  double settingsLockFontSize() => height() * 0.03;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  //Change floor image
  double settingsFloorImageLockWidth() => height() * 0.18;
  double settingsFloorImageLockHeight() => height() * 0.20;
  double settingsFloorImageHeight() => height() * 0.19;
  double settingsFloorImageWidth() => settingsFloorImageHeight() * 9 / 16;
  double settingsFloorImageMargin() => height() * 0.01;
  double settingsArrowMarginTop() => height() * 0.03;
  //Change button number
  double settingsButtonSize() => height() * 0.07;
  double settingsButtonNumberSize()   => height() * 0.075;
  double settingsButtonNumberHideWidth() => height() * 0.165;
  double settingsButtonNumberHideHeight() => height() * 0.085;
  double settingsButtonNumberHideMargin() => height() * 0.009;
  double settingsButtonNumberFontSize() => height() * 0.03;
  double settingsButtonNumberMargin() => height() * 0.015;
  double settingsButtonNumberLockWidth() => height() * 0.20;
  double settingsButtonNumberLockHeight() => height() * 0.11;
  //Change floor stop
  double settingsFloorStopFontSize() => height() * 0.015;
  double settingsFloorStopMargin() => height() * 0.005;
  double settingsFloorStopToggleScale() => height() * 0.001;
  //Change button style
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.08;
  //Change button shape
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.02;
  double settingsButtonShapeMarginTop() => height() * 0.03;
  double settingsButtonShapeMarginBottom() => height() * 0.025;
  double settingsButtonShapeLockHeight() => height() * 0.19;
  double settingsButtonShapeLockWidth() => width() * 0.9;
  double settingsButtonShapeLockMarginTop() => height() * 0.114;
  //Change background image
  double settingsBackgroundHeight() => height() * 0.27;
  double settingsBackgroundWidth() => settingsBackgroundHeight() * 0.62;
  double settingsBackgroundMargin() => height() * 0.015;
  double settingsBackgroundLockHeight() => settingsBackgroundHeight() + height() * 0.017;
  double settingsBackgroundLockWidth() => width() * 0.9;
  double settingsBackgroundLockMargin() => height() * 0.292;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  double settingsGlassFontSize() => height() * (lang() == "en" ? 0.032: 0.024);
  double settingsGlassToggleMargin() => height() * 0.005;
  //Settings Alert Dialog
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
  //Divider
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
}



extension IntExt on int {

  ///Floor Sound
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";

  ///Settings
  //this is selected number
  String selected(int i) => (this == i) ? "Pressed": "";
  String settingsButton(int i) => "$assetsSettings${settingsItemList[i]}Settings${selected(i)}.png";
  //this is operationButtonStyleNumber
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

  ///Elevator inside image
  //This is currentFloor
  List<Image> insideImages(String elevatorStyle) =>
      [for (int i = -6; i <= 163; i++) if (i != 0) ((this == i) ? elevatorStyle.insideElevator(): imageDark).fittedAssetImage()];

  ///Display
  // this is counter
  String displayNumber() =>
      (this == max || this == 0) ? "":
      (this < 0) ? "${abs()}":
      "$this";
  String displayAlphabet() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B":
      "";

  ///Image Display
  String upArrow() => "${assetsElevator}up${this + 1}.png";
  String downArrow() => "${assetsElevator}down${this + 1}.png";
  String arrowImage(bool isMoving, int nextFloor, int buttonStyle) =>
      (isMoving && this < nextFloor) ? buttonStyle.upArrow():
      (isMoving && this > nextFloor) ? buttonStyle.downArrow():
      transpImage;

  ///Speed
  //this is i
  int elevatorSpeed(int count, int nextFloor) {
    int l = (this - nextFloor).abs();
    return (count < 2 || l < 2) ? 2000:
    (count < 5 || l < 5) ? 1000:
    (count < 10 || l < 10) ? 500:
    (count < 20 || l < 20) ? 250: 100;
  }

  ///Button
  //this is i
  String buttonNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  //this is i and counter.
  bool isSelected(List<bool> isAboveSelectedList, isUnderSelectedList) =>
      (this > 0) ? isAboveSelectedList[this]: isUnderSelectedList[this * (-1)];

  //this is counter.
  void clearUpperFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = max; j > this - 1; j--) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  //this is counter.
  void clearLowerFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = min; j < this + 1; j++) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  //this is counter.
  List<int> upFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this + 1; i < nextFloor + 1; i++) {
      floorList.add(i);
    }
    return floorList;
  }

  //this is counter
  List<int> downFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this - 1; i > nextFloor - 1; i--) {
      floorList.add(i);
    }
    return floorList;
  }

  // this is counter
  int upNextFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    int nextFloor = max;
    for (int k = this + 1; k < max + 1; k++) {
      bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (k < nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == max) {
      bool isMaxSelected = max.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (isMaxSelected) {
        nextFloor = max;
      } else {
        nextFloor = min;
        bool isMinSelected = min.isSelected(isAboveSelectedList, isUnderSelectedList);
        for (int k = min; k < this; k++) {
          bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
          if (k > nextFloor && isSelected) nextFloor = k;
        }
        if (isMinSelected) nextFloor = min;
      }
    }
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

  // this is counter
  int downNextFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    int nextFloor = min;
    for (int k = min; k < this; k++) {
      bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (k > nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == min) {
      bool isMinSelected = min.isSelected(isAboveSelectedList, isUnderSelectedList);
      if (isMinSelected) {
        nextFloor = min;
      } else {
        nextFloor = max;
        bool isMaxSelected = max.isSelected(isAboveSelectedList, isUnderSelectedList);
        for (int k = max; k > this; k--) {
          bool isSelected = k.isSelected(isAboveSelectedList, isUnderSelectedList);
          if (k < nextFloor && isSelected) nextFloor = k;
        }
        if (isMaxSelected) nextFloor = max;
      }
    }
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

  //this is i.
  void trueSelected(List<bool> isAboveSelectedList, isUnderSelectedList) {
    if (this > 0) isAboveSelectedList[this] = true;
    if (this < 0) isUnderSelectedList[this * (-1)] = true;
  }

  //this is i.
  void falseSelected(List<bool> isAboveSelectedList, isUnderSelectedList) {
    if (this > 0) isAboveSelectedList[this] = false;
    if (this < 0) isUnderSelectedList[this * (-1)] = false;
  }

  //this is i
  bool onlyTrue(List<bool> isAboveSelectedList, isUnderSelectedList) {
    bool listFlag = false;
    if (isSelected(isAboveSelectedList, isUnderSelectedList)) listFlag = true;
    if (this > 0) {
      for (int k = 0; k < isAboveSelectedList.length; k++) {
        if (k != this && isAboveSelectedList[k]) listFlag = false;
      }
      for (int k = 0; k < isUnderSelectedList.length; k++) {
        if (isUnderSelectedList[k]) listFlag = false;
      }
    }
    if (this < 0) {
      for (int k = 0; k < isUnderSelectedList.length; k++) {
        if (k != this * (-1) && isUnderSelectedList[k]) listFlag = false;
      }
      for (int k = 0; k < isAboveSelectedList.length; k++) {
        if (isAboveSelectedList[k]) listFlag = false;
      }
    }
    return listFlag;
  }

  //this is i
  bool isButtonContain(List<int> floorNumbers) => floorNumbers.contains(this);
  String roomImageFile(List<int> floorNumbers, List<String> rooms) => rooms[floorNumbers.indexOf(this)];
  Image roomImage(List<int> floorNumbers, List<String> rooms) =>
    (!isButtonContain(floorNumbers)) ? imageFloor.fittedAssetImage():
      roomImageFile(floorNumbers, rooms).roomImage();
}
extension ListIntExt on List<int> {

  List<List<int>> floorNumbersList() => [
    [this[8], this[9]],
    [this[6], this[7]],
    [this[4], this[5]],
    [this[2], this[3]],
    [this[1], this[0]],
  ];

  int selectFirstFloor(int row, int col) =>
      (row == 3 && col == 3) ? min: this[reversedButtonIndex[row][col] - 1] + 1;
  int selectLastFloor(int row, int col) =>
      (row == 0 && col == 3) ? max: this[reversedButtonIndex[row][col] + 1] - 1;
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}

extension ListStringExt on List<String> {

  List<List<String>> roomsList() => [
    [this[8], this[9]],
    [this[6], this[7]],
    [this[4], this[5]],
    [this[2], this[3]],
    [this[1], this[0]],
  ];

  List<Image> floorImages(List<int> floorNumbers) =>
      [for (int i = -6; i <= 163; i++) if (i != 0) i.roomImage(floorNumbers, this)];

  //this is roomImageList
  Iterable<String> remainIterable(List<String> roomImages, int buttonIndex) =>
      where((image) => !roomImages.contains(image) || roomImages[buttonIndex] == image);
  //calc index
  int roomIndex(List<String> roomImages, int buttonIndex) =>
      indexOf(roomImages[buttonIndex]);
  int remainIndex(List<String> roomImages, int buttonIndex) =>
      indexOf(remainImage(roomImages, buttonIndex));
  //room image
  String remainImage(List<String> roomImages, int buttonIndex) =>
      remainIterable(roomImages, buttonIndex).toList()[0];
  String selectedRoomImage(List<String> roomImages, int buttonIndex) =>
      (roomIndex(roomImages, buttonIndex) == -1) ?
      remainImage(roomImages, buttonIndex):
      roomImages[buttonIndex];
  //room name
  String roomName(BuildContext context, String image) =>
      context.roomNameList()[floorImageList.indexOf(image)];
  String remainName(BuildContext context, List<String> roomImages, int buttonIndex) =>
      context.roomNameList()[remainIndex(roomImages, buttonIndex)];
  String selectedRoomName(BuildContext context, List<String> roomImages, int buttonIndex) =>
      (roomIndex(roomImages, buttonIndex) == -1) ?
        remainName(context, roomImages, buttonIndex) :
        context.roomNameList()[roomIndex(roomImages, buttonIndex)];
}

extension BoolExt on bool {

  ///This is isPressed
  String pressed() => this ? 'Pressed': '';
  String numberBackground(int buttonStyle, String buttonShape) => "$assetsButton$buttonShape${buttonStyle + 1}${pressed()}.png";
  String openBackGround(int buttonStyle) => this ? buttonStyle.pressedOpenButton(): buttonStyle.openButton();
  String closeBackGround(int buttonStyle) => this ? buttonStyle.pressedCloseButton(): buttonStyle.closeButton();
  String phoneBackGround(int buttonStyle) => this ? buttonStyle.pressedAlertButton(): buttonStyle.alertButton();
  String upBackGround(int buttonStyle) => this ? buttonStyle.pressedUpButton(): buttonStyle.upButton();
  String downBackGround(int buttonStyle) => this ? buttonStyle.pressedDownButton(): buttonStyle.downButton();
  Color numberColor(int i) => this ? numberColorList[i]: whiteColor;
  Color floorButtonNumberColor(String buttonShape) => numberColor(buttonShape.buttonShapeIndex());

  ///This is isBasement
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

  ///This is buttonShape
  double floorButtonShapeFactor() => this ? 1.2: 1;
  double buttonMarginShapeFactor() => this ? 0.5: 1;
  double operationTopMarginShapeFactor() => this ? 3: 1.6;
  double operationSideMarginShapeFactor() => this ? 1.8: 0.8;
  double emergencyBottomMarginShapeFactor() => this ? 1.8: 0.8;

  //This is isMenu
  Future<bool> pressedMenu() async {
    await AudioManager().playEffectSound(index: 0, asset: selectButton, volume: 1.0);
    await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    return !this;
  }
}

extension ListBoolExt on List<bool> {

  List<String> operationButtonImage(int buttonStyle) => [
    this[0].openBackGround(buttonStyle),
    this[1].closeBackGround(buttonStyle),
    this[2].phoneBackGround(buttonStyle),
  ];
}

extension ListDynamicExt<T> on List<T> {
  List<List<T>> toMatrix(int n) =>
      [for (var i = 0; i < length; i += n) sublist(i, (i + n <= length) ? i + n : length)];

  List<List<T>> toReversedMatrix(int n) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += n) {
      final end = (i + n).clamp(0, length);
      final chunk = (i == 0) ? sublist(i, end).reversed.toList(): sublist(i, end);
      chunks.add(chunk);
    }
    // "chunks: ${chunks.reversed.toList()}".debugPrint();
    return chunks.reversed.toList();
  }

}
