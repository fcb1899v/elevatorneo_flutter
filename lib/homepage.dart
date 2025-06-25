import 'package:flutter/cupertino.dart';
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
import 'menu.dart';
import 'sound_manager.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    //Provider
    final isMenu = ref.watch(isMenuProvider);
    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final floorImages = ref.watch(floorImagesProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);
    final glassStyle = ref.watch(glassStyleProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isConnectedInternet = ref.watch(internetProvider);
    final point = ref.watch(pointProvider);

    //Hooks
    final counter = useState(initialFloor);
    final currentFloor = useState(1);
    final nextFloor = useState(initialFloor);
    final isOutside = useState(true);
    final isMoving = useState(false);
    final isEmergency = useState(false);
    final isDoorState = useState(closedState); //[opened, closed, opening, closing]
    final isPressedOperationButtons = useState([false, false, false]); //[open, close, alert]
    final isAboveSelectedList = useState(List.generate(max + 1, (_) => false));
    final isUnderSelectedList = useState(List.generate(min * (-1) + 1, (_) => false));
    final isLoadingData = useState(false);
    final imageTopMargin = useState(0.0);
    final imageDurationTime = useState(0);
    final isWaitingUp = useState(false);
    final isWaitingDown = useState(false);
    final waitTime = useState(initialWaitTime);
    final openTime = useState(initialOpenTime);
    final animationController = useAnimationController(duration: Duration(milliseconds: flashTime))..repeat(reverse: true);
    final lifecycle = useAppLifecycleState();

    //Manager
    final imageManager = useMemoized(() => ImageManager());
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());
    final gamesManager = useMemoized(() => GamesManager(
      isGamesSignIn: isGamesSignIn,
      isConnectedInternet: isConnectedInternet,
    ));

    //Class
    final common = CommonWidget(context);
    final home = HomeWidget(context,
      floorNumbers: floorNumbers,
      floorStops: floorStops,
      floorImages: floorImages,
      buttonStyle: buttonStyle,
      buttonShape: buttonShape,
      backgroundStyle: backgroundStyle,
      glassStyle: glassStyle,
      isGamesSignIn: isGamesSignIn,
      isConnectedInternet: isConnectedInternet,
      point: point
    );

    initState() async {
      isLoadingData.value = true;
      try {
        if (context.mounted) imageTopMargin.value = context.imageMarginTop() - (max - initialFloor) * context.floorHeight();
        ref.read(floorImagesProvider.notifier).state = await imageManager.getImagesList();
        ref.read(internetProvider.notifier).state = await gamesManager.checkConnectedInternet();
        ref.read(gamesSignInProvider.notifier).state = await gamesManager.gamesSignIn();
        ref.read(pointProvider.notifier).state = await gamesManager.getBestScore();
        await ttsManager.initTts();
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

    ///Going up floor
    counterUp() async {
      ttsManager.speakText(context.upFloor(), !isOutside.value || currentFloor.value == counter.value);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
        Future.forEach(counter.value.upFromToNumber(nextFloor.value), (int i) async {
          if (isMoving.value) {
            imageDurationTime.value = i.elevatorSpeed(count, nextFloor.value);
            if (context.mounted) imageTopMargin.value += context.floorHeight();
          }
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value && !isOutside.value && !isEmergency.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && counter.value < nextFloor.value && nextFloor.value < max + 1) counter.value = counter.value + 1;
            if (counter.value == 0) counter.value = 1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == max)) {
              await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
                if (counter.value == 1 && context.mounted) imageTopMargin.value = context.imageMarginTop() - (max - 1) * context.floorHeight();
                if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, floorImages)), !isOutside.value || currentFloor.value == counter.value);
                counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                nextFloor.value = counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                if (!isOutside.value) currentFloor.value = counter.value;
                "isOutside: ${isOutside.value}, currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                if (isOutside.value && counter.value == currentFloor.value) isWaitingUp.value = false;
                if (isOutside.value && counter.value == currentFloor.value) isWaitingDown.value = false;
                final newPoint = ref.read(pointProvider.notifier).state;
                "pointKey".setSharedPrefInt(prefs, newPoint);
                await gamesManager.gamesSubmitScore(newPoint);
                if (isEmergency.value) {
                  await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
                    isEmergency.value = false;
                  });
                }
                isMoving.value = false;
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              });
            }
          });
        });
      });
    }

    ///Going down floor
    counterDown() async {
      ttsManager.speakText(context.downFloor(), !isOutside.value || currentFloor.value == counter.value);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
        Future.forEach(counter.value.downFromToNumber(nextFloor.value), (int i) async {
          if (isMoving.value) {
            imageDurationTime.value = i.elevatorSpeed(count, nextFloor.value);
            if (context.mounted) imageTopMargin.value -= context.floorHeight();
          }
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value && !isOutside.value && !isEmergency.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && min - 1 < nextFloor.value && nextFloor.value < counter.value) counter.value = counter.value - 1;
            if (counter.value == 0) counter.value = -1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == min)) {
              await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
                if (counter.value == 1 && context.mounted) imageTopMargin.value = context.imageMarginTop() - (max - 1) * context.floorHeight();
                if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, floorImages)), !isOutside.value || currentFloor.value == counter.value);
                counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                nextFloor.value = counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                if (!isOutside.value) currentFloor.value = counter.value;
                "isOutside: ${isOutside.value}, currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                if (isOutside.value && counter.value == currentFloor.value) isWaitingUp.value = false;
                if (isOutside.value && counter.value == currentFloor.value) isWaitingDown.value = false;
                final newPoint = ref.read(pointProvider.notifier).state;
                "pointKey".setSharedPrefInt(prefs, newPoint);
                await gamesManager.gamesSubmitScore(newPoint);
                if (isEmergency.value) {
                  await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
                    isEmergency.value = false;
                  });
                }
                isMoving.value = false;
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              });
            }
          });
        });
      });
    }

    ///Select floor button
    floorSelected(int i, bool selectFlag) async {
      await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (!isEmergency.value) {
        if (i == counter.value) {
          if (!isMoving.value && i == nextFloor.value && context.mounted) ttsManager.speakText(context.pushNumber(), true);
        } else if (!selectFlag) {
          if (context.mounted) ttsManager.speakText(context.notStop(), true);
        } else if (!i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)) {
          i.trueSelected(isAboveSelectedList.value, isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(isAboveSelectedList.value, isUnderSelectedList.value)) nextFloor.value = i;
          "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
          await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              (counter.value < nextFloor.value) ? counterUp() :
              (counter.value > nextFloor.value) ? counterDown() :
              (context.mounted) ? ttsManager.speakText(context.pushNumber(), !isOutside.value || currentFloor.value == counter.value): null;
            }
          });
        }
      }
    }

    ///Deselect floor button
    floorCanceled(int i) async {
      if (i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value) && i != nextFloor.value) {
        await audioManager.playEffectSound(index: 0, asset: cancelButton, volume: 0.5);
        await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        i.falseSelected(isAboveSelectedList.value, isUnderSelectedList.value);
        if (i == nextFloor.value) {
          nextFloor.value = (counter.value < nextFloor.value) ?
          counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value) :
          counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
        }
        "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
      }
    }

    ///Close door
    doorsClosing() async {
      if (isWaitingUp.value || isWaitingDown.value) floorSelected(currentFloor.value, true);
      if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await ttsManager.speakText(context.closeDoor(), !isOutside.value || currentFloor.value == counter.value);
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            (counter.value < nextFloor.value) ? counterUp():
            (counter.value > nextFloor.value) ? counterDown():
            (context.mounted) ? ttsManager.speakText(context.pushNumber(), !isOutside.value || currentFloor.value == counter.value): null;
          }
        });
      }
    }

    ///Pressed open button action
    pressedOpenAction(bool isOn) async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
      if (!isMoving.value) {
        isPressedOperationButtons.value = [isOn, false, false];
        if (isOn) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) async {
              if (!isMoving.value && !isEmergency.value  && isDoorState.value != openedState && isDoorState.value != openingState) {
                if (context.mounted) ttsManager.speakText(context.openDoor(), !isOutside.value || currentFloor.value == counter.value);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
                await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
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
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
      if (!isMoving.value) {
        isPressedOperationButtons.value = [false, isOn, false];
        if (isOn) {
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
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 0.5);
      isPressedOperationButtons.value = [false, false, isOn];
      if (isOn && ((currentFloor.value - counter.value).abs() > 5) && ((nextFloor.value - counter.value).abs() > 5)) {
        if (isLongPressed) {
          if (isMoving.value) isEmergency.value = true;
          if (isEmergency.value && isMoving.value) {
            await audioManager.playEffectSound(index: 0, asset: callSound, volume: 1.0);
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
              if (context.mounted) ttsManager.speakText(context.emergency(), !isOutside.value || currentFloor.value == counter.value);
              nextFloor.value = counter.value;
              isMoving.value = false;
              isEmergency.value = true;
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
            });
            await Future.delayed(Duration(seconds: openTime.value)).then((_) async {
              if (context.mounted) ttsManager.speakText(context.return1st(), !isOutside.value || currentFloor.value == counter.value);
            });
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
              if (counter.value != 1) {
                nextFloor.value = 1;
                "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                (counter.value < nextFloor.value) ? counterUp() : counterDown();
              } else {
                if (context.mounted) ttsManager.speakText(context.openDoor(), !isOutside.value || currentFloor.value == counter.value);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              }
            });
          }
        }
      }
    }

    changeView() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      isOutside.value = !isOutside.value;
      "isOutside: ${isOutside.value}".debugPrint();
      if (context.mounted) {
        imageTopMargin.value += (isOutside.value) ? - context.changeMarginTop() : context.changeMarginTop();
      }
    }

    pressedWaitUp() {
      "pressedWaitUp: ${isWaitingDown.value}".debugPrint();
      if (counter.value != currentFloor.value) {
        isWaitingUp.value = true;
        if (isDoorState.value == openingState) {
          pressedCloseAction(true);
          isPressedOperationButtons.value = [false, false, false];
        } else {
          doorsClosing();
        }
      } else {
        pressedOpenAction(true);
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    pressedWaitDown() {
      "pressedWaitDown: ${isWaitingDown.value}".debugPrint();
      if (counter.value != currentFloor.value) {
        isWaitingDown.value = true;
        if (isDoorState.value == openingState) {
          pressedCloseAction(true);
          isPressedOperationButtons.value = [false, false, false];
        } else {
          doorsClosing();
        }
      } else {
        pressedOpenAction(true);
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    ///Button action list
    List<dynamic> pressedButtonAction(bool isOn, isLongPressed) => [
      (isOn && isLongPressed) ? () => pressedOpenAction(isOn): (_) => pressedOpenAction(isOn),
      (isOn && isLongPressed) ? () => pressedCloseAction(isOn): (_) => pressedCloseAction(isOn),
      (isOn && isLongPressed) ? () => pressedAlertAction(isOn, isLongPressed): (_) => pressedAlertAction(isOn, isLongPressed),
    ];

    ///Action after changing door state
    useEffect(() {
      waitTime.value = (isOutside.value && counter.value != currentFloor.value) ? 0: initialWaitTime;
      openTime.value = (isOutside.value && counter.value != currentFloor.value) ? 3: initialOpenTime;
      if (isDoorState.value == openingState) {
        Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          isDoorState.value = openedState;
          "isDoorState: ${isDoorState.value}".debugPrint();
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openedState) {
            Future.delayed(Duration(seconds: openTime.value)).then((_) async {
              doorsClosing();
            });
          }
        });
      } else if (isDoorState.value == closingState) {
        doorsClosing();
      }
      return null;
    }, [isDoorState.value]);

    Future<void> pressedMenu() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).state = await isMenu.pressedMenu();
    }

    return Scaffold(
      backgroundColor: blackColor,
      ///My AppBar
      appBar: home.homeAppBar(onPressed: () => pressedMenu()),
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
              home.floorImagesWidget(
                currentFloorNumber: currentFloor.value,
                isOutside: isOutside.value,
                margin: imageTopMargin.value,
                duration: imageDurationTime.value,
              ),
              ///Black container for hiding
              home.blackHideWidget(isEmergency.value),
              ///Elevator design
              Row(children: [
                SizedBox(width: context.sideSpacerWidth()),
                Stack(children: [
                  ///Door Frame Image
                  home.upAndDownDoorFrame(),
                  ///Left Door Frame Image
                  home.leftDoorFrame(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  ///Right Door Frame Image
                  home.rightDoorFrame(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  ///Left Door Image
                  home.leftDoorImage(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  ///Right Door Image
                  home.rightDoorImage(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  ///Elevator Frame Image
                  home.elevatorFrameImage(isOutside.value),
                  ///Elevator Button Image
                  Container(
                    width: context.buttonPanelWidth(),
                    height: context.buttonPanelHeight(),
                    margin: EdgeInsets.only(
                      top: context.buttonPanelMarginTop(),
                      left: context.buttonPanelMarginLeft()
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ///Display Image
                        home.displayNumberWidget(
                          number: counter.value,
                          isMoving: isMoving.value,
                          next: nextFloor.value
                        ),
                        Spacer(),
                        ///Operation Buttons (Alert: 2)
                        if (!isOutside.value && buttonStyle != 2) GestureDetector(
                          onTapDown: pressedButtonAction(true, false)[2],
                          onTapUp: pressedButtonAction(false, false)[2],
                          onTapCancel: () => pressedButtonAction(false, false)[2],
                          onLongPress: pressedButtonAction(true, true)[2],
                          onLongPressStart: (_) => pressedButtonAction(true, true)[2],
                          onLongPressDown: (_) => pressedButtonAction(true, true)[2],
                          onLongPressUp:  () => pressedButtonAction(false, true)[2],
                          onLongPressEnd: pressedButtonAction(false, true)[2],
                          onLongPressCancel: () => pressedButtonAction(false, true)[2],
                          child: home.operationButton(isPressedOperationButtons.value, 2)
                        ),
                        ///Floor Buttons
                        if (!isOutside.value) Column(children: floorNumbers.floorNumbersList().asMap().entries.map((row) => Column(children: [
                          SizedBox(height: (row.key != 0) ? context.floorButtonMargin(): context.operationButtonMargin()),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: row.value.asMap().entries.map((col) => Row(children: [
                              GestureDetector(
                                child: home.floorButtonImage(col.value, col.value.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)),
                                onTap: () => floorSelected(col.value, floorStops[buttonIndex(row.key, col.key)]),
                                onLongPress: () => floorCanceled(col.value),
                                onDoubleTap: () => floorCanceled(col.value),
                              ),
                            ])).toList(),
                          ),
                        ])).toList()),
                        ///Operation Buttons (Close: 0, Open: 1)
                        if (!isOutside.value) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                              child: home.operationButton(isPressedOperationButtons.value, i),
                            ),
                          ]).toList()
                        ),
                        ///Operation Buttons (Alert: 2)
                        if (!isOutside.value && buttonStyle == 2) GestureDetector(
                          onTapDown: pressedButtonAction(true, false)[2],
                          onTapUp: pressedButtonAction(false, false)[2],
                          onTapCancel: () => pressedButtonAction(false, false)[2],
                          onLongPress: pressedButtonAction(true, true)[2],
                          onLongPressStart: (_) => pressedButtonAction(true, true)[2],
                          onLongPressDown: (_) => pressedButtonAction(true, true)[2],
                          onLongPressUp:  () => pressedButtonAction(false, true)[2],
                          onLongPressEnd: pressedButtonAction(false, true)[2],
                          onLongPressCancel: () => pressedButtonAction(false, true)[2],
                          child: home.operationButton(isPressedOperationButtons.value, 2)
                        ),
                        ///Up and down buttons
                        if (isOutside.value) home.upDownButtons(
                          currentFloor: currentFloor.value,
                          onTapUp: () => pressedWaitUp(),
                          onTapDown: () => pressedWaitDown(),
                          isWaitingUp: isWaitingUp.value,
                          isWaitingDown: isWaitingDown.value
                        ),
                      ]
                    ),
                  ),
                  ///Change View Button
                  if (isDoorState.value == openedState && currentFloor.value == counter.value) GestureDetector(
                    onTap: changeView,
                    child: Container(
                      margin: EdgeInsets.only(
                        top: context.changeViewMarginTop(),
                        left: context.changeViewMarginLeft(),
                      ),
                      child: common.flashButton(
                        animationController: animationController,
                        icon: CupertinoIcons.arrow_up_arrow_down,
                        isDark: backgroundStyle != "wood"
                      ),
                    )
                  )
                ])
              ]),
              ///Door Cover
              home.doorCover()
            ]),
          ),
          ///Menu
          if (isMenu) const MenuPage(),
          ///Admob Banner
          if (!isTest) const AdBannerWidget(),
          ///Progress Indicator
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]),
      ),
    );
  }
}

