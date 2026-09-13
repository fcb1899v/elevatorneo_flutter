// ===== SettingsPage: floor, button, background and glass customization =====
// Photo selection, point-based unlocks, scroll management and persistence.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'analytics_manager.dart';
import 'games_manager.dart';
import 'photo_manager.dart';
import 'image_manager.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'admob_banner.dart';
import 'main.dart';
import 'plan_provider.dart';
import 'premium_page.dart';
import 'purchase_manager.dart';
import 'homepage.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- Provider State Management ---
    // Riverpod providers for managing app settings and state
    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final roomImages = ref.watch(floorImagesProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final point = ref.watch(pointProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);
    final glassStyle = ref.watch(glassStyleProvider);
    final isPremium = ref.watch(planProvider).isPremium;

    // --- Hooks State Management ---
    // Local state management using Flutter Hooks for UI interactions
    final scrollController = useScrollController();                    // Scroll view controller
    final imageManager = useMemoized(() => ImageManager());           // Image management service
    final photoManager = useMemoized(() => PhotoManager(context: context)); // Photo selection service
    final isButtonOn = useState(List.generate(5, (_) => List.generate(2, (_) => false))); // Button selection states
    final isImageOn  = useState(List.generate(5, (_) => List.generate(2, (_) => false))); // Image selection states
    final selectedNumber = useState(0);                               // Currently selected floor number
    final showSettingNumber = useState(0);                            // Active settings tab index
    final hasScrolledOnce = useState(false);                          // Scroll state tracking
    final isLoadingData = useState(false);                            // Data loading state
    // The price the store returned, empty until it answers. Every purchase entry
    // point is drawn from this, never from "the SDK started", which may sell nothing
    final storePrice = useState("");
    final animationController = useAnimationController(duration:Duration(milliseconds: flashTime))..repeat(reverse: true);

    // --- Widget and Manager Instances ---
    // UI widget instances and service managers
    final common = CommonWidget(context);

    // --- Premium Purchase Functions ---
    // Entry points: the lock overlays, and the app bar button for those who skip locks

    /// Run the purchase or restore flow and report the result to the user
    Future<void> runPurchase({required bool isRestore, required String source}) async {
      isLoadingData.value = true;
      try {
        final purchased = await PurchaseManager.buyPremium(
          isRestore: isRestore,
          source: source,
        );
        if (!context.mounted) return;
        if (purchased) {
          await ref.read(planProvider.notifier).setCurrentPlan(true);
          if (!context.mounted) return;
          common.commonSnackBar(context.premiumThanks());
        } else if (isRestore) {
          common.commonSnackBar(context.premiumRestoreFailed());
        }
      } catch (e) {
        "Purchase error: $e".debugPrint();
        // Nothing to sell is not a failed purchase. The reviewer sees this one
        // while the product is still attached to the submission
        if (context.mounted) {
          common.commonSnackBar((e is StoreUnavailableException)
            ? context.premiumUnavailable()
            : context.premiumFailed());
        }
      } finally {
        isLoadingData.value = false;
      }
    }

    /// Open the upgrade dialog, shared by the lock overlays and the app bar. The
    /// price is fetched again since the offering or network can drop; empty is announced
    Future<void> openUpgrade(String source) async {
      isLoadingData.value = true;
      final price = await PurchaseManager.fetchPrice();
      if (!context.mounted) return;
      isLoadingData.value = false;
      // An empty price still opens the page: the button says "Buy" without an
      // amount, and pressing it reports why nothing happened
      storePrice.value = price ?? "";
      ref.read(planProvider.notifier).setPrice(price ?? "");
      await AnalyticsManager.upgradeOffered(source);
      if (!context.mounted) return;
      context.pushPage(PremiumPage(
        price: price ?? "",
        onBuy: () async {
          context.popPage();
          await runPurchase(isRestore: false, source: source);
        },
        onRestore: () async {
          context.popPage();
          await runPurchase(isRestore: true, source: source);
        },
      ));
    }

    /// Offer the premium unlock when the user taps a locked feature. The tap is
    /// logged first, always; the offer follows only when the store returned a price
    Future<void> showUpgrade(String feature, int requiredPoint) async {
      await AnalyticsManager.unlockBlocked(
        feature: feature,
        requiredPoint: requiredPoint,
        currentPoint: point,
      );
      await openUpgrade(feature);
    }

    final settings = SettingsWidget(context,
      point: point,
      roomImages: roomImages,
      floorNumbers: floorNumbers,
      floorStops: floorStops,
      buttonStyle: buttonStyle,
      buttonShape: buttonShape,
      backgroundStyle: backgroundStyle,
      glassStyle: glassStyle,
      isPremium: isPremium,
      onLockTap: showUpgrade,
    );

    /// --- Initialization Effect ---
    // Connectivity checks, initial settings data and loading states
    useEffect(() {

      Future<void> gamesInit() async {
        final gamesManager = GamesManager(
          isGamesSignIn: false,
          isConnectedInternet: false,
        );
        final hasInternet = await gamesManager.checkInternetConnection();
        final updatedGamesManager = GamesManager(
            isGamesSignIn: false,
            isConnectedInternet: hasInternet
        );
        final signedIn = await updatedGamesManager.gamesSignIn();
        final reUpdatedGamesManager = GamesManager(
            isGamesSignIn: signedIn,
            isConnectedInternet: hasInternet
        );
        final bestScore = await reUpdatedGamesManager.getBestScore();
        ref.read(internetProvider.notifier).setValue(hasInternet);
        ref.read(gamesSignInProvider.notifier).setValue(signedIn);
        // Runs unawaited so the user can keep earning meanwhile; a plain setValue
        // would drop what arrived in flight. Mileage only ever goes up
        ref.read(pointProvider.notifier).setValue(
          (bestScore > ref.read(pointProvider)) ? bestScore: ref.read(pointProvider)
        );
      }

      initState() async {
        isLoadingData.value = true;
        try {
          if (!isGamesSignIn) gamesInit();
        } catch (e) {
          "Error: $e".debugPrint();
        } finally {
          isLoadingData.value = false;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
        if (scrollController.hasClients) scrollController.jumpTo(scrollController.position.maxScrollExtent);
        hasScrolledOnce.value = false;
        // Settings is a deliberate navigation long after the first frame, so starting
        // the store SDK here costs launch nothing. The price decides the purchase UI
        final price = await PurchaseManager.fetchPrice();
        if (!context.mounted) return;
        if (price != null) {
          storePrice.value = price;
          ref.read(planProvider.notifier).setPrice(price);
        }
      });

      // Control scroll position tracking
      void listener() {
        if (scrollController.offset > 10) hasScrolledOnce.value = true;
      }
      scrollController.addListener(listener);
      return () {
        scrollController.removeListener(listener);
      };
    }, []);

    /// --- Scroll Management Functions ---
    // Animate scroll view to top with smooth transition
    void scrollToTop() {
      scrollController.animateTo(0.0,
        duration: Duration(milliseconds: flashTime),
        curve: Curves.easeOut,
      );
    }

    /// --- Settings Tab Management Effect ---
    // Handle settings tab changes and scroll behavior
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) scrollController.jumpTo(scrollController.position.maxScrollExtent);
        hasScrolledOnce.value = false;
      });
      return null;
    }, [showSettingNumber.value]);

    /// --- Settings Configuration Functions ---
    // Change active settings tab with vibration feedback
    void changeSelectButton(int i) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      showSettingNumber.value = i;
    }

    // Open floor image change dialog with selection options
    // Handles both preset images and user photo selection
    void openChangeImageDialog(int row, col) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      isImageOn.value[row][col] = true;
      isImageOn.value = List.from(isImageOn.value);
      settings.floorImagePickerDialog(row, col,
        onChanged: (String? newValue, int row, int col) async {
          if (newValue != null) {
            Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
            ref.read(floorImagesProvider.notifier).setValue(await imageManager.saveImagePath(
              currentList: roomImages,
              newIndex: buttonIndex(row, col),
              newValue: newValue
            ));
          }
          if (context.mounted) context.popPage();
        },
        onChangedMyPhoto: (row, col) async {
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          ref.read(floorImagesProvider.notifier).setValue(await photoManager.selectMyPhoto(
            row: row,
            col: col,
            currentList: roomImages
          ));
          if (context.mounted) context.popPage();
        },
        then: (row, col) {
          isImageOn.value[row][col] = false;
          isImageOn.value = List.from(isImageOn.value);
        },
      );
    }

    // Change floor button number with validation and selection dialog
    // Handles floor number selection for configurable buttons
    void changeButtonNumber(int row, col) {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        isButtonOn.value[row][col] = true;
        isButtonOn.value = List.from(isButtonOn.value);
        // The picker does not report the row it opens on, so seed it here or OK
        // would save whatever the previous dialog left behind
        selectedNumber.value = floorNumbers[reversedButtonIndex[row][col]];
        settings.floorNumberSelectDialog(row, col,
          select: (int index) {
            selectedNumber.value = floorNumbers.selectedFloor(index, row, col);
            "Select number: ${selectedNumber.value}".debugPrint();
          },
          ok: () async {
            Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
            ref.read(floorNumbersProvider.notifier).setValue(await imageManager.saveFloorNumber(
              currentList: floorNumbers,
              newIndex: reversedButtonIndex[row][col],
              newValue: selectedNumber.value
            ));
            if (context.mounted) context.popPage();
          },
          then: () async {
            isButtonOn.value[row][col] = false;
            isButtonOn.value = List.from(isButtonOn.value);
          }
        );
      }
    }

    // Change floor stop configuration with validation
    // Toggles whether elevator stops at specific floors
    Future<void> changeFloorStop(bool value, int row, col) async {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        ref.read(floorStopsProvider.notifier).setValue(await imageManager.saveFloorStops(
          currentList: floorStops,
          newIndex: reversedButtonIndex[row][col],
          newValue: value
        ));
      }
    }

    // Change button style with persistence
    // Updates button visual style and saves to storage
    Future<void> changeButtonStyle(int value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(buttonStyleProvider.notifier).setValue(await imageManager.changeSettingsIntValue(
        key: "buttonStyleKey",
        current: buttonStyle,
        next: value
      ));
    }

    // Change button shape with persistence
    // Updates button shape and saves to storage
    Future<void> changeButtonShape(String value) async {
      ref.read(buttonShapeProvider.notifier).setValue(await imageManager.changeSettingsStringValue(
        key: "buttonShapeKey",
        current: buttonShape,
        next: value,
      ));
    }

    // Change glass panel style with persistence
    // Toggles glass panel visibility and saves to storage
    Future<void> changeGlassStyle(bool value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(glassStyleProvider.notifier).setValue(await imageManager.changeSettingsStringValue(
        key: "glassStyleKey",
        current: glassStyle,
        next: value ? "use": "non"
      ));
    }

    // Change background style with persistence
    // Updates background image and saves to storage
    Future<void> changeBackground(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(backgroundStyleProvider.notifier).setValue(await imageManager.changeSettingsStringValue(
        key: "backgroundStyleKey",
        current: backgroundStyle,
        next: value
      ));
    }

    // Handle back button press with navigation
    // Returns to main menu and home page
    Future<void> pressedBack() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).setValue(false);
      void backToHome() {
        if (context.mounted) context.pushFadeReplacement(HomePage());
      }
      // No interstitial here: a full screen ad on the way back to the elevator was
      // judged not worth the retention cost; rewarded is the only full screen format
      backToHome();
    }

    /// --- UI Rendering ---
    // Main settings interface structure with conditional content
    return Scaffold(
      /// App bar with animated back button and title
      appBar: settings.settingsAppBar(
        animation: animationController,
        onPressed: () => pressedBack(),
      ),
      /// Main body with settings content
      body: Stack(children: [
        /// Background image for settings
        common.commonBackground(menuBackGroundImage),
        /// Settings content layout
        Column(children: [
          /// Settings tab selection buttons
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(settingsItemList.length, (i) =>
              settings.selectButtonWidget(
                image: showSettingNumber.value.settingsButton(i),
                onTap: () => changeSelectButton(i)
              )
            ),
          ),
          settings.settingsDivider(),
          /// Floor image customization section
          (showSettingNumber.value == 0) ? Expanded(
            child: Stack(children: [
              SingleChildScrollView(
                controller: scrollController,
                child: settings.settingsFloorImageWidget(
                  isImageOn: isImageOn.value,
                  onTap: openChangeImageDialog
                )
              ),
              /// Scroll to top button when content is scrollable
              if (!hasScrolledOnce.value) settings.scroolUpButton(
                animation: animationController,
                onTap: scrollToTop
              ),
            ])
          ):
          /// Floor number configuration section
          (showSettingNumber.value == 1) ? settings.settingsFloorNumberWidget(
            isButtonOn: isButtonOn.value,
            changeButtonNumber: changeButtonNumber,
            changeFloorStopFlag: changeFloorStop,
          ):
          /// Button style selection section with lock overlay
          (showSettingNumber.value == 2) ? Stack(alignment: Alignment.center,
            children: [
              settings.settingsButtonStyleWidget(onTap: changeButtonStyle),
              /// Lock overlay for premium features
              if (settings.isLocked(buttonStyleLockPoint)) settings.settingsLockContainer(
                margin: EdgeInsets.only(top: context.settingsButtonStyleLockMargin()),
                width: context.settingsButtonStyleLockWidth(),
                height: context.settingsButtonStyleLockHeight(),
                point: "$buttonStyleLockPoint",
                feature: "button_style",
                requiredPoint: buttonStyleLockPoint,
              ),
            ]
          ):
          /// Glass panel toggle section
          settings.settingsGlassToggleWidget(onChanged: changeGlassStyle),

          /// Button shape selection section with lock overlay
          (showSettingNumber.value == 2) ? Stack(alignment: Alignment.topCenter,
            children: [
              settings.settingsButtonShapeWidget(onTap: changeButtonShape),
              /// Lock overlay for premium features
              if (settings.isLocked(buttonShapeLockPoint)) settings.settingsLockContainer(
                width: context.settingsButtonShapeLockWidth(),
                height: context.settingsButtonShapeLockHeight(),
                margin: EdgeInsets.only(top: context.settingsButtonShapeLockMarginTop()),
                point: "$buttonShapeLockPoint",
                feature: "button_shape",
                requiredPoint: buttonShapeLockPoint,
              ),
            ]
          ):
          /// Background selection section with lock overlay
          (showSettingNumber.value == 3) ? Stack(alignment: Alignment.topCenter,
            children: [
              settings.settingsBackgroundSelectWidget(onTap: changeBackground),
              /// Lock overlay for premium features
              if (settings.isLocked(backgroundLockPoint)) settings.settingsLockContainer(
                width: context.settingsBackgroundLockWidth(),
                height: context.settingsBackgroundLockHeight(),
                margin: EdgeInsets.only(top: context.settingsBackgroundLockMargin()),
                point: "$backgroundLockPoint",
                feature: "background",
                requiredPoint: backgroundLockPoint,
              ),
            ]
          ): SizedBox(),
          /// AdMob banner space reservation
          if (!isPremium) Container(
            height: context.admobHeight(),
            color: blackColor,
          )
        ]),
        /// AdMob banner at bottom of screen
        if (!isTest) const AdBannerWidget(),
        /// Loading indicator during data initialization
        if (isLoadingData.value) common.commonCircularProgressIndicator(),
      ])
    );
  }
}

