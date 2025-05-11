import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admob_banner.dart';
import 'games_manager.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'image_manager.dart';
import 'main.dart';
import 'my_app_bar.dart';
import 'sound_manager.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    //Provider
    final floorNumbers = ref.watch(floorNumbersProvider);
    final roomImages = ref.watch(roomImagesProvider);
    final point = ref.watch(pointProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);
    final glassStyle = ref.watch(glassStyleProvider);

    //Hooks
    final counter = useState(1);
    final nextFloor = useState(1);
    final isMoving = useState(false);
    final isEmergency = useState(false);
    final isDoorState = useState(closedState); //[opened, closed, opening, closing]
    final isPressedOperationButtons = useState([false, false, false]); //[open, close, alert]
    final isAboveSelectedList = useState(List.generate(max + 1, (_) => false));
    final isUnderSelectedList = useState(List.generate(min * (-1) + 1, (_) => false));
    final isSoundOn = useState(true);
    final isLoadingData = useState(false);
    final imageTopMargin = useState(context.doorMarginTop() - (max - 1) * context.roomHeight() * 17/16);
    final imageDurationTime = useState(0);
    final lifecycle = useAppLifecycleState();

    //Manager
    final imageManager = useMemoized(() => ImageManager());
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());

    initState() async {
      isLoadingData.value = true;
      try {
        if (context.mounted) imageTopMargin.value = context.doorMarginTop() - (max - 1) * context.floorHeight();
        final prefs = await SharedPreferences.getInstance();
        await ttsManager.initTts();
        ref.read(floorNumbersProvider.notifier).state = "floorsKey".getSharedPrefListInt(prefs, initialFloorNumbers);
        ref.read(roomImagesProvider.notifier).state = await imageManager.getImagesList();
        ref.read(pointProvider.notifier).state = await getBestScore();
        ref.read(buttonShapeProvider.notifier).state = "numberButtonKey".getSharedPrefString(prefs, initialButtonShape);
        ref.read(buttonStyleProvider.notifier).state = "operationButtonKey".getSharedPrefInt(prefs, initialButtonStyle);
        ref.read(backgroundStyleProvider.notifier).state = "backgroundStyleKey".getSharedPrefString(prefs, initialBackgroundStyle);
        ref.read(glassStyleProvider.notifier).state = "glassStyleKey".getSharedPrefString(prefs, initialGlassStyle);
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
      return null;
    }, []);

    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          audioManager.stopAll();
          ttsManager.stopTts();
        }
      }
      return null;
    }, [lifecycle]);

    /// 上の階へ行く
    counterUp() async {
      ttsManager.speakText(context.upFloor());
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(seconds: waitTime)).then((_) {
        Future.forEach(counter.value.upFromToNumber(nextFloor.value), (int i) async {
          if (isMoving.value) {
            imageDurationTime.value = i.elevatorSpeed(count, nextFloor.value);
            if (context.mounted) imageTopMargin.value += context.floorHeight();
          }
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && counter.value < nextFloor.value && nextFloor.value < max + 1) counter.value = counter.value + 1;
            if (counter.value == 0) counter.value += 1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == max)) {
              await Future.delayed(Duration(seconds: waitTime)).then((_) async {
                if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, roomImages)));
                counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                nextFloor.value = counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                isMoving.value = false;
                isEmergency.value = false;
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
                "nextFloor: ${nextFloor.value}".debugPrint();
                final newPoint = ref.read(pointProvider.notifier).state;
                await "pointKey".setSharedPrefInt(prefs, newPoint);
                await gamesSubmitScore(newPoint);
              });
            }
          });
        });
      });
    }

    /// 下の階へ行く
    counterDown() async {
      ttsManager.speakText(context.downFloor());
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(seconds: waitTime)).then((_) {
        Future.forEach(counter.value.downFromToNumber(nextFloor.value), (int i) async {
          if (isMoving.value) {
            imageDurationTime.value = i.elevatorSpeed(count, nextFloor.value);
            if (context.mounted) imageTopMargin.value -= context.floorHeight();
          }
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && min - 1 < nextFloor.value && nextFloor.value < counter.value) counter.value = counter.value - 1;
            if (counter.value == 0) counter.value -= 1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == min)) {
              await Future.delayed(Duration(seconds: waitTime)).then((_) async {
                if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, roomImages)));
                counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                nextFloor.value = counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                isMoving.value = false;
                isEmergency.value = false;
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
                "nextFloor: ${nextFloor.value}".debugPrint();
                final newPoint = ref.read(pointProvider.notifier).state;
                await "pointKey".setSharedPrefInt(prefs, newPoint);
                await gamesSubmitScore(newPoint);
              });
            }
          });
        });
      });
    }

    /// ドアを閉じる
    doorsClosing() async {
      if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await ttsManager.speakText(context.closeDoor());
        await Future.delayed(const Duration(seconds: waitTime)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            (counter.value < nextFloor.value) ? counterUp() :
            (counter.value > nextFloor.value) ? counterDown() :
            (context.mounted) ? ttsManager.speakText(context.pushNumber()): null;
          }
        });
      }
    }

    ///Pressed open button action
    pressedOpenAction(bool isOn) async {
      if (!isMoving.value) {
        isPressedOperationButtons.value = [isOn, false, false];
        if (isOn) {
          await audioManager.stopSound(0);
          if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) async {
              if (!isMoving.value && !isEmergency.value  && isDoorState.value != openedState && isDoorState.value != openingState) {
                if (context.mounted) ttsManager.speakText(context.openDoor());
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
                await Future.delayed(const Duration(seconds: waitTime)).then((_) {
                  if (!isMoving.value && !isEmergency.value && isDoorState.value == openingState) {
                    isDoorState.value = openedState;
                    "isDoorState: ${isDoorState.value}".debugPrint();
                  }
                });
              }
            });
          }
        }
      } else {
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    ///Pressed close button action
    pressedCloseAction(bool isOn) async {
      if (!isMoving.value) {
        isPressedOperationButtons.value = [false, isOn, false];
        if (isOn) {
          await audioManager.stopSound(0);
          if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) => doorsClosing());
          }
        }
      } else {
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    ///Long pressed alert button action
    pressedAlertAction(bool isOn, isLongPressed) async {
      isPressedOperationButtons.value = [false, false, isOn];
      if (isOn) {
        await audioManager.stopSound(0);
        if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (isLongPressed) {
          if (isMoving.value) isEmergency.value = true;
          if (isEmergency.value && isMoving.value) {
            await audioManager.stopSound(0);
            if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: callSound, volume: 1.0);
            await Future.delayed(const Duration(seconds: waitTime)).then((_) {
              if (context.mounted) ttsManager.speakText(context.emergency());
              nextFloor.value = counter.value;
              isMoving.value = false;
              isEmergency.value = true;
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
            });
            await Future.delayed(const Duration(seconds: openTime)).then((_) async {
              if (context.mounted) ttsManager.speakText(context.return1st());
            });
            await Future.delayed(const Duration(seconds: waitTime * 2)).then((_) async {
              if (counter.value != 1) {
                nextFloor.value = 1;
                "nextFloor: ${nextFloor.value}".debugPrint();
                (counter.value < nextFloor.value) ? counterUp() : counterDown();
              } else {
                if (context.mounted) ttsManager.speakText(context.openDoor());
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              }
            });
          }
        }
      }
    }

    ///Button action list
    List<dynamic> pressedButtonAction(bool isOn, isLongPressed) => [
      (isOn && isLongPressed) ? () => pressedOpenAction(isOn): (_) => pressedOpenAction(isOn),
      (isOn && isLongPressed) ? () => pressedCloseAction(isOn): (_) => pressedCloseAction(isOn),
      (isOn && isLongPressed) ? () => pressedAlertAction(isOn, isLongPressed): (_) => pressedAlertAction(isOn, isLongPressed),
    ];

    ///行き先階ボタンを選択する
    floorSelected(int i, bool selectFlag) async {
      if (!isEmergency.value) {
        if (i == counter.value) {
          if (!isMoving.value && i == nextFloor.value) ttsManager.speakText(context.pushNumber());
        } else if (!selectFlag) {
          ttsManager.speakText(context.notStop());
        } else if (!i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)) {
          await audioManager.stopSound(0);
          if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          i.trueSelected(isAboveSelectedList.value, isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(isAboveSelectedList.value, isUnderSelectedList.value)) nextFloor.value = i;
          "nextFloor: ${nextFloor.value}".debugPrint();
          await Future.delayed(const Duration(seconds: waitTime)).then((_) async {
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              (counter.value < nextFloor.value) ? counterUp() :
              (counter.value > nextFloor.value) ? counterDown() :
              (context.mounted) ? ttsManager.speakText(context.pushNumber()): null;
            }
          });
        }
      }
    }

    ///Deselect floor button remote add origin
    floorCanceled(int i) async {
      if (i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value) && i != nextFloor.value) {
        await audioManager.stopSound(0);
        if (isSoundOn.value) await audioManager.playEffectSound(index: 0, asset: cancelButton, volume: 0.5);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        i.falseSelected(isAboveSelectedList.value, isUnderSelectedList.value);
        if (i == nextFloor.value) {
          nextFloor.value = (counter.value < nextFloor.value) ?
          counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value) :
          counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
        }
        "nextFloor: ${nextFloor.value}".debugPrint();
      }
    }

    ///Action after changing door state
    useEffect(() {
      if (isDoorState.value == openingState) {
        Future.delayed(const Duration(seconds: waitTime)).then((_) {
          isDoorState.value = openedState;
          "isDoorState: ${isDoorState.value}".debugPrint();
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openedState) {
            Future.delayed(const Duration(seconds: openTime)).then((_) async {
              doorsClosing();
            });
          }
        });
      } else if (isDoorState.value == closingState) {
        doorsClosing();
      }
      return null;
    }, [isDoorState.value]);

    return Scaffold(
      backgroundColor: blackColor,
      ///My AppBar
      appBar: myAppBar(
        context: context,
        point: point,
        pressedMenu: () => context.pushMyPage(false), ///to MyMenuPage
      ),
      ///Body
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(children: [
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 1.5,
            child: Stack(children: [
              ///Room Image
              AnimatedPositioned(
                duration: Duration(milliseconds: imageDurationTime.value),
                top: imageTopMargin.value,
                left: context.doorMarginLeft() + context.sideSpacerWidth(),
                child: Column(
                  children: roomImages.floorImages(floorNumbers).reversed.map((img) => Column(
                    children: [
                      SizedBox(
                        width: context.roomWidth(),
                        height: context.roomHeight(),
                        child: img,
                      ),
                      SizedBox(
                        width: context.roomWidth(),
                        height: (context.floorHeight() - context.roomHeight()),
                        child: Image.asset(imageDark,
                          width: double.infinity,
                          fit: BoxFit.fitWidth
                        ),
                      ),
                    ],
                  )).toList(),
                ),
              ),
              Column(children: [
                Container(
                  margin: EdgeInsets.only(
                    top: context.doorMarginTop(),
                    left: context.doorMarginLeft() + context.sideSpacerWidth(),
                  ),
                  width: context.width(),
                  height: context.roomHeight(),
                  color: transpColor,
                ),
                Expanded(
                  child: Container(color: blackColor),
                )
              ]),
              Row(children: [
                SizedBox(width: context.sideSpacerWidth()),
                Stack(children: [
                  ///Door Frame Image
                  upAndDownDoorFrame(context, backgroundStyle),
                  ///Left Door Frame Image
                  leftDoorFrame(context, isDoorState.value == closedState),
                  ///Right Door Frame Image
                  rightDoorFrame(context, isDoorState.value == closedState),
                  ///Left Door Image
                  leftDoorImage(context, backgroundStyle, glassStyle, isDoorState.value == closedState),
                  ///Right Door Image
                  rightDoorImage(context, backgroundStyle, glassStyle, isDoorState.value == closedState),
                  ///Elevator Frame Image
                  elevatorFrameImage(context, backgroundStyle),
                  ///Display Image
                  displayNumber(context, counter.value, isMoving.value, nextFloor.value),
                  ///Elevator Button Image
                  Container(
                    width: context.buttonPanelWidth(),
                    height: context.buttonPanelHeight(),
                    margin: EdgeInsets.only(
                      top: context.buttonPanelMarginTop(),
                      left: context.buttonPanelMarginLeft()
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ///Operation Buttons (Alert: 2)
                        if (buttonStyle != 2) GestureDetector(
                          // onTap: () => pressedButtonAction(true, false)[2],
                          onTapDown: pressedButtonAction(true, false)[2],
                          onTapUp: pressedButtonAction(false, false)[2],
                          onTapCancel: () => pressedButtonAction(false, false)[2],
                          onLongPress: pressedButtonAction(true, true)[2],
                          onLongPressStart: (_) => pressedButtonAction(true, true)[2],
                          onLongPressDown: (_) => pressedButtonAction(true, true)[2],
                          onLongPressUp:  () => pressedButtonAction(false, true)[2],
                          onLongPressEnd: pressedButtonAction(false, true)[2],
                          onLongPressCancel: () => pressedButtonAction(false, true)[2],
                          child: operationButton(context, buttonStyle, isPressedOperationButtons.value, 2)
                        ),
                        ///Floor Buttons
                        Column(children: floorNumbers.floorNumbersList().asMap().entries.map((row) => Column(children: [
                          if (row.key != 0) SizedBox(height: context.floorButtonMargin()),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.value.asMap().entries.map((floor) => Row(children: [
                              GestureDetector(
                                child: floorButtonImage(context, buttonStyle, buttonShape, floor.value, floor.value.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)),
                                onTap: () => floorSelected(floor.value, isFloors[row.key][floor.key]),
                                onLongPress: () => floorCanceled(floor.value),
                                onDoubleTap: () => floorCanceled(floor.value),
                              ),
                            ])).toList(),
                          ),
                        ])).toList()),
                        ///Operation Buttons (Close: 0, Open: 1)
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [0, 1].expand((i) => [
                            GestureDetector(
                              onTap: () => pressedButtonAction(true, false)[i],
                              onTapDown: pressedButtonAction(true, false)[i],
                              onTapUp: pressedButtonAction(false, false)[i],
                              onTapCancel: () => pressedButtonAction(false, false)[i],
                              onLongPress: pressedButtonAction(true, true)[i],
                              onLongPressStart: (_) => pressedButtonAction(true, true)[i],
                              onLongPressDown: (_) => pressedButtonAction(true, true)[i],
                              onLongPressUp:  () => pressedButtonAction(false, true)[i],
                              onLongPressEnd: pressedButtonAction(false, true)[i],
                              onLongPressCancel: () => pressedButtonAction(false, true)[i],
                              child: operationButton(context, buttonStyle, isPressedOperationButtons.value, i),
                            ),
                          ]).toList()
                        ),
                        ///Operation Buttons (Alert: 2)
                        if (buttonStyle == 2) GestureDetector(
                          // onTap: () => pressedButtonAction(true, false)[2],
                            onTapDown: pressedButtonAction(true, false)[2],
                            onTapUp: pressedButtonAction(false, false)[2],
                            onTapCancel: () => pressedButtonAction(false, false)[2],
                            onLongPress: pressedButtonAction(true, true)[2],
                            onLongPressStart: (_) => pressedButtonAction(true, true)[2],
                            onLongPressDown: (_) => pressedButtonAction(true, true)[2],
                            onLongPressUp:  () => pressedButtonAction(false, true)[2],
                            onLongPressEnd: pressedButtonAction(false, true)[2],
                            onLongPressCancel: () => pressedButtonAction(false, true)[2],
                            child: operationButton(context, buttonStyle, isPressedOperationButtons.value, 2)
                        ),
                      ]
                    ),
                  ),
                ])
              ]),
              ///Door Cover
              doorCover(context)
            ]),
          ),
          ///Admob Banner
          AdBannerWidget(),
          ///Progress Indicator
          if (isLoadingData.value) circularProgressIndicator(context),
        ]),
      ),
    );
  }
}

