import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;
import 'constant.dart';
import 'my_home_body.dart';

extension StringExt on String {

  ///Common
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  void pushPage(BuildContext context) =>
      Navigator.of(context).pushNamedAndRemoveUntil(this, (_) => false);

  Future<void> speakText(FlutterTts flutterTts, bool isSoundOn) async {
    if (isSoundOn) {
      debugPrint();
      await flutterTts.stop();
      await flutterTts.speak(this);
    }
  }

  //SharedPreferences this is key
  setSharedPrefString(SharedPreferences prefs, String value) {
    "$this: $value".debugPrint();
    prefs.setString(this, value);
  }
  setSharedPrefInt(SharedPreferences prefs, int value) {
    "$this: $value".debugPrint();
    prefs.setInt(this, value);
  }
  setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "$this: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("this$i", value[i]);
    }
    "$this: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "$this: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "$this: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "$this: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("this$i") ?? defaultList[i];
      values.add(v);
    }
    "$this: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }

  //this is imagePath
  Image cropperImage() => Image.file(File(this), fit: BoxFit.cover);
  Image fittedAssetImage() => Image.asset(this, fit: BoxFit.cover);
  Image roomImage() => contains("image_cropper") ? cropperImage(): fittedAssetImage();
}

extension ContextExt on BuildContext {

  void pushHomePage() => Navigator.pushReplacement(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => MyHomePage(),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ));

  ///Common
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
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
  String menu() => AppLocalizations.of(this)!.menu;
  String settings() => AppLocalizations.of(this)!.settings;
  String back() => AppLocalizations.of(this)!.back;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
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
    if (Platform.isAndroid) elevatorYoutube,
    (lang() == "ja") ? landingPageJa: landingPageEn,
    (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn,
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
  double circleStrokeWidth() => ((height() > width()) ? width(): height()) * 0.01;

  ///Responsible
  double responsible() => (height() < responsibleHeight) ? height(): responsibleHeight;
  double widthResponsible() => (width() < height() / 2) ? width(): height() / 2;

  ///Elevator
  double elevatorWidth() => widthResponsible();
  double elevatorHeight() => widthResponsible() * elevatorHeightRate;
  double doorWidth() => widthResponsible() * doorWidthRate;
  double doorMarginLeft() => widthResponsible() * doorMarginLeftRate;
  double doorMarginTop() => widthResponsible() * doorMarginTopRate;
  double roomHeight() => widthResponsible() * roomHeightRate;
  double roomWidth() => roomHeight() * 9 / 16;
  double floorHeight() => widthResponsible() * floorHeightRate;
  double sideFrameWidth() => widthResponsible() * sideFrameWidthRate;
  double sideSpacerWidth() => (width() - elevatorWidth()) / 2;
  double menuIconSize() => widthResponsible() * menuIconSizeRate;

  ///Display
  double displayHeight() => widthResponsible() * displayHeightRate;
  double displayWidth()  => widthResponsible() * displayWidthRate;
  double displayMarginTop() => widthResponsible() * displayMarginTopRate;
  double displayMarginLeft()  => widthResponsible() * displayMarginLeftRate;
  double displayNumberHeight() => widthResponsible() * displayNumberHeightRate;
  double displayNumberWidth() => widthResponsible() * displayNumberWidthRate;
  double displayArrowHeight() => widthResponsible() * displayArrowHeightRate;
  double displayArrowWidth() => widthResponsible() * displayArrowWidthRate;
  double displayArrowMargin() => widthResponsible() * displayArrowMarginRate;
  double displayNumberFontSize() => widthResponsible() * displayFontSizeRate;

  ///Buttons
  double buttonPanelWidth() =>      widthResponsible() * buttonPanelWidthRate;
  double buttonPanelHeight() =>     widthResponsible() * buttonPanelHeightRate;
  double buttonPanelMarginTop() =>  widthResponsible() * buttonPanelMarginTopRate;
  double buttonPanelMarginLeft() => widthResponsible() * buttonPanelMarginLeftRate;
  double floorButtonSize() =>       widthResponsible() * floorButtonSizeRate;
  double operationButtonSize() =>   widthResponsible() * operationButtonSizeRate;
  double buttonNumberFontSize() =>  widthResponsible() * buttonNumberFontSizeRate;
  double buttonMargin() =>          widthResponsible() * buttonMarginRate;
  double buttonBorderWidth() =>     widthResponsible() * buttonBorderWidthRate;
  double buttonBorderRadius() =>    widthResponsible() * buttonBorderRadiusRate;

  ///Tooltip
  double tooltipTitleFontSize() => widthResponsible() * tooltipTitleFontRate;
  double tooltipDescFontSize() => widthResponsible() * tooltipDescFontRate;
  double tooltipTitleMargin() => widthResponsible() * tooltipTitleMarginRate;
  double tooltipPaddingSize() => widthResponsible() * tooltipPaddingSizeRate;
  double tooltipMarginSize() => widthResponsible() * tooltipMarginSizeRate;
  double tooltipBorderRadius() => widthResponsible() * tooltipBorderRadiusRate;
  double tooltipOffsetSize() => widthResponsible() * tooltipOffsetSizeRate;

  ///Admob
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? (height() / 8 - 25): 100;
  double admobWidth() => widthResponsible() - 100;

  ///Menu
  double menuTitleWidth() => widthResponsible() * menuTitleWidthRate;
  double menuTitleFontSize() => height() * menuTitleFontSizeRate;
  double menuButtonSize() => widthResponsible() * menuButtonSizeRate;
  double menuButtonFontSize() => widthResponsible() * menuButtonFontSizeRate;
  double menuAlertTitleFontSize() => (widthResponsible() * menuAlertTitleFontSizeRate > 24) ? 24: widthResponsible() * menuAlertTitleFontSizeRate;
  double menuAlertDescFontSize() => (widthResponsible() * menuAlertDescFontSizeRate > 14) ? 14: widthResponsible() * menuAlertDescFontSizeRate;
  double menuAlertSelectFontSize() => (widthResponsible() * menuAlertSelectFontSizeRate > 24) ? 24: widthResponsible() * menuAlertSelectFontSizeRate;

  ///Menu Bottom Navigation Links
  double linksLogoWidth() => widthResponsible() * linksLogoWidthRate;
  double linksLogoHeight() => widthResponsible() * linksLogoHeightRate;
  double linksTitleSize() => widthResponsible() * ((lang() == "ja" && Platform.isAndroid) ? linksTitleJaFontSizeRate: linksTitleEnFontSizeRate);
  double linksTitleMargin() => widthResponsible() * linksTitleMarginRate;
  double linksMargin() => widthResponsible() * linksMarginRate;

  ///Settings
  double settingsTitleFontSize() => height() * settingsTitleFontSizeRate;
  double settingsTitleMargin() => height() * settingsTitleMarginRate;
  double settingsButtonWidth() => height() * settingsButtonWidthRate;
  double settingsButtonHeight() => height() * settingsButtonHeightRate;
  double settingsButtonMargin() => height() * settingsButtonMarginRate;
  double settingsButtonSpace() => height() * settingsButtonSpaceRate;
  double settingsButtonSize() => height() * settingsButtonSizeRate;
  double settingsButtonFontSize() => height() * settingsButtonFontSizeRate;
  double settingsButtonNumberFontSize() => height() * settingsButtonNumberFontSizeRate;
  double settingsButtonBorderRadius() => height() * settingsButtonBorderRadiusRate;
  double settingsButtonShadowSize() => height() * settingsButtonShadowSizeRate;
  double settingsLockFontSize() => height() * settingsLockFontSizeRate;
  double settingsLockIconSize() => height() * settingsLockIconSizeRate;
  double settingsLockSpaceSize() => height() * settingsLockSpaceSizeRate;
  double settingsLockWidth() => settingsImageSelectWidth() + settingsButtonWidth() + settingsButtonMargin();
  double settingsImageSelectHeight() => height() * settingsImageSelectHeightRate;
  double settingsImageSelectWidth() => settingsImageSelectHeight() * 9 / 16;

  ///Settings Alert Dialog
  double settingsAlertTitleFontSize() => widthResponsible() * settingsAlertTitleFontSizeRate;
  double settingsAlertFontSize() => widthResponsible() * settingsAlertFontSizeRate;
  double settingsAlertSelectFontSize() => widthResponsible() * settingsAlertSelectFontSizeRate;
  double settingsAlertFloorNumberSize() => widthResponsible() * settingsAlertFloorNumberSizeRate;
  double settingsAlertFloorNumberHeight() => widthResponsible() * settingsAlertFloorNumberHeightRate;
  double settingsAlertDropdownMargin() => widthResponsible() * settingsAlertDropdownMarginRate;
  double settingsAlertImageSelectHeight() => widthResponsible() * settingsAlertImageSelectHeightRate;
  double settingsAlertIconSize() => widthResponsible() * settingsAlertIconSizeRate;
  double settingsAlertIconMargin() => width() * settingsAlertIconMarginRate;
  double settingsAlertLockFontSize() => widthResponsible() * settingsAlertLockFontSizeRate;
  double settingsAlertLockIconSize() => widthResponsible() * settingsAlertLockIconSizeRate;
  double settingsAlertLockBorderWidth() => widthResponsible() * settingsAlertLockBorderWidthRate;
  double settingsAlertLockBorderRadius() => widthResponsible() * settingsAlertLockBorderRadiusRate;
  double settingsAlertLockSpaceSize() => widthResponsible() * settingsAlertLockSpaceSizeRate;
}

