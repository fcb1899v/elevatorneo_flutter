import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

///アプリ名
const String appTitle = "LETS ELEVATOR NEO";

///App Check
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.deviceCheck;

///最高階と最低階
const int min = -6;
const int max = 163;

/// ボタンの階数
const List<int> initialFloorNumbers = [
  min, -1, 1, 2, 4, 6, 14, 100, 154, max,
];

/// Button Index
bool isBasement(int row, int col) => (row == 4);
int buttonCol(int row, int col) => isBasement(row, col) ? (1 - col) : col;
int buttonIndex(int row, int col) => 2 * (4 - row) + buttonCol(row, col);
bool isNotSelectFloor(int row, int col) =>
    (col == 0 && row == 3) || (col == 1 && (row == 0 || row == 4));

/// 解放ポイントリスト
List<List<int>> changePointList = isTest ? List.generate(5, (_) => [0, 0]): [
  [50000, 99999],
  [10000, 20000],
  [ 1000,  2000],
  [    0,   200],
  [ 3000, 50000],
];
const int albumImagePoint = isTest ? 0: 3000;
const initialPoint = 0;

/// 停止する：true・しない：false
const List<List<bool>> isFloors = [
  [true, true],
  [true, true],
  [true, true],
  [true, true],
  [true, true],
];

const String numberValidation = r'-?\d*';
List<FilteringTextInputFormatter> numberFormat = [
  FilteringTextInputFormatter.allow(RegExp(numberValidation)),
];

/// バイブレーション
const int vibTime = 200;
const int vibAmp = 128;

/// Tooltip
const int toolTipTime = 10000; //[msec]

/// エレベータードアの開閉時間
const int openTime = 10;      //[sec]
const int waitTime = 3;       //[sec]
const int flashTime = 500;    //[msec]
const int snackBarTime = 3;   //[sec]

/// エレベータードアの状態
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

/// エレベーターボタンの状態
final List<bool> noPressed = [false, false, false];
final List<bool> pressedOpen = [true, false, false];
final List<bool> pressedClose = [false, true, false];
final List<bool> pressedCall = [false, false, true];
final List<bool> allPressed = [true, true, true];

///Audio
const int audioPlayerNumber = 1;
const String countdown = "audios/pon.mp3";
const String countdownFinish = "audios/chan.mp3";
const String bestScoreSound = "audios/jajan.mp3";
const String selectButton = "audios/kako.mp3";
const String cancelButton = "audios/hi.mp3";
const String changeModeSound = "audios/popi.mp3";
const String changePageSound = "audios/tetete.mp3";
const String callSound = "audios/call.mp3";

///Font
const String elevatorFont = "cornerstone";
const String menuFont = "noto";
const String settingsFont = "noto";
const String numberFont = "teleIndicators";

///Image Folder
const String assetsMenu = "assets/images/menu/";
const String assetsElevator = "assets/images/elevator/";
const String assetsRoom = "assets/images/room/";

///Image Elevator
const String elevatorFrame = "${assetsElevator}elevatorFrame.png";
const String doorFrame = "${assetsElevator}doorFrame.png";
const String leftDoor = "${assetsElevator}doorLeft.png";
const String rightDoor = "${assetsElevator}doorRight.png";
const String leftSideFrame = "${assetsElevator}sideFrameLeft.png";
const String rightSideFrame = "${assetsElevator}sideFrameRight.png";
const String pointImage = "${assetsElevator}point.png";

