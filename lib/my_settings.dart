import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'admob_banner.dart';
import 'common_widget.dart';
import 'image_manager.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';

class MySettingsPage extends HookConsumerWidget {
  const MySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final floorNumbers = ref.watch(floorNumbersProvider);
    final roomImages = ref.watch(roomImagesProvider);
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
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final prefs = await SharedPreferences.getInstance();
        ref.read(buttonShapeProvider.notifier).state = "numberButtonKey".getSharedPrefString(prefs, initialButtonShape);
        ref.read(buttonStyleProvider.notifier).state = "operationButtonKey".getSharedPrefInt(prefs, initialButtonStyle);
        ref.read(backgroundStyleProvider.notifier).state = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
        ref.read(glassStyleProvider.notifier).state = "glassStyleKey".getSharedPrefString(prefs, initialGlassStyle);
      });
      return null;
    }, []);

    // スクロール位置を監視
    useEffect(() {
      void listener() {
        if (scrollController.offset > 10) hasScrolledOnce.value = true;
      }
      scrollController.addListener(listener);
      return () {
        scrollController.removeListener(listener);
      };
    }, []);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
        hasScrolledOnce.value = false;
      });
      return null;
    }, [showSettingNumber.value]);

    roomPickerDialog(int row, int col) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: transpBlackColor,
        title: Row(children: [
          const Spacer(),
          Text(context.changeImage(),
            style: TextStyle(
              fontSize: context.settingsAlertTitleFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: settingsFont,
              color: whiteColor,
            ),
          ),
          const Spacer(),
          ///Close button
          shutButton(context),
        ]),
        content: SizedBox(
          height: context.settingsAlertImageSelectHeight(),
          child: Column(children: [
            Container(
              margin: EdgeInsets.all(context.settingsAlertDropdownMargin()),
              child: DropdownButton<String>(
                value: roomImageList.selectedRoomImage(roomImages, buttonIndex(row, col)),
                onChanged: (String? newValue) async {
                  ref.read(roomImagesProvider.notifier).state = await imageManager.saveImagePath(
                    currentList: roomImages,
                    newIndex: buttonIndex(row, col),
                    newValue: newValue
                  );
                  if (context.mounted) context.popPage();
                },
                items: roomImageList.remainIterable(roomImages, buttonIndex(row, col)).map((image) =>
                  DropdownMenuItem<String>(
                    value: image,
                    child: Text(roomImageList.roomName(context, image),
                      style: TextStyle(
                        fontSize: context.settingsAlertFontSize(),
                        fontFamily: settingsFont,
                        color: whiteColor,
                      ),
                    ),
                  )
                ).toList(),
                dropdownColor: transpBlackColor,
              ),
            ),
            const Spacer(flex: 1),
            Stack(children: [
              GestureDetector(
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
                          fontFamily: settingsFont,
                        ),
                      ),
                    ]
                  ),
                ),
                onTap: () async {
                  ref.read(roomImagesProvider.notifier).state = await photoManager.selectMyPhoto(row, col, roomImages);
                  if (context.mounted) context.popPage();
                }
              ),
              if (point < albumImagePoint) alertLockWidget(context),
            ]),
            const Spacer(flex: 1),
          ]),
        ),
      )
    ).then((_) {
      isImageOn.value[row][col] = false;
      isImageOn.value = List.from(isImageOn.value);
    });

    floorInputDialog(int row, int col) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: transpBlackColor,
        title: Text(context.changeNumberTitle(isBasement(row, col)),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.settingsAlertTitleFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: settingsFont,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          height: context.settingsAlertFloorNumberHeight(),
          child: CupertinoPicker(
            itemExtent: context.settingsAlertFloorNumberSize(),
            scrollController: FixedExtentScrollController(
              initialItem: isBasement(row, col).selectInitialIndex(floorNumbers,buttonIndex(row, col))
            ),
            onSelectedItemChanged: (int index) {
              selectedNumber.value = isBasement(row, col).selectedFloorNumber(index) + isBasement(row, col).selectFirstFloor(floorNumbers, buttonIndex(row, col)) - 1; // 選択された数字を更新
              "Select number: ${selectedNumber.value}".debugPrint();
            },
            children: List.generate(isBasement(row, col).selectDiffFloor(floorNumbers, buttonIndex(row, col)), (int index) =>
              Text('${index + isBasement(row, col).selectFirstFloor(floorNumbers, buttonIndex(row, col))}',
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.settingsAlertFloorNumberSize(),
                  fontWeight: FontWeight.normal,
                  fontFamily: numberFont,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Row(children: [
            const Spacer(flex: 2),
            TextButton(
              child: Text(context.cancel(),
                style: TextStyle(
                  color: whiteColor,
                  fontSize: context.settingsAlertSelectFontSize(),
                  fontFamily: settingsFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => context.popPage(),
            ),
            const Spacer(flex: 2),
            TextButton(
              child: Text(context.ok(),
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.settingsAlertSelectFontSize(),
                  fontFamily: settingsFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                ref.read(floorNumbersProvider.notifier).state = await imageManager.saveFloorNumber(
                  currentList: floorNumbers,
                  newIndex: buttonIndex(row, col),
                  newValue: selectedNumber.value
                );
                if (context.mounted) context.popPage();
              }
            ),
            const Spacer(flex: 1),
          ]),
        ]
      ),
    ).then((_) {
      isButtonOn.value[row][col] = false;
      isButtonOn.value = List.from(isButtonOn.value);
    });

    Widget selectButtonsWidget() => Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(settingsItemList.length, (i) =>
          GestureDetector(
            onTap: () => {
              Vibration.vibrate(duration: vibTime, amplitude: vibAmp),
              showSettingNumber.value = i
            },
            child: Container(
              width: context.settingsSelectButtonSize(),
              height: context.settingsSelectButtonSize(),
              margin: EdgeInsets.only(
                top: context.settingsSelectButtonMarginTop(),
                bottom: context.settingsSelectButtonMarginBottom()
              ),
              child: Image.asset(showSettingNumber.value.settingsButton(i)),
            ),
          ),
        ),
      ),
      myDivider(context),
    ]);

    Widget settingsFloorNumberWidget() => Column(children: [
      ...floorNumbers.floorNumbersList().asMap().entries.map((row) =>
        Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.value.asMap().entries.map((col) => Container(
              alignment: Alignment.center,
              width: context.settingsNumberLockWidth(),
              height: context.settingsNumberLockHeight(),
              margin: EdgeInsets.only(top: context.settingsNumberButtonMargin(),),
              child: Stack(alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Number Button
                      GestureDetector(
                        onTap: () {
                          if (point >= changePointList[row.key][col.key] && !isNotSelectFloor(row.key, col.key)) {
                            isButtonOn.value[row.key][col.key] = true;
                            isButtonOn.value = List.from(isButtonOn.value);
                            floorInputDialog(row.key, col.key);
                          }
                        },
                        child: Stack(alignment: Alignment.center,
                          children: [
                            Image.asset(isButtonOn.value[row.key][col.key].numberBackground(0, "circle"),
                              width: context.settingsNumberButtonSize(),
                              height: context.settingsNumberButtonSize(),
                            ),
                            Text(col.value.buttonNumber(),
                              style: TextStyle(
                                color: isButtonOn.value[row.key][col.key] ? lampColor: whiteColor,
                                fontSize: context.settingsNumberButtonFontSize(),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isNotSelectFloor(row.key, col.key)) Container(
                              width: context.settingsNumberButtonSize(),
                              height: context.settingsNumberButtonSize(),
                              color: transpBlackColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  /// Lock Overlay
                  if (point < changePointList[row.key][col.key]) Container(
                    alignment: Alignment.center,
                    color: transpBlackColor,
                    width: context.settingsNumberLockWidth(),
                    height: context.settingsNumberLockHeight(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: context.settingsLockMargin()),
                        lockIcon(context.settingsLockIconSize()),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            pointIcon(context.settingsLockIconSize()),
                            SizedBox(width: context.settingsLockMargin()),
                            Text(
                              "${changePointList[row.key][col.key]}",
                              style: TextStyle(
                                color: lampColor,
                                fontSize: context.settingsLockFontSize(),
                                fontWeight: FontWeight.normal,
                                fontFamily: numberFont,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ]),
      ),
    ]);

    Widget settingsFloorUpArrow() => Container(
      alignment: Alignment.topCenter,
      margin: EdgeInsets.only(top: context.settingsArrowMarginTop()),
      child: FadeTransition(
        opacity: animationController.drive(CurveTween(curve: Curves.easeInOut)),
        child: Container(
          width: context.settingsSelectButtonSize(),
          height: context.settingsSelectButtonSize(),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [transpBlackColor, transpColor],
              center: Alignment.center,
              radius: 0.8,
            ),
          ),
          child: Icon(
            CupertinoIcons.arrow_down,
            size: context.settingsSelectButtonIconSize(),
            color: whiteColor,
          ),
        ),
      ),
    );

    Widget settingsFloorImageWidget() => Expanded(
      child: Stack(children: [
        SingleChildScrollView(
          controller: scrollController,
          child: Column(children: [
            ...roomImages.roomsList().asMap().entries.map((row) =>
              Column(children: [
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
                          onTap: () {
                            isImageOn.value[row.key][col.key] = true;
                            isImageOn.value = List.from(isImageOn.value);
                            roomPickerDialog(row.key, col.key);
                          },
                          child: SizedBox(
                            width: context.settingsFloorImageWidth(),
                            height: context.settingsFloorImageHeight(),
                            child: Stack(children: [
                              roomImages.roomsList()[row.key][col.key].roomImage(),
                              if (isImageOn.value[row.key][col.key] && point >= changePointList[row.key][col.key]) Container(color: transpLampColor),
                            ]),
                          ),
                        ),
                        /// Lock Overlay
                        if (point < changePointList[row.key][col.key]) Container(
                          alignment: Alignment.center,
                          color: transpBlackColor,
                          width: context.settingsFloorImageLockWidth(),
                          height: context.settingsFloorImageLockHeight(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: context.settingsLockMargin()),
                              lockIcon(context.settingsLockIconSize()),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  pointIcon(context.settingsLockIconSize()),
                                  SizedBox(width: context.settingsLockMargin()),
                                  Text(
                                    "${changePointList[row.key][col.key]}",
                                    style: TextStyle(
                                      color: lampColor,
                                      fontSize: context.settingsLockFontSize(),
                                      fontWeight: FontWeight.normal,
                                      fontFamily: numberFont,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ]),
            ),
          ])
        ),
        if (!hasScrolledOnce.value) settingsFloorUpArrow(),
      ])
    );

    Widget settingsButtonShapeWidget() => Column(children: [
      ...List.generate(operationButtonCount, (row) => GestureDetector(
        onTap: () async {
          ref.read(buttonStyleProvider.notifier).state = await imageManager.changeSettingsIntValue(
            key: "operationButtonKey",
            current: buttonStyle,
            next: row
          );
        },
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (col) => Container(
            width: context.settingsShapeButtonSize(),
            height: context.settingsShapeButtonSize(),
            margin: EdgeInsets.only(
                top: (row == 0) ? context.settingsShapeButtonMarginTop(): 0,
                bottom: context.settingsShapeButtonMargin()
            ),
            child: Image.asset(List.filled(3, row == buttonStyle).operationButtonImage(row)[col]),
          )),
        )
      )),
      myDivider(context),
      ...buttonShapeList.toGroups(numberButtonColumnCount).asMap().entries.map((row) =>
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.value.asMap().entries.map((col) => Container(
              alignment: Alignment.center,
              width: context.settingsShapeButtonSize(),
              height: context.settingsShapeButtonSize(),
              margin: EdgeInsets.only(
                top: (row.key == 0) ? context.settingsShapeButtonMarginTop(): 0,
                bottom: context.settingsShapeButtonMargin()
              ),
              child: Stack(alignment: Alignment.center,
                children: [
                  /// Number Button
                  GestureDetector(
                    onTap: () async {
                      ref.read(buttonShapeProvider.notifier).state = await imageManager.changeSettingsStringValue(
                        key: "numberButtonKey",
                        current: buttonShape,
                        next: row.value[col.key]
                      );
                    },
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
                              fontSize: context.settingsShapeButtonFontSize(),
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

    Widget settingsButtonShapeLockWidget() => Column(children: List.generate(2, (i) =>
      Container(
        alignment: Alignment.center,
        color: transpBlackColor,
        width: context.settingsShapeButtonLockWidth(),
        height: context.settingsShapeButtonLockHeight(),
        margin: EdgeInsets.only(
          top: (i == 0) ? context.settingsShapeButtonLockMarginTop(): context.settingsShapeButtonLockMarginNext()
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: context.settingsLockMargin()),
            lockIcon(context.settingsLockIconSize()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                pointIcon(context.settingsLockIconSize()),
                SizedBox(width: context.settingsLockMargin()),
                Text(
                  "$buttonShapeLockPoint",
                  style: TextStyle(
                    color: lampColor,
                    fontSize: context.settingsLockFontSize(),
                    fontWeight: FontWeight.normal,
                    fontFamily: numberFont,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));

    Widget settingsGlassToggleWidget() => Column(children: [
      SizedBox(height: context.settingsGlassToggleMargin()),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(context.glass(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.settingsGlassFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: elevatorFont,
            ),
          ),
          CupertinoSwitch(
            value: glassStyle == "use",
            onChanged: (value) async {
              ref.read(glassStyleProvider.notifier).state = await imageManager.changeSettingsStringValue(
                key: "glassStyleKey",
                current: glassStyle,
                next: value ? "use": "non"
              );
            },
          ),
        ],
      ),
      myDivider(context),
    ]);

    Widget settingsBackgroundLockWidget() => Container(
      alignment: Alignment.topCenter,
      color: transpBlackColor,
      width: context.settingsBackgroundLockWidth(),
      height: context.settingsBackgroundLockHeight(),
      margin: EdgeInsets.only(top: context.settingsBackgroundLockMargin()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: context.settingsLockMargin()),
          lockIcon(context.settingsLockIconSize()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              pointIcon(context.settingsLockIconSize()),
              SizedBox(width: context.settingsLockMargin()),
              Text(
                "$buttonShapeLockPoint",
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.settingsLockFontSize(),
                  fontWeight: FontWeight.normal,
                  fontFamily: numberFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    Widget settingsBackgroundImageWidget() => Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...backgroundStyleList.toGroups(2).asMap().entries.map((row) =>
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.value.asMap().entries.map((col) => Container(
              alignment: Alignment.center,
              width: context.settingsBackgroundWidth(),
              height: context.settingsBackgroundHeight(),
              margin: EdgeInsets.only(top: context.settingsBackgroundMargin()),
              child: Stack(children: [
                GestureDetector(
                  onTap: () async {
                    ref.read(backgroundStyleProvider.notifier).state = await imageManager.changeSettingsStringValue(
                      key: "backgroundStyleKey",
                      current: backgroundStyle,
                      next: row.value[col.key]
                    );
                  },
                  child: Image.asset(row.value[col.key].backGroundImage(glassStyle)),
                ),
                if (backgroundStyleList.toGroups(2)[row.key][col.key] == backgroundStyle) Container(color: transpLampColor),
              ]),
            )).toList(),
          ),
        ),
      ]
    );

    ///Settings
    return Scaffold(
      appBar: AppBar(
        backgroundColor: blackColor,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: whiteColor),
        title: Row(children: [
          Spacer(flex: 1),
          Container(
            alignment: Alignment.center,
            height: 50,
            margin: EdgeInsets.only(right: 50),
            child: Text(context.settings(),
              style: TextStyle(
                color: whiteColor,
                fontSize: context.lang() == "ja" ? 28: 40,
                fontFamily: elevatorFont,
              ),
            ),
          ),
          Spacer(flex: 1),
        ]),
        leading: FadeTransition(
          opacity: animationController,
          child: Container(
            margin: EdgeInsets.only(left: 10),
            child: IconButton(
              iconSize: 40, // 大きめ
              icon: const Icon(CupertinoIcons.arrow_left_circle_fill,
                color: whiteColor
              ),
              onPressed: () => context.pushMyPage(true),
            ),
          ),
        ),
      ),
      body: Column(children: [
        selectButtonsWidget(),
        if (showSettingNumber.value == 3) settingsGlassToggleWidget(),
        (showSettingNumber.value == 0) ? settingsFloorImageWidget():
        (showSettingNumber.value == 1) ? settingsFloorNumberWidget():
        (showSettingNumber.value == 2) ? Stack(alignment: Alignment.topCenter,
          children: [
            settingsButtonShapeWidget(),
            if (point < buttonShapeLockPoint) settingsButtonShapeLockWidget(),
          ]
        ):
        (showSettingNumber.value == 3) ? Stack(alignment: Alignment.topCenter,
          children: [
            settingsBackgroundImageWidget(),
            if (point < backgroundLockPoint) settingsBackgroundLockWidget()
          ]
        ):
        settingsFloorNumberWidget(),
        (showSettingNumber.value == 0) ? myDivider(context): Spacer(flex: 1),
        const AdBannerWidget(),
      ]),
    );
  }
}