extension IntExt on int {

  ///Floor Sound
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";

  ///Display
  // this is counter
  String displayNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  String arrowImage(bool isMoving, int nextFloor) =>
      (isMoving && this < nextFloor) ? upArrow:
      (isMoving && this > nextFloor) ? downArrow:
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
      context.roomNameList()[roomImageList.indexOf(image)];
  String remainName(BuildContext context, List<String> roomImages, int buttonIndex) =>
      context.roomNameList()[remainIndex(roomImages, buttonIndex)];
  String selectedRoomName(BuildContext context, List<String> roomImages, int buttonIndex) =>
      (roomIndex(roomImages, buttonIndex) == -1) ?
        remainName(context, roomImages, buttonIndex) :
        context.roomNameList()[roomIndex(roomImages, buttonIndex)];
}

extension BoolExt on bool {

  ///This is isPressed
  String numberBackground() => this ? pressedSquare: squareButton;
  String openBackGround() => (this) ? pressedOpenButton: openButton;
  String closeBackGround() => (this) ? pressedCloseButton: closeButton;
  String phoneBackGround() => (this) ? pressedAlertButton: alertButton;
  Color numberColor() => this ? lampColor: whiteColor;

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
}

extension ListBoolExt on List<bool> {

  List<String> operateBackGround() => [
    this[0].openBackGround(),
    this[1].closeBackGround(),
    this[2].phoneBackGround()
  ];
}

