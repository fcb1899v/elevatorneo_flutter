import 'dart:io';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// =============================================================================
// APPLICATION CONFIGURATION
// =============================================================================

/// Application name
const String appTitle = "LETS ELEVATOR NEO";

/// Firebase App Check configuration
/// Uses debug provider in debug mode, production provider in release mode
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.appAttestWithDeviceCheckFallback;

/// Ad unit ID configuration
/// Platform-specific ad unit IDs for different build modes
String rewardAdUnitID =
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? "IOS_REWARDED_UNIT_ID":
  (!kDebugMode) ? "ANDROID_REWARDED_UNIT_ID":
  (Platform.isIOS || Platform.isMacOS) ? "IOS_REWARDED_TEST_ID":
  "ANDROID_REWARDED_TEST_ID";

// =============================================================================
// FLOOR CONFIGURATION
// =============================================================================

/// Floor configuration
/// Minimum and maximum floor numbers, and initial floor position
const int min = -6;
const int max = 163;
const int initialFloor = 2;

/// Initial floor button configuration
/// List of floor numbers displayed on elevator buttons
const List<int> initialFloorNumbers = [
  min, -1, 1, 2, 4, 6, 14, 100, 154, max,
];
List<bool> initialFloorStops = List.generate(initialFloorNumbers.length, (_) => true);

/// Button layout configuration for reversed button arrangement
const List<List<int>> reversedButtonIndex = [
  [8, 9],
  [6, 7],
  [4, 5],
  [2, 3],
  [1, 0],
];

/// Button Index calculation functions
/// Helper functions to determine button positions and states
bool isBasement(int row, int col) => (row == 4);
int buttonCol(int row, int col) => isBasement(row, col) ? (1 - col) : col;
int buttonIndex(int row, int col) => 2 * (4 - row) + buttonCol(row, col);
bool isNotSelectFloor(int row, int col) =>
    (col == 0 && row == 3) || (col == 1 && (row == 0 || row == 4));

// =============================================================================
// GAMEPLAY & UNLOCK SYSTEM
// =============================================================================

/// Unlock points configuration
/// Points required to unlock various features
List<List<int>> changePointList = [
  [50000, 99999],
  [ 5000, 20000],
  [  500,  2000],
  [    0,   200],
  [ 1000, 10000],
];
const int albumImagePoint = 2000;
const int buttonStyleLockPoint = 10000;
const int buttonShapeLockPoint = 10000;
const int backgroundLockPoint = 10000;
const String earnMiles = "1,000";
const int earnMilesInt = 1000;

// =============================================================================
// TIMING & ANIMATION
// =============================================================================

/// Vibration settings
/// Duration and amplitude for haptic feedback
const int vibTime = 200;
const int vibAmp = 128;

/// Tooltip display duration
const int toolTipTime = 10000; //[msec]

/// Elevator door timing configuration
/// Various timing settings for door operations and UI elements
const int initialOpenTime = 10; //[sec]
const int initialWaitTime =  2; //[sec]
const int flashTime = 700;      //[msec]

// =============================================================================
// ELEVATOR STATE MANAGEMENT
// =============================================================================

/// Elevator door states
/// Boolean arrays representing different door states: [opened, closed, opening, closing]
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

/// Elevator button states
/// Boolean arrays representing different button press states: [open, close, call]
final List<bool> noPressed = [false, false, false];
final List<bool> pressedOpen = [true, false, false];
final List<bool> pressedClose = [false, true, false];
final List<bool> pressedCall = [false, false, true];
final List<bool> allPressed = [true, true, true];

// =============================================================================
// AUDIO CONFIGURATION
// =============================================================================

/// Audio configuration
/// Sound file paths for various elevator operations
const String selectSound = "assets/audios/kako.mp3";
const String cancelSound = "assets/audios/hi.mp3";
const String changeSound = "assets/audios/popi.mp3";
const String callSound   = "assets/audios/call.mp3";
const String openSound   = "assets/audios/pingpong.mp3";
const String closeSound  = "assets/audios/ping.mp3";

// =============================================================================
// FONT CONFIGURATION
// =============================================================================

/// Font configuration
/// Font families for numbers and alphabets
const List<String> numberFont = ["lcd", "dseg", "dseg"];
const List<String> alphabetFont = ["lcd", "letsgo", "letsgo"];

// =============================================================================
// ASSET PATHS
// =============================================================================

/// Asset folder paths
/// Base paths for different asset categories
const String assetsButton = "assets/images/button/";
const String assetsElevator = "assets/images/elevator/";
const String assetsMenu = "assets/images/menu/";
const String assetsRoom = "assets/images/room/";
const String assetsSettings = "assets/images/settings/";

// =============================================================================
// ELEVATOR UI CONFIGURATION
// =============================================================================

/// Elevator image configuration
/// Button styles, shapes, and visual themes
const int operationButtonCount = 3;
const int initialButtonStyle = 0;
String initialButtonShape = buttonShapeList[1];
String initialBackgroundStyle = backgroundStyleList[0];
String initialGlassStyle = glassStyleList[0];
const int numberButtonColumnCount = 3;

