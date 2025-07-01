import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevatorneo/games_manager.dart';
import 'package:letselevatorneo/homepage.dart';
import 'package:vibration/vibration.dart';
import 'admob_banner.dart';
import 'common_widget.dart';
import 'image_manager.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final roomImages = ref.watch(floorImagesProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isConnectedInternet = ref.watch(internetProvider);
    final point = ref.watch(pointProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);
    final glassStyle = ref.watch(glassStyleProvider);

    final scrollController = useScrollController();
    final imageManager = useMemoized(() => ImageManager());
    final photoManager = useMemoized(() => PhotoManager(context: context));
    final isButtonOn = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final isImageOn  = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final selectedNumber = useState(0);
    final showSettingNumber = useState(0);
    final hasScrolledOnce = useState(false);
    final isLoadingData = useState(false);
    final animationController = useAnimationController(duration:Duration(seconds: flashTime))..repeat(reverse: true);

    //Class
    final common = CommonWidget(context);
    final settings = SettingsWidget(context,
      point: point,
      roomImages: roomImages,
      floorNumbers: floorNumbers,
      floorStops: floorStops,
      buttonStyle: buttonStyle,
      buttonShape: buttonShape,
      backgroundStyle: backgroundStyle,
      glassStyle: glassStyle,
    );
    final gamesManager = useMemoized(() => GamesManager(
      isGamesSignIn: isGamesSignIn,
      isConnectedInternet: isConnectedInternet
    ));

    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(internetProvider.notifier).state = await gamesManager.checkInternetConnection();
        ref.read(gamesSignInProvider.notifier).state = await gamesManager.gamesSignIn();
        ref.read(pointProvider.notifier).state = await gamesManager.getBestScore();
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
      });
      // Control scroll position
      void listener() {
        if (scrollController.offset > 10) hasScrolledOnce.value = true;
      }
      scrollController.addListener(listener);
      return () {
        scrollController.removeListener(listener);
      };
    }, []);

    void scrollToTop() {
      scrollController.animateTo(0.0,
        duration: Duration(seconds: flashTime),
        curve: Curves.easeOut,
      );
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isGamesSignIn) gamesManager.gamesSignIn();
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
        hasScrolledOnce.value = false;
      });
      return null;
    }, [showSettingNumber.value]);


    ///Change select button
    void changeSelectButton(int i) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      showSettingNumber.value = i;
    }

    ///Change floor image
    void openChangeImageDialog(int row, col) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      isImageOn.value[row][col] = true;
      isImageOn.value = List.from(isImageOn.value);
      settings.floorImagePickerDialog(row, col,
        onChanged: (String? newValue, int row, int col) async {
          if (newValue != null) {
            Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
            ref.read(floorImagesProvider.notifier).state = await imageManager.saveImagePath(
              currentList: roomImages,
              newIndex: buttonIndex(row, col),
              newValue: newValue
            );
          }
          if (context.mounted) context.popPage();
        },
        onChangedMyPhoto: (row, col) async {
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          ref.read(floorImagesProvider.notifier).state = await photoManager.selectMyPhoto(
            row: row,
            col: col,
            currentList: roomImages
          );
          if (context.mounted) context.popPage();
        },
        then: (row, col) {
          isImageOn.value[row][col] = false;
          isImageOn.value = List.from(isImageOn.value);
        },
      );
    }

    ///Change button number
    void changeButtonNumber(int row, col) {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        isButtonOn.value[row][col] = true;
        isButtonOn.value = List.from(isButtonOn.value);
        settings.floorNumberSelectDialog(row, col,
          select: (int index) {
            selectedNumber.value = floorNumbers.selectedFloor(index, row, col);
            "Select number: ${selectedNumber.value}".debugPrint();
          },
          ok: () async {
            Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
            ref.read(floorNumbersProvider.notifier).state = await imageManager.saveFloorNumber(
              currentList: floorNumbers,
              newIndex: reversedButtonIndex[row][col],
              newValue: selectedNumber.value
            );
            if (context.mounted) context.popPage();
          },
          then: () async {
            isButtonOn.value[row][col] = false;
            isButtonOn.value = List.from(isButtonOn.value);
          }
        );
      }
    }

    ///Change stop floor
    Future<void> changeFloorStop(bool value, int row, col) async {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        ref.read(floorStopsProvider.notifier).state = await imageManager.saveFloorStops(
          currentList: floorStops,
          newIndex: reversedButtonIndex[row][col],
          newValue: value
        );
      }
    }

    ///Change button style
    Future<void> changeButtonStyle(int value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(buttonStyleProvider.notifier).state = await imageManager.changeSettingsIntValue(
        key: "buttonStyleKey",
        current: buttonStyle,
        next: value
      );
    }

    ///Change button shape
    Future<void> changeButtonShape(String value) async {
      ref.read(buttonShapeProvider.notifier).state = await imageManager.changeSettingsStringValue(
        key: "buttonShapeKey",
        current: buttonShape,
        next: value,
      );
    }

    ///Change glass style
    Future<void> changeGlassStyle(bool value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(glassStyleProvider.notifier).state = await imageManager.changeSettingsStringValue(
        key: "glassStyleKey",
        current: glassStyle,
        next: value ? "use": "non"
      );
    }

    ///Change background style
    Future<void> changeBackground(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(backgroundStyleProvider.notifier).state = await imageManager.changeSettingsStringValue(
        key: "backgroundStyleKey",
        current: backgroundStyle,
        next: value
      );
    }

    Future<void> pressedBack() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).state = false;
      ref.read(isMenuProvider.notifier).state = false;
      if (context.mounted) context.pushFadeReplacement(HomePage());
    }

    ///Settings
    return Scaffold(
      appBar: settings.settingsAppBar(
        animation: animationController,
        onPressed: () => pressedBack(),
      ),
      body: Stack(children: [
        common.commonBackground(menuBackGroundImage),
        Column(children: [
          ///Select button
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(settingsItemList.length, (i) =>
              settings.selectButtonWidget(
                image: showSettingNumber.value.settingsButton(i),
                onTap: () => changeSelectButton(i)
              )
            ),
          ),
          settings.settingsDivider(),
          ///Setting floor image
          (showSettingNumber.value == 0) ? Expanded(
            child: Stack(children: [
              SingleChildScrollView(
                controller: scrollController,
                child: settings.settingsFloorImageWidget(
                  isImageOn: isImageOn.value,
                  onTap: openChangeImageDialog
                )
              ),
              if (!hasScrolledOnce.value) settings.scroolUpButton(
                animation: animationController,
                onTap: scrollToTop
              ),
            ])
          ):
          ///Setting floor number
          (showSettingNumber.value == 1) ? settings.settingsFloorNumberWidget(
            isButtonOn: isButtonOn.value,
            changeButtonNumber: changeButtonNumber,
            changeFloorStopFlag: changeFloorStop,
          ):
          ///Setting button style
          (showSettingNumber.value == 2) ? Stack(alignment: Alignment.center,
            children: [
              settings.settingsButtonStyleWidget(onTap: changeButtonStyle),
              if (point < buttonStyleLockPoint && !isTest) settings.settingsLockContainer(
                margin: EdgeInsets.only(top: context.settingsButtonStyleLockMargin()),
                width: context.settingsButtonStyleLockWidth(),
                height: context.settingsButtonStyleLockHeight(),
                point: "$buttonStyleLockPoint"
              ),
            ]
          ):
          ///Setting vision panel
          settings.settingsGlassToggleWidget(onChanged: changeGlassStyle),

          ///Setting button shape
          (showSettingNumber.value == 2) ? Stack(alignment: Alignment.topCenter,
            children: [
              settings.settingsButtonShapeWidget(onTap: changeButtonShape),
              if (point < buttonShapeLockPoint && !isTest) settings.settingsLockContainer(
                width: context.settingsButtonShapeLockWidth(),
                height: context.settingsButtonShapeLockHeight(),
                margin: EdgeInsets.only(top: context.settingsButtonShapeLockMarginTop()),
                point: "$buttonShapeLockPoint",
              ),
            ]
          ):
          ///Setting background image
          (showSettingNumber.value == 3) ? Stack(alignment: Alignment.topCenter,
            children: [
              settings.settingsBackgroundSelectWidget(onTap: changeBackground),
              if (point < backgroundLockPoint && !isTest) settings.settingsLockContainer(
                width: context.settingsBackgroundLockWidth(),
                height: context.settingsBackgroundLockHeight(),
                margin: EdgeInsets.only(top: context.settingsBackgroundLockMargin()),
                point: "$backgroundLockPoint",
              ),
            ]
          ): SizedBox(),
          ///Admob banner space
          Container(
            height: context.admobHeight(),
            color: blackColor,
          )
        ]),
        ///Admob banner
        if (!isTest) const AdBannerWidget(),
        ///Progress Indicator
        if (isLoadingData.value) common.commonCircularProgressIndicator(),
      ])
    );
  }
}

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

  SettingsWidget(this.context, {
    required this.point,
    required this.roomImages,
    required this.floorNumbers,
    required this.floorStops,
    required this.buttonStyle,
    required this.buttonShape,
    required this.glassStyle,
    required this.backgroundStyle,
  });

  ///Common widget
  //Divider
  Divider settingsDivider() => Divider(
    height: context.settingsDividerHeight(),
    thickness: context.settingsDividerThickness(),
    color: blackColor,
  );

  //Lock container
  Widget settingsLockContainer({
    required double width,
    required double height,
    required EdgeInsets margin,
    required point,
  }) => Container(
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
  );

  //Alert dialog
  Widget alertDialogTitle(String title) => Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Text(title,
        style: TextStyle(
          fontSize: context.settingsAlertTitleFontSize(),
          fontFamily: context.normalFont(),
          color: whiteColor,
        ),
      ),
      SizedBox(width: context.settingsAlertCloseIconSpace()),
      ///Close button
      GestureDetector(
        onTap: () => context.popPage(),
        child: Icon(Icons.close,
          size: context.settingsAlertCloseIconSize(),
          color: whiteColor,
        ),
      ),
    ]
  );

  ///AppBar
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
        fontFamily: context.elevatorFont(),
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
  );

  ///Select button
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

  ///Change floor image
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
              /// Room Image
              GestureDetector(
                onTap: () => onTap(row.key, col.key),
                child: SizedBox(
                  width: context.settingsFloorImageWidth(),
                  height: context.settingsFloorImageHeight(),
                  child: Stack(children: [
                    roomImages.roomsList()[row.key][col.key].roomImage(),
                    if (isImageOn[row.key][col.key] && point >= changePointList[row.key][col.key]) Container(color: transpLampColor),
                  ]),
                ),
              ),
              /// Lock Overlay
              if (point < changePointList[row.key][col.key] && !isTest) settingsLockContainer(
                width: context.settingsFloorImageLockWidth(),
                height: context.settingsFloorImageLockHeight(),
                margin: EdgeInsets.zero,
                point: "${changePointList[row.key][col.key]}",
              )
            ],
          )
        )).toList()
      ),
    ),
  ]);

  //Scroll up button
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
        isUp: false,
      )
    ),
  );

  //Image picker dialog for changing floor Image
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
            if (point < albumImagePoint && !isTest) alertLockWidget(),
          ]),
          const Spacer(flex: 1),
        ]),
      ),
    )
  ).then((_) => then(row, col));

  //Change floor image by dropdown list
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
              fontFamily: context.normalFont(),
              color: whiteColor,
            ),
          ),
        )
      ).toList(),
      dropdownColor: transpBlackColor,
    ),
  );

  //Change floor image from my album
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
              fontFamily: context.normalFont(),
            ),
          ),
        ]
      ),
    ),
  );

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



  ///Change button style
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

  ///Change button shape
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
                /// Number Button
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

  ///Change floor number
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
                  GestureDetector(
                    child: settingsFloorButtonImage(
                      image: isButtonOn[row.key][col.key].numberBackground(1, "normal"),
                      number: col.value.buttonNumber()
                    ),
                    onTap: () => changeButtonNumber(row.key, col.key) ,
                  ),
                  settingsFloorStopToggleWidget(row.key, col.key, changeFloorStopFlag: changeFloorStopFlag)
                ]),
              ),
              if (isNotSelectFloor(row.key, col.key)) Container(
                width: context.settingsButtonNumberHideWidth(),
                height: context.settingsButtonNumberHideHeight(),
                margin: EdgeInsets.only(right: context.settingsButtonNumberHideMargin()),
                color: transpBlackColor,
              ),
              /// Lock Overlay
              if (point < changePointList[row.key][col.key] && !isTest && col.value != max && col.value != min) settingsLockContainer(
                width: context.settingsButtonNumberLockWidth(),
                height: context.settingsButtonNumberLockHeight(),
                margin: EdgeInsets.zero,
                point: "${changePointList[row.key][col.key]}",
              ),
            ])
          )).toList()
      )
    ),
  ]);

  ///Floor Button Image
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
              fontFamily: context.normalFont(),
            ),
          ),
        ),
      ],
    ),
  );


  //Number picker dialog for changing floor number
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
              fontFamily: context.normalFont(),
            ),
          ),
        ),
        TextButton(
          onPressed: ok,
          child: Text(context.ok(),
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertSelectFontSize(),
              fontFamily: context.normalFont(),
            ),
          ),
        )
      ]
    ),
  ).then((_) => then());

  //Number picker content
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
      children: List.generate(floorNumbers.selectDiffFloor(row, col), (int index) =>
        (floorNumbers.selectedFloor(index, row, col) != 0) ? Container(
          alignment: Alignment.center,
          child: Text('${(floorNumbers.selectedFloor(index, row, col) < 0 ? -1: 1) * floorNumbers.selectedFloor(index, row, col)}',
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertFloorNumberFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont[1],
            ),
          )
        ): null
      ).whereType<Container>().toList(),
    ),
  );

  ///Change stop floor
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
            fontFamily: context.normalFont(),
          ),
        ),
        Transform.scale(
          scale: context.settingsFloorStopToggleScale(),
          child: CupertinoSwitch(
            activeTrackColor: lampColor,
            inactiveTrackColor: blackColor,
            thumbColor: whiteColor,
            value: floorStops[reversedButtonIndex[row][col]],
            onChanged: (value) => changeFloorStopFlag(value, row, col),
          ),
        ),
      ]
    ),
  );

  ///Change background
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

  //Change vision panel
  Widget settingsGlassToggleWidget({
    required void Function(bool) onChanged,
  }) => Column(children: [
    SizedBox(height: context.settingsGlassToggleMarginTop()),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(context.glass(),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.settingsGlassFontSize(),
            fontFamily: context.elevatorFont(),
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
    SizedBox(height: context.settingsGlassToggleMarginBottom()),
    settingsDivider(),
  ]);
}