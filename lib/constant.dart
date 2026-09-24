import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'main.dart';

// ===== APPLICATION CONFIGURATION =====

/// Application name
const String appTitle = "LETS ELEVATOR NEO";


// Ad unit ID configuration
// Platform-specific ad unit IDs for different build modes
String rewardAdUnitID =
  // Production units resolve through .env at the call site.
  // The demo units are Google's published constants, returned directly.
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_REWARDED_UNIT_ID"):
  (!kDebugMode) ? dotenv.get("ANDROID_REWARDED_UNIT_ID"):
  (Platform.isIOS || Platform.isMacOS) ? iosRewardedTestId:
  androidRewardedTestId;

String bannerAdUnitID =
  // Production units resolve through .env at the call site.
  // The demo units are Google's published constants, returned directly.
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
  (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
  (Platform.isIOS || Platform.isMacOS) ? iosBannerTestId:
  androidBannerTestId;

String interstitialAdUnitID =
  // Production units resolve through .env at the call site.
  // The demo units are Google's published constants, returned directly.
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_INTERSTITIAL_UNIT_ID"):
  (!kDebugMode) ? dotenv.get("ANDROID_INTERSTITIAL_UNIT_ID"):
  (Platform.isIOS || Platform.isMacOS) ? iosInterstitialTestId:
  androidInterstitialTestId;

// Interstitial frequency capping
// Keeps interstitials from interrupting the elevator experience too often
const int interstitialIntervalSec = 180;   // Minimum gap between two interstitials
const int interstitialMaxPerSession = 3;   // Upper bound within a single session
const int interstitialMinRides = 5;        // Rides required before the first interstitial

/// RevenueCat configuration
/// Keys are looked up in assets/.env. The entitlement id must equal the dashboard's;
/// "premium" is taken by another app in the shared project, so this one is prefixed
String revenueCatApiKey = (Platform.isIOS || Platform.isMacOS) ?
  "REVENUE_CAT_IOS_API_KEY":
  "REVENUE_CAT_ANDROID_API_KEY";
const String premiumEntitlementID = "elevatorneo_premium";
/// Wait after the home screen's launch work (splash removed) before fetching the price
const Duration pricePrefetchDelay = Duration(seconds: 3);
/// Lifecycle states in which the app is not visible: no new sound, and playing ones stop.
/// Inactive is still visible (split screen, notification shade), so it is not here
const Set<AppLifecycleState> notVisibleStates = {
  AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.detached,
};
/// Wait after the splash is removed before TTS init and the first sound's load
const Duration soundWarmUpDelay = Duration(seconds: 3);

/// Store review request
/// Minimum rides before asking the user for a store review
const int reviewRequestRides = 30;

// No ATT constants or code in this app: the UMP flow in admob_banner.dart owns the prompt.
// It shows the IDFA explainer and the ATT dialog itself, and ads never wait on it.

/// Ad retry limits: unfilled requests never match, so retrying needs a ceiling.
/// Not symmetric on purpose: nobody waits on a banner, but the user waits on a reward
const int bannerMaxRetry = 5;          // Only a settings round trip re-arms this
const int bannerRetryBaseSec = 30;     // First banner retry delay; doubles each attempt
const int bannerRetryMaxSec = 300;     // Ceiling for the banner backoff
const int rewardedMaxRetry = 3;        // Re-armed by the next button press

/// The consent round trip can hang on a bad network. The reward button waits on
/// it behind a spinner, so it needs a point at which it gives up and answers
const int consentFormTimeoutSec = 15;

// ===== FLOOR CONFIGURATION =====

// Floor configuration
// Minimum and maximum floor numbers, and initial floor position
const int min = -12;
const int max = 163;
int initialFloor = isTest ? max: 2;
int initialCurrent = isTest ? max: 1;

/// Initial floor button configuration
/// List of floor numbers displayed on elevator buttons
const List<int> initialFloorNumbers = [
  min, -1, 1, 2, 4, 6, 14, 100, 154, max,
];
List<bool> initialFloorStops = List.generate(initialFloorNumbers.length, (_) => true);

/// How far the top and bottom buttons may travel.
///
/// 1F never moves, so the buttons above it must fit between 1 and the top, and
/// the buttons below it between the bottom and -1. With ten buttons and 1F at
/// index 2 that leaves eight above ground and two below: the top cannot go
/// under 8F, and the bottom cannot rise above B2.
/// The picker enforces this by stopping at the neighbouring buttons
const int floorButtonCount = 10;
const int oneFloorIndex = 2;

/// Button layout configuration for reversed button arrangement
const List<List<int>> reversedButtonIndex = [
  [8, 9],
  [6, 7],
  [4, 5],
  [2, 3],
  [1, 0],
];

// Button Index calculation functions
// Helper functions to determine button positions and states
bool isBasement(int row, int col) => (row == 4);
int buttonCol(int row, int col) => isBasement(row, col) ? (1 - col) : col;
int buttonIndex(int row, int col) => 2 * (4 - row) + buttonCol(row, col);
/// How far the two 1F controls are faded. They are dimmed rather than covered:
/// a black plate over the cell hides the floor number itself
const double fixedFloorOpacity = 0.35;

/// CupertinoSwitch fades itself by 0.5 when onChanged is null
/// (`cupertino/switch.dart` _kDisabledOpacity), so the switch needs a
/// lighter touch to land on the same 0.35 as the button beside it
const double fixedFloorSwitchOpacity = fixedFloorOpacity * 2;

/// Only 1F is fixed. The top and the bottom move too, within the range above
bool isNotSelectFloor(int row, int col) => (col == 0 && row == 3);

/// The last stop above or below 1F cannot be turned off: the car needs
/// somewhere to go on each side of the fixed floor
bool isOnlyStop(List<bool> stops, int index) {
  if (!stops[index]) return false;
  for (int i = 0; i < stops.length; i++) {
    if (i == index || i == oneFloorIndex) continue;
    if ((i < oneFloorIndex) == (index < oneFloorIndex) && stops[i]) return false;
  }
  return true;
}

/// The gap a button may move within: strictly between its neighbours, inside
/// min..max, and never floor 0. Both the picker and the save use this
bool isInFloorGap(List<int> list, int index, int value) {
  if (value == 0 || value < min || max < value) return false;
  if (index == oneFloorIndex) return false;
  if (index > 0 && value <= list[index - 1]) return false;
  if (index < list.length - 1 && value >= list[index + 1]) return false;
  return true;
}

/// A saved panel from an older build may break the rule above: before the
/// pickers were bounded, the basement buttons could be set independently. Repair
/// what is broken and keep the rest, rather than throw the whole panel away
List<int> normalizedFloorNumbers(List<int> numbers) {
  if (numbers.length != initialFloorNumbers.length) return initialFloorNumbers;
  final list = List<int>.from(numbers)..[oneFloorIndex] = 1;
  for (int i = oneFloorIndex - 1; i >= 0; i--) {
    if (list[i] >= list[i + 1]) list[i] = list[i + 1] - 1;
    if (list[i] == 0) list[i] = -1;
  }
  for (int i = oneFloorIndex + 1; i < list.length; i++) {
    if (list[i] <= list[i - 1]) list[i] = list[i - 1] + 1;
  }
  // Pushing can run off either end. Nothing sensible is left to keep there
  if (list.first < min || max < list.last) return initialFloorNumbers;
  return list;
}

/// Each side of 1F needs a stop. A save made before that rule may have none
List<bool> normalizedFloorStops(List<bool> stops) {
  if (stops.length != initialFloorStops.length) return initialFloorStops;
  final list = List<bool>.from(stops)..[oneFloorIndex] = true;
  if (!list.sublist(0, oneFloorIndex).contains(true)) list[oneFloorIndex - 1] = true;
  if (!list.sublist(oneFloorIndex + 1).contains(true)) list[oneFloorIndex + 1] = true;
  return list;
}

// ===== GAMEPLAY & UNLOCK SYSTEM =====

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

// ===== TIMING & ANIMATION =====

// Vibration settings
// Duration and amplitude for haptic feedback
const int vibTime = 200;
const int vibAmp = 128;

/// Tooltip display duration
const int toolTipTime = 10000; //[msec]

// Elevator door timing configuration
// Various timing settings for door operations and UI elements
const int initialOpenTime = 10; //[sec]
const int initialWaitTime =  2; //[sec]
const int flashTime = 700;      //[msec]
const int operationTime = 300;  //[msec]

// ===== ELEVATOR STATE MANAGEMENT =====

// Elevator door states
// Boolean arrays representing different door states: [opened, closed, opening, closing]
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

// Elevator button states
// Boolean arrays representing different button press states: [open, close, call]
final List<bool> noPressed = [false, false, false];
final List<bool> pressedOpen = [true, false, false];
final List<bool> pressedClose = [false, true, false];
final List<bool> pressedCall = [false, false, true];
final List<bool> allPressed = [true, true, true];

// ===== AUDIO CONFIGURATION =====

// Audio configuration
// Sound file paths for various elevator operations
const String selectSound = "assets/audios/kako.mp3";
const String cancelSound = "assets/audios/hi.mp3";
const String changeSound = "assets/audios/popi.mp3";
const String callSound   = "assets/audios/call.mp3";
const String openSound   = "assets/audios/pingpong.mp3";
const String closeSound  = "assets/audios/ping.mp3";

// ===== FONT CONFIGURATION =====

// Font configuration
// Font families for numbers and alphabets
const List<String> numberFont = ["lcd", "dseg", "dseg"];
const List<String> alphabetFont = ["lcd", "letsgo", "letsgo"];

// ===== ASSET PATHS =====

// Asset folder paths
// Base paths for different asset categories
const String assetsButton = "assets/images/button/";
const String assetsElevator = "assets/images/elevator/";
const String assetsMenu = "assets/images/menu/";
const String assetsRoom = "assets/images/room/";
const String assetsSettings = "assets/images/settings/";

// ===== ELEVATOR UI CONFIGURATION =====

// Elevator image configuration
// Button styles, shapes, and visual themes
const int operationButtonCount = 3;
const int initialButtonStyle = 0;
String initialButtonShape = buttonShapeList[1];
String initialBackgroundStyle = backgroundStyleList[0];
String initialGlassStyle = glassStyleList[0];
const int numberButtonColumnCount = 3;

// Settings and style lists
const List<String> settingsItemList = ["floor", "number", "button", "style"];

/// Settings tabs that hold something the premium unlock opens.
/// LETS's number tab is free, so it is not listed. The paywall draws one
/// icon per entry, which keeps it correct when a tab gains a new feature
const List<String> premiumTabList = ["floor", "number", "button", "style"];
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
/// Star, heart and cat sit off their geometric centre. Fraction of button size
const List<double> floorButtonNumberOffset = [
  0.0, 0.0, 0.0,
  0.0, 0.0, 0.0,
  0.047, -0.050, 0.016,
];

// Elevator frame images
const String leftSideFrame = "${assetsElevator}sideFrameLeft.png";
const String rightSideFrame = "${assetsElevator}sideFrameRight.png";
const String pointImage = "${assetsElevator}elevatorPoint.png";

// Hall lamp images
const String hallLampUp = "${assetsElevator}hallLamp_up.jpg";
const String hallLampDown = "${assetsElevator}hallLamp_down.jpg";
const String hallLampOn = "${assetsElevator}hallLamp_on.jpg";
const String hallLampOff = "${assetsElevator}hallLamp_off.jpg";

// ===== ROOM BACKGROUND IMAGES =====

// Room background images
// Floor-specific background images for different locations
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
const String imageApplian = "${assetsRoom}23appliance.jpg";

// Floor image lists
// Initial and additional floor images for different building types
const List<String> initialFloorImages = [
  imageParking, imageStation, imageSuper, imageArcade, imageFood,
  imageBook, imageSpa, imageRest, imageVip, imageTop
];
const List<String> addFloorImages = [
  imageApparel, imageElectro, imagePark, imageOutdoor, imageCandy,
  imageToy, imageLuxury, imageSports, imageGym, imageSweets,
  imageFurnit, imageCinema, imageApplian
];
const List<String> floorImageList = [...initialFloorImages, ...addFloorImages];

// ===== BUTTON & MENU ASSETS =====

// Button images
// Transparent and default button images
const String transpImage = "${assetsButton}transparent.png";
const String squareButton = "${assetsButton}normal1.png";

// Menu asset images
// UI elements for menu screens and social media links
const String menuBackGroundImage = "${assetsMenu}metal.png";
const String settingsButton = "${assetsMenu}settings.png";
const String rankingButton = "${assetsMenu}ranking.png";
const String adRewardButton = "${assetsMenu}adReward.png";
// Baked from square1.png and purchase.svg by the purchase_bake.sh next to them.
// Edit the SVG and re-run the script; do not retouch the PNG by hand.
const String purchaseButton = "${assetsMenu}purchase.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String twitterLogo = "${assetsMenu}x.png";
const String instagramLogo = "${assetsMenu}instagram.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";

// ===== WEB LINKS & EXTERNAL URLs =====

// Web page URLs
// Landing pages, privacy policy, and social media links
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevatorneo/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevatorneo/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";
const String shopLink = "https://letselevator.designstore.jp";
const String elevatorTwitter = "https://twitter.com/letselevator";
const String elevatorInstagram = "https://www.instagram.com/letselevator/";

// ===== COLOR DEFINITIONS =====

// Primary colors
const Color lampColor = Color.fromRGBO(247, 178, 73, 1); //#f7b249
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;

// Light colors for various UI elements
const Color lightBlueColor = Colors.lightBlue;
const Color goldLightColor = Color.fromRGBO(212, 175, 55, 1);
const Color pinkLightColor = Color.fromRGBO(255, 128, 192, 1);
const Color redLightColor = Color.fromRGBO(255, 64, 64, 1);
const Color blueLightColor = Color.fromRGBO(16, 192, 255, 1); //#10c0ff
const Color purpleLightColor = Color.fromRGBO(192, 128, 255, 1);
const Color greenLightColor = Color.fromRGBO(64, 255, 64, 1);
const Color lightGrayColor = Color.fromRGBO(192, 192, 192, 1);

// Standard colors
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1); //#ffea00
const Color greenColor = Color.fromRGBO(105, 184, 0, 1); //#69b800
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color grayColor = Colors.grey;

// Transparent colors
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.6);
const Color darkBlackColor = Colors.black;
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.95);

// Display color schemes
// Background and text colors for different display themes
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

// Color calculation notes. Shimada's lamp: F7B249 (R 247, G 178, B 73)
// 3000 K -> FFB16E: G = 99.47080*Ln(30)-161.11957 = B1, B = 138.51773*Ln(20)-305.04480 = 6E

// --- AdMob demo ad units --- Published by Google, so not secret; they live here, not in .env.
// Adaptive banners need their own unit, not the 320x50 one.
const String androidBannerTestId = "ca-app-pub-3940256099942544/9214589741";
const String iosBannerTestId = "ca-app-pub-3940256099942544/2435281174";
const String androidRewardedTestId = "ca-app-pub-3940256099942544/5224354917";
const String iosRewardedTestId = "ca-app-pub-3940256099942544/1712485313";
const String androidInterstitialTestId = "ca-app-pub-3940256099942544/1033173712";
const String iosInterstitialTestId = "ca-app-pub-3940256099942544/4411468910";