/// Settings and style lists
const List<String> settingsItemList = ["floor", "number", "button", "style"];
const List<String> backgroundStyleList = ["metal", "white", "wood", "pop"];
const List<String> glassStyleList = ["not", "use"];
const List<String> buttonShapeList = [
  "normal", "circle", "square",
  "diamond", "hexagon", "clover",
  "star", "heart", "cat",
];

/// Button size and margin factors for different shapes
/// Adjusts text size and positioning for various button shapes
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

/// Elevator frame images
const String leftSideFrame = "${assetsElevator}sideFrameLeft.png";
const String rightSideFrame = "${assetsElevator}sideFrameRight.png";
const String pointImage = "${assetsElevator}elevatorPoint.png";

/// Hall lamp images
const String hallLampUp = "${assetsElevator}hallLamp_up.jpg";
const String hallLampDown = "${assetsElevator}hallLamp_down.jpg";
const String hallLampOn = "${assetsElevator}hallLamp_on.jpg";
const String hallLampOff = "${assetsElevator}hallLamp_off.jpg";

// =============================================================================
// ROOM BACKGROUND IMAGES
// =============================================================================

/// Room background images
/// Floor-specific background images for different locations
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

/// Floor image lists
/// Initial and additional floor images for different building types
const List<String> initialFloorImages = [
  imageParking, imageStation, imageSuper, imageArcade, imageFood,
  imageBook, imageSpa, imageRest, imageVip, imageTop
];
const List<String> addFloorImages = [
  imageApparel, imageElectro, imagePark, imageOutdoor, imageCandy,
  imageToy, imageLuxury, imageSports, imageGym, imageSweets,
  imageFurnit, imageCinema
];
const List<String> floorImageList = [...initialFloorImages, ...addFloorImages];

// =============================================================================
// BUTTON & MENU ASSETS
// =============================================================================

/// Button images
/// Transparent and default button images
const String transpImage = "${assetsButton}transparent.png";
const String squareButton = "${assetsButton}normal1.png";

/// Menu asset images
/// UI elements for menu screens and social media links
const String menuBackGroundImage = "${assetsMenu}metal.png";
const String settingsButton = "${assetsMenu}settings.png";
const String rankingButton = "${assetsMenu}ranking.png";
const String adRewardButton = "${assetsMenu}adReward.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String twitterLogo = "${assetsMenu}x.png";
const String instagramLogo = "${assetsMenu}instagram.png";
const String youtubeLogo = "${assetsMenu}youtube.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";

// =============================================================================
// WEB LINKS & EXTERNAL URLs
// =============================================================================

/// Web page URLs
/// Landing pages, privacy policy, and social media links
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevatorneo/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevatorneo/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";
const String youtubeJa = "https://www.youtube.com/watch?v=CQuYL0wG47E";
const String youtubeEn = "https://www.youtube.com/watch?v=oMhqBiNHAtA";
const String shopLink = "https://letselevator.designstore.jp";
const String elevatorTwitter = "https://twitter.com/letselevator";
const String elevatorInstagram = "https://www.instagram.com/letselevator/";
const String elevatorYoutube = "https://www.youtube.com/channel/UCIEVfzFOhUTMOXos1zaZrQQ";

// =============================================================================
// COLOR DEFINITIONS
// =============================================================================

/// Primary colors
const Color lampColor = Color.fromRGBO(247, 178, 73, 1); //#f7b249
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;

/// Light colors for various UI elements
const Color lightBlueColor = Colors.lightBlue;
const Color goldLightColor = Color.fromRGBO(212, 175, 55, 1);
const Color pinkLightColor = Color.fromRGBO(255, 128, 192, 1);
const Color redLightColor = Color.fromRGBO(255, 64, 64, 1);
const Color blueLightColor = Color.fromRGBO(16, 192, 255, 1); //#10c0ff
const Color purpleLightColor = Color.fromRGBO(192, 128, 255, 1);
const Color greenLightColor = Color.fromRGBO(64, 255, 64, 1);
const Color lightGrayColor = Color.fromRGBO(192, 192, 192, 1);

/// Standard colors
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1); //#ffea00
const Color greenColor = Color.fromRGBO(105, 184, 0, 1); //#69b800
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color grayColor = Colors.grey;

/// Transparent colors
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.6);
const Color darkBlackColor = Colors.black;
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.95);

/// Display color schemes
/// Background and text colors for different display themes
const List<Color> displayBackgroundColor = [
  darkBlackColor, darkBlackColor, lightBlueColor
];
const List<Color> displayNumberColor = [
  lampColor, whiteColor, whiteColor
];
const List<Color> numberColorList = [
  lampColor, lampColor, blueLightColor,
  redLightColor, purpleLightColor, greenLightColor,
  yellowColor, pinkLightColor, goldLightColor,
];

/// Color calculation notes

//＜Shimada's lamp　color＞
// [F7B249]
// Red = F7 = 247
// Green = B2 = 178
// Blue = 49 = 73

//＜Lamp color from temperature＞
// Temperature = 3000 K → FFB16E
// Red = 255 = FF
// Green = 99.47080 * Ln(30) - 161.11957 = 177 = B1
// Blue = 138.51773 * Ln(30-10) - 305.04480 = 110 = 6E
