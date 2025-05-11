import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///アプリ名
const String appTitle = "LETS ELEVATOR NEO";

///App Check
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.appAttestWithDeviceCheckFallback;

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
List<List<int>> changePointList = [
  [50000, 99999],
  [ 5000, 20000],
  [  500,  2000],
  [    0,   200],
  [ 1000, 10000],
];
const int albumImagePoint = 2000;
const initialPoint = 0;
const String earnMiles = "1,000";
const int earnMilesInt = 1000;

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
const int waitTime = 2;       //[sec]
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
const String assetsButton = "assets/images/button/";
const String assetsElevator = "assets/images/elevator/";
const String assetsMenu = "assets/images/menu/";
const String assetsRoom = "assets/images/room/";
const String assetsSettings = "assets/images/settings/";

///Image Elevator
const int buttonShapeLockPoint = 10000;
const int operationButtonCount = 3;
const int initialButtonStyle = 0;
String initialButtonShape = buttonShapeList[1];
String initialBackgroundStyle = backgroundStyleList[0];
String initialGlassStyle = glassStyleList[0];
const int numberButtonColumnCount = 3;
const List<String> settingsItemList = ["floor", "number", "button", "style"];
const List<String> backgroundStyleList = ["metal", "white", "wood", "pop"];
const List<String> glassStyleList = ["not", "use"];
const List<String> buttonShapeList = [
  "normal", "circle", "square",
  "diamond", "hexagon", "clover",
  "star", "heart", "cat",
];
const List<Color> numberColorList = [
  lampColor, lampColor, blueLightColor,
  redLightColor, purpleLightColor, greenLightColor,
  yellowColor, pinkLightColor, goldLightColor,
];
const List<double> floorButtonNumberSizeFactor = [
  1.0, 1.0, 1.0,
  1.0, 1.0, 1.0,
  0.9, 0.9, 1.0,
];
const List<double> floorButtonNumberMarginFactor = [
  0.0, 0.0, 0.0,
  0.0, 0.0, 0.0,
  0.006, -0.01, 0.002,
];
const int backgroundLockPoint = 10000;
const String leftSideFrame = "${assetsElevator}sideFrameLeft.png";
const String rightSideFrame = "${assetsElevator}sideFrameRight.png";
const String pointImage = "${assetsElevator}elevatorPoint.png";

///Image Room
const String imageFloor   = "${assetsRoom}00floor.png";
const String imageDark    = "${assetsRoom}00dark.png";
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
const String transpImage = "${assetsButton}transparent.png";
const String squareButton = "${assetsButton}normal1.png";

///Asset Menu
const String settingsButton = "${assetsMenu}settings.png";
const String rankingButton = "${assetsMenu}ranking.png";
const String adRewardButton = "${assetsMenu}adReward.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String twitterLogo = "${assetsMenu}x.png";
const String instagramLogo = "${assetsMenu}instagram.png";
const String youtubeLogo = "${assetsMenu}youtube.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";

///Web Page
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevatorneo/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevatorneo/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";
const String shopLink = "https://letselevator.designstore.jp";
const String elevatorTwitter = "https://twitter.com/letselevator";
const String elevatorInstagram = "https://www.instagram.com/letselevator/";
const String elevatorYoutube = "https://www.youtube.com/channel/UCIEVfzFOhUTMOXos1zaZrQQ";

///Size
const double responsibleHeight = 1000;
const double elevatorHeightRate = 16/9;

/// Color
const Color lampColor = Color.fromRGBO(247, 178, 73, 1); //#f7b249
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color goldLightColor = Color.fromRGBO(212, 175, 55, 1);
const Color pinkLightColor = Color.fromRGBO(255, 128, 192, 1);
const Color redLightColor = Color.fromRGBO(255, 64, 64, 1);
const Color blueLightColor = Color.fromRGBO(16, 192, 255, 1);
const Color purpleLightColor = Color.fromRGBO(192, 128, 255, 1);
const Color greenLightColor = Color.fromRGBO(64, 255, 64, 1);
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1); //#ffea00
const Color greenColor = Color.fromRGBO(105, 184, 0, 1);  //#69b800
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color lightGrayColor =Color.fromRGBO(192, 192, 192, 1);
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