///Image Room
const String imageParking = "${assetsRoom}01parking.jpg";
const String imageStation = "${assetsRoom}02station.jpg";
const String imageSuper   = "${assetsRoom}03supermarket.jpg";
const String imagePark    = "${assetsRoom}04park.jpg";
const String imageFood    = "${assetsRoom}05food.jpg";
const String imageArcade  = "${assetsRoom}06arcade.jpg";
const String imageSpa     = "${assetsRoom}07spa.jpg";
const String imageRest    = "${assetsRoom}08restaurant.jpg";
const String imageVip     = "${assetsRoom}09vip.jpg";
const String imageTop     = "${assetsRoom}10top.jpg";
const String imageApparel = "${assetsRoom}11apparel.jpg";
const String imageElectro = "${assetsRoom}12electronics.jpg";
const String imageOutdoor = "${assetsRoom}13outdoor.jpg";
const String imageBook    = "${assetsRoom}14book.jpg";
const String imageCandy   = "${assetsRoom}15candy.jpg";
const String imageToy     = "${assetsRoom}16toy.jpg";
const String imageLuxury  = "${assetsRoom}17luxury.jpg";
const String imageSports  = "${assetsRoom}18sports.jpg";
const String imageGym     = "${assetsRoom}19gym.jpg";
const String imageSweets  = "${assetsRoom}20sweets.jpg";
const String imageFurnit  = "${assetsRoom}21furniture.jpg";
const String imageCinema  = "${assetsRoom}22cinema.jpg";

const List<String> initialRoomImages = [
  imageParking, imageStation, imageSuper, imageArcade, imageFood,
  imageBook, imageSpa, imageRest, imageVip, imageTop
];
const List<String> addRoomImages = [
  imageApparel, imageElectro, imagePark, imageOutdoor, imageCandy,
  imageToy, imageLuxury, imageSports, imageGym, imageSweets,
  imageFurnit, imageCinema
];
const List<String> roomImageList = [...initialRoomImages, ...addRoomImages];

///Image Display
const String upArrow = "${assetsElevator}up.png";
const String downArrow = "${assetsElevator}down.png";

///Image Buttons
const String squareButton = "${assetsElevator}square.jpg";
const String openButton = "${assetsElevator}open.png";
const String closeButton = "${assetsElevator}close.png";
const String alertButton = "${assetsElevator}phone.png";
const String pressedSquare = "${assetsElevator}pressedSquare.jpg";
const String pressedOpenButton = "${assetsElevator}pressedOpen.png";
const String pressedCloseButton = "${assetsElevator}pressedClose.png";
const String pressedAlertButton = "${assetsElevator}pressedPhone.png";
const String transpImage = "${assetsElevator}transparent.png";

///Asset Menu
const String appLogo = "${assetsMenu}title.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String twitterLogo = "${assetsMenu}x.png";
const String instagramLogo = "${assetsMenu}instagram.png";
const String youtubeLogo = "${assetsMenu}youtube.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";

///String
const String nextString = "Next Floor: ";

///Web Page
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevatorneo/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevatorneo/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";
const String shopLink = "https://letselevator.designstore.jp";
const String elevatorTwitter = "https://twitter.com/letselevator";
const String elevatorInstagram = "https://www.instagram.com/letselevator/";
const String elevatorYoutube = "https://www.youtube.com/channel/UCIEVfzFOhUTMOXos1zaZrQQ";

///Size Elevator
const double responsibleHeight = 1000;
const double elevatorHeightRate = 16/9;
const double doorWidthRate = 0.355;
const double doorMarginLeftRate = 0.023;
const double doorMarginTopRate = 0.195;
const double roomHeightRate = 1.27;
const double sideFrameWidthRate = 0.024;
const double menuIconSizeRate = 0.06;
const double snackBarFontSizeRate = 0.04;

///Size Display
const double displayHeightRate = 0.12;
const double displayWidthRate = 0.3;
const double displayMarginTopRate = 0.045;
const double displayMarginLeftRate = 0.23;
const double displayFontSizeRate = 0.09;
const double displayArrowHeightRate = 0.14;
const double displayArrowWidthRate = 0.04;
const double displayArrowMarginRate = 0.01;
const double displayNumberWidthRate = 0.16;
const double displayNumberHeightRate = 0.12;

///Size Button
const double buttonPanelWidthRate = 0.26;
const double buttonPanelHeightRate = 0.9;
const double buttonPanelMarginTopRate = 0.3;
const double buttonPanelMarginLeftRate = 0.74;
const double floorButtonSizeRate = 0.09;
const double operationButtonSizeRate = 0.075;
const double buttonNumberFontSizeRate = 0.035;
const double buttonMarginRate = 0.02;
const double buttonBorderWidthRate = 0.01;
const double buttonBorderRadiusRate = 0.015;