// ===== SettingsWidget: dialogs, selection widgets, lock overlays and navigation =====

class SettingsWidget {
  final BuildContext context;
  final int point;
  final List<String> roomImages;
  final List<int> floorNumbers;
  final List<bool> floorStops;
  final int buttonStyle;
  final String buttonShape;
  final String glassStyle;
  final String backgroundStyle;
  final bool isPremium;
  final void Function(String, int) onLockTap;

  SettingsWidget(this.context, {
    required this.point,
    required this.roomImages,
    required this.floorNumbers,
    required this.floorStops,
    required this.buttonStyle,
    required this.buttonShape,
    required this.glassStyle,
    required this.backgroundStyle,
    required this.isPremium,
    required this.onLockTap,
  });

  /// Whether a feature is still locked for this user
  /// Premium unlocks everything without changing the EV mile balance
  bool isLocked(int requiredPoint) => !isPremium && point < requiredPoint && !isTest;

  /// --- Common UI Components ---
  // Create divider with consistent styling
  Divider settingsDivider() => Divider(
    height: context.settingsDividerHeight(),
    thickness: context.settingsDividerThickness(),
    color: blackColor,
  );

  // Create lock overlay container for premium features
  // Displays lock icon and required points, and offers the unlock on tap
  Widget settingsLockContainer({
    required double width,
    required double height,
    required EdgeInsets margin,
    required point,
    required String feature,
    required int requiredPoint,
  }) => GestureDetector(
    onTap: () => onLockTap(feature, requiredPoint),
    child: Container(
    alignment: Alignment.center,
    color: transpBlackColor,
    width: width,
    height: height,
    margin: margin,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: context.settingsLockMargin()),
        Icon(CupertinoIcons.lock_fill,
          color: lampColor,
          size: context.settingsLockIconSize(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(pointImage,
              height: context.settingsLockIconSize()
            ),
            SizedBox(width: context.settingsLockMargin()),
            Text(point,
              style: TextStyle(
                color: lampColor,
                fontSize: context.settingsLockFontSize(),
                fontWeight: FontWeight.normal,
                fontFamily: numberFont[0],
              ),
            ),
          ],
        ),
      ],
    ),
    ),
  );

  /// Create alert dialog title with close button
  Widget alertDialogTitle(String title) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      // Scaled down rather than clipped: the basement title is long in some languages
      Flexible(child: FittedBox(fit: BoxFit.scaleDown,
        child: Text(title,
          maxLines: 1,
          style: TextStyle(
            fontSize: context.settingsAlertTitleFontSize(),
            fontFamily: context.font(),
            color: whiteColor,
          ),
        ),
      )),
      SizedBox(width: context.settingsAlertCloseIconSpace()),
      /// Close button for dialog dismissal
      GestureDetector(
        onTap: () => context.popPage(),
        child: Icon(Icons.close,
          size: context.settingsAlertCloseIconSize(),
          color: whiteColor,
        ),
      ),
    ]
  );

  // --- App Bar Components ---
  // Navigation and header elements

  /// Create settings app bar with animated back button
  AppBar settingsAppBar({
    required AnimationController animation,
    required void Function() onPressed,
  }) => AppBar(
    toolbarHeight: context.settingsAppBarHeight(),
    backgroundColor: blackColor,
    centerTitle: true,
    shadowColor: darkBlackColor,
    iconTheme: IconThemeData(color: whiteColor),
    title: Text(context.settings(),
      style: TextStyle(
        color: whiteColor,
        fontSize: context.settingsAppBarFontSize(),
        fontFamily: context.font(),
      ),
    ),
    leading: FadeTransition(
      opacity: animation,
      child: Container(
        margin: EdgeInsets.only(left: context.settingsAppBarBackButtonMargin()),
        child: IconButton(
          iconSize: context.settingsAppBarBackButtonSize(),
          icon: Icon(CupertinoIcons.arrow_left_circle_fill),
          onPressed: onPressed,
        ),
      ),
    ),
    // No purchase action here on purpose: a bare padlock in the bar reads as a
    // status, the same "blocked" glyph the overlays use. The only offer on this
    // screen is the lock overlay itself, which is what the user just tapped
  );

  // --- Settings Tab Components ---
  // UI components for settings tab selection

  /// Create settings tab selection button
  Widget selectButtonWidget({
    required String image,
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: context.settingsSelectButtonSize(),
      height: context.settingsSelectButtonSize(),
      margin: EdgeInsets.only(
        top: context.settingsSelectButtonMarginTop(),
        bottom: context.settingsSelectButtonMarginBottom(),
      ),
      child: Image.asset(image),
    ),
  );

  // --- Floor Image Customization Components ---
  // UI components for floor image selection and management

  /// Create floor image selection grid with lock overlays
  /// Displays room images with selection states and point-based locks
  Widget settingsFloorImageWidget({
    required List<List<bool>> isImageOn,
    required void Function(int, int) onTap,
  }) => Column(children: [
    ...roomImages.roomsList().asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          width: context.settingsFloorImageLockWidth(),
          height: context.settingsFloorImageLockHeight(),
          margin: EdgeInsets.only(
            top: row.key == 0 ? context.settingsFloorImageMargin() : 0,
            bottom: context.settingsFloorImageMargin(),
          ),
          child: Stack(alignment: Alignment.center,
            children: [
              /// Room image with selection overlay
              GestureDetector(
                onTap: () => onTap(row.key, col.key),
                child: SizedBox(
                  width: context.settingsFloorImageWidth(),
                  height: context.settingsFloorImageHeight(),
                  child: Stack(children: [
                    roomImages.roomsList()[row.key][col.key].roomImage(),
                    if (isImageOn[row.key][col.key] && !isLocked(changePointList[row.key][col.key])) Container(color: transpLampColor),
                  ]),
                ),
              ),
              /// Lock overlay for premium features
              if (isLocked(changePointList[row.key][col.key])) settingsLockContainer(
                width: context.settingsFloorImageLockWidth(),
                height: context.settingsFloorImageLockHeight(),
                margin: EdgeInsets.zero,
                point: "${changePointList[row.key][col.key]}",
                feature: "floor_image",
                requiredPoint: changePointList[row.key][col.key],
              )
            ],
          )
        )).toList()
      ),
    ),
  ]);

  /// Create scroll to top button with animation
  Widget scroolUpButton({
    required AnimationController animation,
    required void Function() onTap,
  }) => Container(
    alignment: Alignment.topCenter,
    margin: EdgeInsets.only(top: context.settingsArrowMarginTop()),
    child: GestureDetector(
      onTap: onTap,
      child: CommonWidget(context).flashButton(
        animationController: animation,
        isUp: true,
      )
    ),
  );

  /// Open floor image picker dialog with dropdown and photo selection
  void floorImagePickerDialog(int row, col, {
    required void Function(String?, int, int) onChanged,
    required void Function(int, int) onChangedMyPhoto,
    required void Function(int, int) then,
  }) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: transpBlackColor,
      title: alertDialogTitle(context.changeImage()),
      content: SizedBox(
        height: context.settingsAlertImageSelectHeight(),
        child: Column(children: [
          floorImageDropdownList(row, col, onChanged: onChanged),
          const Spacer(flex: 1),
          Stack(children: [
            floorImageFromMyAlbumButton(onTap: () => onChangedMyPhoto(row, col)),
            /// Lock overlay for photo selection feature
            if (isLocked(albumImagePoint)) GestureDetector(
              onTap: () => onLockTap("album_photo", albumImagePoint),
              child: alertLockWidget(),
            ),
          ]),
          const Spacer(flex: 1),
        ]),
      ),
    )
  ).then((_) => then(row, col));

  /// Create dropdown list for preset floor images
  Widget floorImageDropdownList(int row, col, {
    required void Function(String?, int, int) onChanged,
  }) => Container(
    margin: EdgeInsets.all(context.settingsAlertDropdownMargin()),
    child: DropdownButton<String>(
      value: floorImageList.selectedRoomImage(roomImages, buttonIndex(row, col)),
      onChanged: (String? newValue) => onChanged(newValue, row, col),
      items: floorImageList.remainIterable(roomImages, buttonIndex(row, col)).map((image) =>
        DropdownMenuItem<String>(
          value: image,
          child: Text(floorImageList.roomName(context, image),
            style: TextStyle(
              fontSize: context.settingsAlertFontSize(),
              fontFamily: context.font(),
              color: whiteColor,
            ),
          ),
        )
      ).toList(),
      dropdownColor: transpBlackColor,
    ),
  );

  /// Create button for selecting photos from user's album
  Widget floorImageFromMyAlbumButton({
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.all(context.settingsAlertLockSpaceSize()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined,
            color: whiteColor,
            size: context.settingsAlertIconSize(),
            semanticLabel: context.selectPhoto(),
          ),
          SizedBox(width: context.settingsAlertIconMargin()),
          Text(context.selectPhoto(),
            style: TextStyle(
              color: whiteColor,
              fontSize: context.settingsAlertFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ]
      ),
    ),
  );

  /// Create lock overlay for photo selection feature
  Container alertLockWidget()  => Container(
    decoration: BoxDecoration(
      color: transpBlackColor,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(context.settingsAlertLockBorderRadius()),
      border: Border.all(
        color: whiteColor,
        width: context.settingsAlertLockBorderWidth(),
      ),
    ),
    child: Column(children: [
      SizedBox(height: context.settingsAlertLockIconSize() + context.settingsAlertLockSpaceSize()),
      Row(children: [
        const Spacer(flex: 1),
        Icon(CupertinoIcons.lock_fill,
          color: lampColor,
          size: context.settingsAlertLockIconSize()
        ),
        SizedBox(width: context.settingsAlertLockSpaceSize()),
        Image.asset(pointImage,
          height: context.settingsAlertLockIconSize()
        ),
        SizedBox(width: context.settingsLockMargin()),
        Text("$albumImagePoint",
          style: TextStyle(
            color: lampColor,
            fontSize: context.settingsAlertLockFontSize(),
            fontWeight: FontWeight.normal,
            fontFamily: numberFont[0],
          ),
        ),
        const Spacer(flex: 1),
      ]),
    ]),
  );

  // --- Button Style Components ---
  // UI components for button style selection

  /// Create button style selection grid
  Widget settingsButtonStyleWidget({
    required void Function(int) onTap,
  }) => Column(children: [
    ...List.generate(3, (row) => GestureDetector(
      onTap: () => onTap(row),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (col) => Container(
          width: context.settingsButtonStyleSize(),
          height: context.settingsButtonStyleSize(),
          margin: EdgeInsets.only(
            top: (row == 0) ? context.settingsButtonStyleMargin() : 0,
            bottom: context.settingsButtonStyleMargin(),
          ),
          child: Image.asset(
            List.filled(3, row == buttonStyle).operationButtonImage(row)[col],
          ),
        )),
      )
    )),
    settingsDivider(),
  ]);

  // --- Button Shape Components ---
  // UI components for button shape selection

  /// Create button shape selection grid with preview
  Widget settingsButtonShapeWidget({
    required void Function(String) onTap,
  }) => Column(children: [
    ...buttonShapeList.toMatrix(numberButtonColumnCount).asMap().entries.map((row) =>
      Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.value.asMap().entries.map((col) => Container(
            alignment: Alignment.center,
            width: context.settingsButtonShapeSize(),
            height: context.settingsButtonShapeSize(),
            margin: EdgeInsets.only(
              top: (row.key == 0) ? context.settingsButtonShapeMarginTop(): 0,
              bottom: context.settingsButtonShapeMarginBottom()
            ),
            child: Stack(alignment: Alignment.center,
              children: [
                /// Button shape preview with number display
                GestureDetector(
                  onTap: () => onTap(row.value[col.key]),
                  child: Stack(alignment: Alignment.center,
                    children: [
                      if (buttonShapeList[numberButtonColumnCount * row.key + col.key] != "") Image.asset((buttonShape == row.value[col.key]).numberBackground(buttonStyle, row.value[col.key]),),
                      Container(
                        margin: EdgeInsets.only(
                          top: context.floorButtonNumberMarginTop(numberButtonColumnCount * row.key + col.key) * 2,
                          bottom: context.floorButtonNumberMarginBottom(numberButtonColumnCount * row.key + col.key) * 2,
                        ),
                        child: Text("99",
                          style: TextStyle(
                            color: (buttonStyle != 0) ? blackColor:
                            buttonShape != buttonShapeList[numberButtonColumnCount * row.key + col.key] ? whiteColor:
                            numberColorList[numberButtonColumnCount * row.key + col.key],
                            fontSize: context.settingsButtonShapeFontSize(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ),
          ),
        ).toList()),
      ]),
    ),
  ]);

  /// --- Floor Number Configuration Components ---
  // Create floor number configuration grid with stop toggles
  Widget settingsFloorNumberWidget({
    required List<List<bool>> isButtonOn,
    required void Function(int, int) changeButtonNumber,
    required void Function(bool, int, int) changeFloorStopFlag,
  }) => Column(children: [
    ...floorNumbers.toReversedMatrix(2).asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: context.settingsButtonNumberMargin()),
          child: Stack(alignment: Alignment.center,
            children: [
              SizedBox(
                width: context.settingsButtonNumberLockWidth(),
                height: context.settingsButtonNumberLockHeight(),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  // 1F never moves and always stops. Fade the button and the
                  // switch; the plate that used to cover the cell hid the floor
                  // number too, and the Stop label stays readable
                  Opacity(
                    opacity: isNotSelectFloor(row.key, col.key) ? fixedFloorOpacity : 1.0,
                    child: GestureDetector(
                      child: settingsFloorButtonImage(
                        image: isButtonOn[row.key][col.key].numberBackground(1, "normal"),
                        number: col.value.buttonNumber()
                      ),
                      onTap: () => changeButtonNumber(row.key, col.key) ,
                    ),
                  ),
                  settingsFloorStopToggleWidget(row.key, col.key, changeFloorStopFlag: changeFloorStopFlag)
                ]),
              ),
              /// Lock overlay for premium features. The top and the bottom used
              /// to be exempt because they could not be changed at all; they can
              /// now, so they cost what the table always said they would
              if (isLocked(changePointList[row.key][col.key])) settingsLockContainer(
                width: context.settingsButtonNumberLockWidth(),
                height: context.settingsButtonNumberLockHeight(),
                margin: EdgeInsets.zero,
                point: "${changePointList[row.key][col.key]}",
                feature: "floor_number",
                requiredPoint: changePointList[row.key][col.key],
              ),
            ])
          )).toList()
      )
    ),
  ]);

  // Create floor button image with number display
  Widget settingsFloorButtonImage({
    required String number,
    required String image,
  }) => SizedBox(
    width: context.settingsButtonSize(),
    height: context.settingsButtonSize(),
    child: Stack(alignment: Alignment.center,
      children: [
        Image.asset(image),
        SizedBox(
          child: Text(number,
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsButtonNumberFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
      ],
    ),
  );

  // Open floor number selection dialog with picker
  void floorNumberSelectDialog(int row, col, {
    required void Function(int) select,
    required void Function() ok,
    required void Function() then,
  }) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: transpBlackColor,
      title: alertDialogTitle(context.changeNumberTitle(isBasement(row, col))),
      content: settingsFloorNumberContent(row, col, onSelectedItemChanged: select,),
      actions: [
        TextButton(
          onPressed: () => context.popPage(),
          child: Text(context.cancel(),
            style: TextStyle(
              color: whiteColor,
              fontSize: context.settingsAlertDescFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
        TextButton(
          onPressed: ok,
          child: Text(context.ok(),
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        )
      ]
    ),
  ).then((_) => then());

  // Create floor number picker content with scrollable list
  Widget settingsFloorNumberContent(int row, col, {
    required void Function(int) onSelectedItemChanged,
  }) => Container(
    alignment: Alignment.center,
    height: context.settingsAlertFloorNumberPickerHeight(),
    child: CupertinoPicker(
      itemExtent: context.settingsAlertFloorNumberHeight(),
      scrollController: FixedExtentScrollController(
        initialItem: floorNumbers[reversedButtonIndex[row][col]] - floorNumbers.selectFirstFloor(row, col),
      ),
      onSelectedItemChanged: (int index) => onSelectedItemChanged(index),
      // No filtering here: the range never contains floor 0, so dropping an item
      // would only make the index disagree with the value it reports
      children: List.generate(floorNumbers.selectDiffFloor(row, col), (int index) =>
        Container(
          alignment: Alignment.center,
          child: Text('${floorNumbers.selectedFloor(index, row, col).abs()}',
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertFloorNumberFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont[1],
            ),
          )
        )
      ),
    ),
  );

  // Create floor stop toggle widget with switch control
  Widget settingsFloorStopToggleWidget(int row, col, {
    required void Function(bool, int, int) changeFloorStopFlag,
  }) => Container(
    margin: EdgeInsets.only(top: context.settingsFloorStopMargin()),
    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(floorStops[reversedButtonIndex[row][col]] ? context.stop(): context.bypass(),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.settingsFloorStopFontSize(),
            fontFamily: context.font(),
          ),
        ),
        // Only the switch is faded for 1F. The Stop label above it stays legible
        Opacity(
          opacity: isNotSelectFloor(row, col) ? fixedFloorSwitchOpacity : 1.0,
          child: Transform.scale(
            scale: context.settingsFloorStopToggleScale(),
            child: CupertinoSwitch(
              activeTrackColor: lampColor,
              inactiveTrackColor: blackColor,
              thumbColor: whiteColor,
              value: floorStops[reversedButtonIndex[row][col]],
              // The last stop on its side of 1F stays on, so the switch is disabled
              onChanged: (isNotSelectFloor(row, col)
                  || isOnlyStop(floorStops, reversedButtonIndex[row][col]))
                ? null
                : (value) => changeFloorStopFlag(value, row, col),
            ),
          ),
        ),
      ]
    ),
  );

  /// --- Background and Glass Components ---
  // Create background selection grid with preview
  Widget settingsBackgroundSelectWidget({
    required void Function(String) onTap
  }) => Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [...backgroundStyleList.toMatrix(2).asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          width: context.settingsBackgroundWidth(),
          height: context.settingsBackgroundHeight(),
          margin: EdgeInsets.only(top: context.settingsBackgroundMargin()),
          child: Stack(children: [
            GestureDetector(
              onTap: () => onTap(row.value[col.key]),
              child: Image.asset(row.value[col.key].backGroundImage(glassStyle)),
            ),
            /// Selection indicator for current background
            if (backgroundStyleList.toMatrix(2)[row.key][col.key] == backgroundStyle) Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: context.settingsBackgroundSelectBorderWidth(),
                  color: lampColor
                ),
              ),
            ),
          ]),
        )).toList(),
      )),
    ]
  );

  // Create glass panel toggle with switch control
  Widget settingsGlassToggleWidget({
    required void Function(bool) onChanged,
  }) => Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(context.glass(),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.settingsGlassFontSize(),
            fontFamily: context.font(),
            shadows: [
              Shadow(
                color: blackColor,
                offset: Offset(context.settingsGlassShadowShift(), context.settingsGlassShadowShift()),
              ),
            ]
          ),
        ),
        CupertinoSwitch(
          activeTrackColor: lampColor,
          inactiveTrackColor: blackColor,
          thumbColor: whiteColor,
          value: glassStyle == "use",
          onChanged: (value) => onChanged(value),
        ),
      ],
    ),
    settingsDivider(),
  ]);
}