class HomeWidget {
  final BuildContext context;
  final List<int> floorNumbers;
  final List<bool> floorStops;
  final List<String> floorImages;
  final int buttonStyle;
  final String buttonShape;
  final String glassStyle;
  final String backgroundStyle;
  final bool isGamesSignIn;
  final bool isConnectedInternet;
  final int point;

  HomeWidget(this.context, {
    required this.floorNumbers,
    required this.floorStops,
    required this.floorImages,
    required this.buttonStyle,
    required this.buttonShape,
    required this.glassStyle,
    required this.backgroundStyle,
    required this.isGamesSignIn,
    required this.isConnectedInternet,
    required this.point,
  });

  ///AppBar
  AppBar homeAppBar({
    required void Function() onPressed,
  }) => AppBar(
    toolbarHeight: context.settingsAppBarHeight(),
    backgroundColor: blackColor,
    shadowColor: darkBlackColor,
    iconTheme: IconThemeData(color: whiteColor),
    automaticallyImplyLeading: false,
    title: Row(children: [
      //Icon for EV Mileage
      GestureDetector(
        onTap: () async {
          await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          await GamesManager(isGamesSignIn: isGamesSignIn, isConnectedInternet: isConnectedInternet).gamesShowLeaderboard();
        },
        child: Image.asset(pointImage,
          height: context.homeAppBarIconSize()
        ),
      ),
      //EV Mileage
      Container(
        margin: EdgeInsets.only(
          left: context.homeAppBarPointMarginLeft(),
          bottom: context.homeAppBarPointMarginBottom()
        ),
        child: HookBuilder(
          builder: (context) => Text(isTest ? "99999": "$point",
            style: TextStyle(
              color: lampColor,
              fontSize: context.homeAppBarPointFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont[0],
            ),
          ),
        ),
      ),
      evMileTooltip(),
    ]),
    actions: [
      GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: EdgeInsets.only(right: context.homeAppBarMenuButtonMargin()),
          child: Icon(Icons.menu,
            size: context.homeAppBarMenuButtonSize(),
          ),
        ),
      ),
    ],
  );

  //Tooltip for EV Mileage
  Container evMileTooltip() => Container(
    height: context.tooltipHeight(),
    alignment: Alignment.topCenter,
    margin: EdgeInsets.only(left: context.tooltipMarginLeft()),
    child: Tooltip(
      richMessage: TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            child: Image.asset(pointImage,
              height: context.tooltipTitleFontSize()
            ),
          ),
          TextSpan(
            text: " ${context.eVMile()}",
            style: TextStyle(
              color: lampColor,
              fontWeight: FontWeight.bold,
              fontFamily: normalFont,
              decorationColor: whiteColor,
              fontSize: context.tooltipTitleFontSize(),
            ),
          ),
          TextSpan(
            text: "\n ",
            style: TextStyle(
              fontSize: context.tooltipTitleMargin(),
            ),
          ),
          TextSpan(
            text: context.aboutEVMile(),
            style: TextStyle(
              color: whiteColor,
              fontStyle: FontStyle.normal,
              fontFamily: normalFont,
              decoration: TextDecoration.none,
              fontSize: context.tooltipDescFontSize(),
            ),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.tooltipPaddingSize()),
      margin: EdgeInsets.all(context.tooltipMarginSize()),
      verticalOffset: context.tooltipOffsetSize(),
      preferBelow: true, //isBelow for tooltip position
      decoration: BoxDecoration(
        color: transpBlackColor,
        borderRadius: BorderRadius.all(Radius.circular(context.tooltipBorderRadius()))
      ),
      showDuration: const Duration(milliseconds: toolTipTime),
      triggerMode: TooltipTriggerMode.tap,
      enableFeedback: true,
      child: Icon(CupertinoIcons.question_circle,
        color: Colors.white,
        size: context.tooltipIconSize(),
      ),
    ),
  );

  ///floor image
  AnimatedPositioned floorImagesWidget({
    required int currentFloorNumber,
    required bool isOutside,
    required double margin,
    required int duration,
  }) => (!isOutside) ? AnimatedPositioned(
    duration: Duration(milliseconds: duration),
    top: margin,
    left: context.doorMarginLeft() + context.sideSpacerWidth(),
    child: Column(
      children: floorImages.floorImages(floorNumbers).reversed.map((img) => Column(
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
    )
  ): AnimatedPositioned(
    duration: Duration(milliseconds: duration),
    bottom: margin,
    left: context.doorMarginLeft() + context.sideSpacerWidth(),
    child: Column(
      children: currentFloorNumber.insideImages(backgroundStyle).map((img) => Column(
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
    )
  );

  ///Black container for hiding
  Column blackHideWidget(bool isEmergency) => Column(children: [
    if (isEmergency) SizedBox(
      width: context.roomWidth(),
      height: context.floorHeight(),
      child: Image.asset(imageDark),
    ),
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
  ]);

  //UpAndDownDoorFrame
  Container upAndDownDoorFrame() => Container(
    alignment: Alignment.centerLeft,
    height: context.roomHeight(),
    margin: EdgeInsets.only(
        top: context.upDownDoorMarginTop(),
        left: context.doorMarginLeft()
    ),
    child: Image.asset(backgroundStyle.doorFrame()),
  );

  //LeftDoorFrame
  AnimatedContainer leftDoorFrame(bool isClosed) => AnimatedContainer(
    duration: const Duration(seconds: 2),
    transform: Matrix4.translationValues(isClosed ? 0: - context.doorWidth(), 0, 0),
    curve: Curves.easeInOut,
    alignment: Alignment.topLeft,
    margin: EdgeInsets.only(
        top: context.doorMarginTop(),
        left: context.doorMarginLeft() + context.doorWidth()
    ),
    height: context.roomHeight(),
    child: Image.asset(leftSideFrame),
  );

  //RightDoorFrame
  AnimatedContainer rightDoorFrame(bool isClosed) => AnimatedContainer(
    duration: const Duration(seconds: 2),
    transform: Matrix4.translationValues(isClosed ? 0: context.doorWidth(), 0, 0),
    curve: Curves.easeInOut,
    alignment: Alignment.topLeft,
    margin: EdgeInsets.only(
      top: context.doorMarginTop(),
      left: context.doorMarginLeft() + context.doorWidth() - context.sideFrameWidth()
    ),
    height: context.roomHeight(),
    child: Image.asset(rightSideFrame),
  );

  //LeftDoor
  AnimatedContainer leftDoorImage(bool isClosedState) => AnimatedContainer(
    duration: const Duration(seconds: 2),
    transform: Matrix4.translationValues(isClosedState ? 0: - context.doorWidth(), 0, 0),
    curve: Curves.easeInOut,
    alignment: Alignment.topLeft,
    margin: EdgeInsets.only(
      top: context.doorMarginTop(),
      left: context.doorMarginLeft()
    ),
    width: context.doorWidth(),
    height: context.roomHeight(),
    child: Image.asset(backgroundStyle.leftDoor(glassStyle)),
  );

  //RightDoor
  AnimatedContainer rightDoorImage(bool isClosedState) => AnimatedContainer(
    duration: const Duration(seconds: 2),
    transform: Matrix4.translationValues(isClosedState ? 0: context.doorWidth(), 0, 0),
    curve: Curves.easeInOut,
    alignment: Alignment.topLeft,
    margin: EdgeInsets.only(
      top: context.doorMarginTop(),
      left: context.doorMarginLeft() + context.doorWidth()
    ),
    width: context.doorWidth(),
    height: context.roomHeight(),
    child: Image.asset(backgroundStyle.rightDoor(glassStyle)),
  );

  //Elevator Frame
  Container elevatorFrameImage(bool isOutside) => Container(
    alignment: Alignment.topCenter,
    width: context.elevatorWidth() ,
    height: context.elevatorHeight(),
    child: Image.asset(backgroundStyle.elevatorFrame(isOutside))
  );

  //DoorCover
  Row doorCover() => Row(children: [
    Container(
      color: blackColor,
      width: context.sideSpacerWidth(),
      height: context.elevatorHeight(),
    ),
    SizedBox(width: context.elevatorWidth()),
    Container(
      color: blackColor,
      width: context.width() - context.sideSpacerWidth() - context.elevatorWidth(),
      height: context.elevatorHeight(),
    ),
  ]);

  ///Display
  Container displayNumberWidget({
    required int number,
    required bool isMoving,
    required int next,
  }) => Container(
    width: context.displayWidth(),
    height: context.displayHeight(),
    color: displayBackgroundColor[buttonStyle],
    child: Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ///Arrow
        displayArrow(
          number: number,
          isMoving: isMoving,
          next: next,
        ),
        ///Floor number
        displayNumber(number),
      ]
    )
  );

  //Display Arrow
  Widget displayArrow({
    required int number,
    required bool isMoving,
    required int next,
  }) => Container(
    height: context.displayArrowHeight(buttonStyle),
    alignment: Alignment.topCenter,
    margin: EdgeInsets.only(top: context.displayArrowMarginTop(buttonStyle)),
    child: Image.asset(number.arrowImage(isMoving, next, buttonStyle)),
  );

  //Display Number
  Widget displayNumber(int number) => Container(
    alignment: Alignment.topRight,
    height: context.displayNumberHeight(),
    margin: EdgeInsets.only(
      top: context.displayNumberMarginTop(buttonStyle),
      right: context.displayNumberMarginRight(buttonStyle)
    ),
    child: useMemoized(() => HookBuilder(
      builder: (context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: number.displayAlphabet(),
            style: TextStyle(
              color: displayNumberColor[buttonStyle],
              fontSize: context.displayAlphabetFontSize(buttonStyle),
              fontWeight: FontWeight.normal,
              fontFamily: alphabetFont[buttonStyle],
            ),
          ),
          TextSpan(text: " ",
            style: TextStyle(
              fontSize: context.displayMarginFontSize(buttonStyle),
            ),
          ),
          TextSpan(text: number.displayNumber(),
            style: TextStyle(
              color: displayNumberColor[buttonStyle],
              fontSize: context.displayNumberFontSize(buttonStyle),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont[buttonStyle],
            ),
          ),
        ]),
        strutStyle: StrutStyle(
          fontSize: context.displayNumberFontSize(buttonStyle),
          height: 1.0,
          forceStrutHeight: true,
        ),
      )
    ), [number])
  );

  ///Button
  //Open or Close Button (Close: 0, Open: 1, Alert:2)
  Widget operationButton(List<bool> isPressedList, int number) => Container(
    width: context.operationButtonSize(),
    height: context.operationButtonSize(),
    margin: EdgeInsets.only(top: context.operationButtonMargin()),
    child: Image.asset(isPressedList.operationButtonImage(buttonStyle)[number]),
  );

  //Floor Button
  Widget floorButtonImage(int floorNumber, bool isSelected) => SizedBox(
    width: context.buttonSize(),
    height: context.buttonSize(),
    child: Stack(alignment: Alignment.center,
      children: [
        Image.asset(isSelected.numberBackground(buttonStyle, buttonShape)),
        Container(
          margin: EdgeInsets.only(
            top: context.floorButtonNumberMarginTop(buttonShape.buttonShapeIndex()),
            bottom: context.floorButtonNumberMarginBottom(buttonShape.buttonShapeIndex())
          ),
          child:Text(floorNumber.buttonNumber(),
            style: TextStyle(
              color: (buttonStyle != 0) ? blackColor: isSelected.floorButtonNumberColor(buttonShape),
              fontSize: context.floorButtonNumberFontSize(buttonShape.buttonShapeIndex()),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget upDownButtons({
    required int currentFloor,
    required void Function() onTapUp,
    required void Function() onTapDown,
    required bool isWaitingUp,
    required bool isWaitingDown,
  }) => Column(children: List.generate(2, (i) =>
    ((i == 0 && currentFloor != max) || (i == 1 && currentFloor != min)) ? GestureDetector(
      onTap: (i == 0) ? onTapUp : onTapDown,
      child: Container(
        width: context.operationButtonSize(),
        height: context.operationButtonSize(),
        margin: EdgeInsets.only(bottom: context.upDownButtonMargin()),
        child: Image.asset(
          (i == 0) ? isWaitingUp.upBackGround(buttonStyle):
            isWaitingDown.downBackGround(buttonStyle)
        ),
      ),
    ): SizedBox(),
  ));

}