///Tooltip
const double tooltipTitleFontRate = 0.05;
const double tooltipDescFontRate = 0.04;
const double tooltipTitleMarginRate = 0.01;
const double tooltipMarginSizeRate = 0.02;
const double tooltipPaddingSizeRate = 0.04;
const double tooltipBorderRadiusRate = 0.04;
const double tooltipOffsetSizeRate = 0.02;

///Menu
const double menuTitleWidthRate = 0.8;
const double menuTitleFontSizeRate = 0.03;
const double menuButtonSizeRate = 0.3;
const double menuButtonFontSizeRate = 0.04;
const double menuAlertTitleFontSizeRate = 0.045;
const double menuAlertDescFontSizeRate = 0.032;
const double menuAlertSelectFontSizeRate = 0.04;

///Menu Bottom Navigation Link
const double linksLogoWidthRate = 0.1;
const double linksLogoHeightRate = 0.12;
const double linksTitleJaFontSizeRate = 0.025;
const double linksTitleEnFontSizeRate = 0.03;
const double linksTitleMarginRate = 0.02;
const double linksMarginRate = 0.04;

///Settings
const double settingsTitleFontSizeRate = 0.03;
const double settingsTitleMarginRate = 0.01;
const double settingsButtonSizeRate = 0.05;
const double settingsButtonMarginRate = 0.015;
const double settingsButtonSpaceRate = 0.035;
const double settingsButtonWidthRate = 0.07;
const double settingsButtonHeightRate = 0.035;
const double settingsButtonFontSizeRate = 0.016;
const double settingsButtonNumberFontSizeRate = 0.02;
const double settingsButtonBorderRadiusRate = 0.03;
const double settingsButtonShadowSizeRate = 0.01;
const double settingsLockFontSizeRate = 0.036;
const double settingsLockIconSizeRate = 0.024;
const double settingsLockSpaceSizeRate = 0.005;
const double settingsImageSelectHeightRate = 0.11;

///Settings Alert
const double settingsAlertTitleFontSizeRate = 0.045;
const double settingsAlertFontSizeRate = 0.04;
const double settingsAlertSelectFontSizeRate = 0.04;
const double settingsAlertFloorNumberSizeRate = 0.12;
const double settingsAlertFloorNumberHeightRate = 0.2;
const double settingsAlertImageSelectHeightRate = 0.4;
const double settingsAlertDropdownMarginRate = 0.01;
const double settingsAlertIconSizeRate = 0.06;
const double settingsAlertIconMarginRate = 0.01;
const double settingsAlertLockFontSizeRate = 0.07;
const double settingsAlertLockIconSizeRate = 0.05;
const double settingsAlertLockSpaceSizeRate = 0.02;
const double settingsAlertLockBorderWidthRate = 0.002;
const double settingsAlertLockBorderRadiusRate = 0.04;

/// Color
const Color lampColor = Color.fromRGBO(247, 178, 73, 1);
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1);
const Color greenColor = Color.fromRGBO(105, 184, 0, 1);
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color grayColor = Colors.grey;
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.6);
const Color darkBlackColor = Colors.black;
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.95);
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;
const Color metalColor1 = Colors.black12;
const Color metalColor2 = Colors.white24;
const Color metalColor3 = Colors.white54;
const Color metalColor4 = Colors.white10;
const Color metalColor5 = Colors.black12;
const List<Color> metalColor = [metalColor1, metalColor2, metalColor3, metalColor4, metalColor5];
const List<double> metalSort = [0.1, 0.3, 0.4, 0.7, 0.9];

//＜電球色lampColor＞
// 電球色 → F7B249
// Red = F7 = 247
// Green = B2 = 178
// Blue = 49 = 73

//＜色温度から算出する電球色lampColor＞
// Temperature = 3000 K → FFB16E
// Red = 255 = FF
// Green = 99.47080 * Ln(30) - 161.11957 = 177 = B1
// Blue = 138.51773 * Ln(30-10) - 305.04480 = 110 = 6E

// ///最高階と最低階
// const int maxBLE = 100;
// const int minBLE = 1;
//
// ///Floors
// const floors = [1, 2, 3, 100];

