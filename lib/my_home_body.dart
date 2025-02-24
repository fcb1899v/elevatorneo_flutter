import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_function.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'main.dart';
import 'my_menu.dart';
import 'my_settings.dart';

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final isMenu = ref.watch(isMenuProvider);
    final isSettings = ref.watch(isSettingsProvider);
    final floorNumbers = ref.watch(floorNumbersProvider);
    final roomImages = ref.watch(roomImagesProvider);
    final point = ref.watch(pointProvider);

    final counter = useState(1);
    final nextFloor = useState(1);
    final isMoving = useState(false);
    final isEmergency = useState(false);
    final isDoorState = useState(closedState); //[opened, closed, opening, closing]
    final isPressedOperationButtons = useState([false, false, false]);  //open, close, alert
    final isAboveSelectedList = useState(List.generate(max + 1, (_) => false));
    final isUnderSelectedList = useState(List.generate(min * (-1) + 1, (_) => false));
    final isSoundOn = useState(true);

    final FlutterTts flutterTts = FlutterTts();
    final audioPlayers = AudioPlayerManager();
    final lifecycle = useAppLifecycleState();

    initTts() async {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
          ]
      );
      await flutterTts.setVolume(1);
      if (context.mounted) await flutterTts.setLanguage(context.ttsLang());
      if (context.mounted) {
        await flutterTts.setVoice({
          "name": context.voiceName(Platform.isAndroid),
          "locale": context.ttsVoice()
        });
      }
      await flutterTts.setSpeechRate(0.5);
      if (context.mounted) context.voiceName(Platform.isAndroid).debugPrint();
      if (context.mounted) context.pushNumber().speakText(flutterTts, isSoundOn.value);
    }

    initAudio() async {
      await audioPlayers.audioPlayers[0].setReleaseMode(ReleaseMode.release);
      await audioPlayers.audioPlayers[0].setVolume(0.5);
    }

    initGames() async {
      await gamesSignIn();
      final bestScore = await getBestScore();
      if (bestScore > point) {
        ref.read(pointProvider.notifier).state = bestScore;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        "floorNumber: $floorNumbers".debugPrint();
        "roomImage: $roomImages".debugPrint();
        "point: $point".debugPrint();
        await initTts();
        await initAudio();
        await initGames();
      });
      return null;
    }, []);

    useEffect(() {
      Future<void> handleLifecycleChange() async {
        // ウィジェットが破棄されていたら何もしない
        if (!context.mounted) return;
        // アプリがバックグラウンドに移行する直前
        if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
          for (int i = 0; i < audioPlayers.audioPlayers.length; i++) {
            final player = audioPlayers.audioPlayers[i];
            try {
              if (player.state == PlayerState.playing) await player.stop();
            } catch (e) {
              'Error handling stop for player $i: $e'.debugPrint();
            }
          }
          flutterTts.stop();
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted, audioPlayers.audioPlayers.length, flutterTts]);

    /// 上の階へ行く
    counterUp() async {
      context.upFloor().speakText(flutterTts, isSoundOn.value);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(seconds: waitTime)).then((_) {
        Future.forEach(counter.value.upFromToNumber(nextFloor.value), (int i) async {
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && counter.value < nextFloor.value && nextFloor.value < max + 1) counter.value = counter.value + 1;
            if (counter.value == 0) counter.value = 1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == max)) {
              if (context.mounted) context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, roomImages)).speakText(flutterTts, isSoundOn.value);
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              nextFloor.value = counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              isMoving.value = false;
              isEmergency.value = false;
              isDoorState.value = openingState;
              "isDoorState: ${isDoorState.value}".debugPrint();
              "$nextString${nextFloor.value}".debugPrint();
              final newPoint = ref.read(pointProvider.notifier).state;
              await "pointKey".setSharedPrefInt(prefs, newPoint);
              await gamesSubmitScore(newPoint);
              "point: $newPoint".debugPrint();
            }
          });
        });
      });
    }

    /// 下の階へ行く
    counterDown() async {
      context.downFloor().speakText(flutterTts, isSoundOn.value);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      final prefs = await SharedPreferences.getInstance();
      await Future.delayed(const Duration(seconds: waitTime)).then((_) {
        Future.forEach(counter.value.downFromToNumber(nextFloor.value), (int i) async {
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value) ref.read(pointProvider.notifier).state++;
            if (isMoving.value && min - 1 < nextFloor.value && nextFloor.value < counter.value) counter.value = counter.value - 1;
            if (counter.value == 0) counter.value = -1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == min)) {
              if (context.mounted) context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, roomImages)).speakText(flutterTts, isSoundOn.value);
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              nextFloor.value = counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              isMoving.value = false;
              isEmergency.value = false;
              isDoorState.value = openingState;
              "isDoorState: ${isDoorState.value}".debugPrint();
              "$nextString${nextFloor.value}".debugPrint();
              final newPoint = ref.read(pointProvider.notifier).state;
              await "pointKey".setSharedPrefInt(prefs, newPoint);
              await gamesSubmitScore(newPoint);
              "point: $newPoint".debugPrint();
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
        await context.closeDoor().speakText(flutterTts, isSoundOn.value);
        await Future.delayed(const Duration(seconds: waitTime)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            (counter.value < nextFloor.value) ? counterUp() :
            (counter.value > nextFloor.value) ? counterDown() :
            (context.mounted) ? context.pushNumber().speakText(flutterTts, isSoundOn.value): null;
          }
        });
      }
    }

    ///Pressed open button action
    pressedOpenAction(bool isOn) async {
      isPressedOperationButtons.value = [isOn, false, false];
      if (isOn) {
        selectButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
          Future.delayed(const Duration(milliseconds: flashTime)).then((_) async {
            if (!isMoving.value && !isEmergency.value  && isDoorState.value != openedState && isDoorState.value != openingState) {
              if (context.mounted) context.openDoor().speakText(flutterTts, isSoundOn.value);
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
    }

    ///Pressed close button action
    pressedCloseAction(bool isOn) async {
      isPressedOperationButtons.value = [false, isOn, false];
      if (isOn) {
        selectButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
          Future.delayed(const Duration(milliseconds: flashTime)).then((_) => doorsClosing());
        }
      }
    }

    ///Long pressed alert button action
    pressedAlertAction(bool isOn, isLongPressed) async {
      isPressedOperationButtons.value = [false, false, isOn];
      if (isOn) {
        selectButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (isLongPressed) {
          if (isMoving.value) isEmergency.value = true;
          if (isEmergency.value && isMoving.value) {
            callSound.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
            await Future.delayed(const Duration(seconds: waitTime)).then((_) {
              if (context.mounted) context.emergency().speakText(flutterTts, isSoundOn.value);
              nextFloor.value = counter.value;
              isMoving.value = false;
              isEmergency.value = true;
              counter.value.clearLowerFloor(
                  isAboveSelectedList.value, isUnderSelectedList.value);
              counter.value.clearUpperFloor(
                  isAboveSelectedList.value, isUnderSelectedList.value);
            });
            await Future.delayed(const Duration(seconds: openTime)).then((
                _) async {
              if (context.mounted) context.return1st().speakText(flutterTts, isSoundOn.value);
            });
            await Future.delayed(const Duration(seconds: waitTime * 2)).then((
                _) async {
              if (counter.value != 1) {
                nextFloor.value = 1;
                "$nextString${nextFloor.value}".debugPrint();
                (counter.value < nextFloor.value) ? counterUp() : counterDown();
              } else {
                if (context.mounted) context.openDoor().speakText(flutterTts, isSoundOn.value);
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
          if (!isMoving.value && i == nextFloor.value) context.pushNumber().speakText(flutterTts, isSoundOn.value);
        } else if (!selectFlag) {
          context.notStop().speakText(flutterTts, isSoundOn.value);
        } else if (!i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)) {
          selectButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          i.trueSelected(isAboveSelectedList.value, isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(isAboveSelectedList.value, isUnderSelectedList.value)) nextFloor.value = i;
          "$nextString${nextFloor.value}".debugPrint();
          await Future.delayed(const Duration(seconds: waitTime)).then((_) async {
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              (counter.value < nextFloor.value) ? counterUp() :
              (counter.value > nextFloor.value) ? counterDown() :
              (context.mounted) ? context.pushNumber().speakText(flutterTts, isSoundOn.value): null;
            }
          });
        }
      }
    }

    ///Deselect floor button remote add origin
    floorCanceled(int i) async {
      if (i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value) && i != nextFloor.value) {
        cancelButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        i.falseSelected(isAboveSelectedList.value, isUnderSelectedList.value);
        if (i == nextFloor.value) {
          nextFloor.value = (counter.value < nextFloor.value) ?
          counter.value.upNextFloor(isAboveSelectedList.value, isUnderSelectedList.value) :
          counter.value.downNextFloor(isAboveSelectedList.value, isUnderSelectedList.value);
        }
        "$nextString${nextFloor.value}".debugPrint();
      }
    }

    ///Menu button action
    pressedMenu() async {
      selectButton.playAudio(audioPlayers.audioPlayers[0], isSoundOn.value);
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).state = isSettings ? false: !isMenu;
      ref.read(isSettingsProvider.notifier).state = false;
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
      ///AppBar
      appBar: AppBar(
        backgroundColor: blackColor,
        shadowColor: Colors.transparent,
        title: Row(children: [
          GestureDetector(
            onTap: () async => {
              Vibration.vibrate(duration: vibTime, amplitude: vibAmp),
              gamesShowLeaderboard(),
            },
            child: pointIcon(30),
          ),
          Container(
            height: 50,
            margin: const EdgeInsets.only(left: 10),
            child:useMemoized(() => HookBuilder(
              builder: (context) => Text("$point",
                style: const TextStyle(
                  color: lampColor,
                  fontSize: 40,
                  fontWeight: FontWeight.normal,
                  fontFamily: numberFont,
                ),
              ),
            ), [point]),
          ),
          evMileTooltip(context),
        ]),
        actions: [
          (counter.value == nextFloor.value) ? IconButton(
            icon: menuIcon(context.menuIconSize()),
            onPressed: () => pressedMenu()
          ): SizedBox(width: context.menuIconSize()),
          const SizedBox(width: 10),
        ]
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(children: [
          Row(children: [
            SizedBox(width: context.sideSpacerWidth()),
            Stack(children: [
              ///Room Image
              Container(
                height: context.roomHeight(),
                margin: EdgeInsets.only(
                  top: context.doorMarginTop(),
                  left: context.doorMarginLeft()
                ),
                child: counter.value.roomImage(floorNumbers, roomImages),
              ),
              ///Door Frame Image
              upAndDownDoorFrame(context),
              ///Left Door Frame Image
              leftDoorFrame(context, isDoorState.value == closedState),
              ///Right Door Frame Image
              rightDoorFrame(context, isDoorState.value == closedState),
              ///Left Door Image
              leftDoorImage(context, isDoorState.value == closedState),
              ///Right Door Image
              rightDoorImage(context, isDoorState.value == closedState),
              ///Elevator Frame Image
              elevatorFrameImage(context),
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
                child: Column(children: [
                  const Spacer(flex: 3),
                  ///Operation Buttons (Alert: 2)
                  Center(child:
                    GestureDetector(
                      onTapDown: pressedButtonAction(true, false)[2],
                      onTapUp: pressedButtonAction(false, false)[2],
                      onLongPress: pressedButtonAction(true, true)[2],
                      onLongPressEnd: pressedButtonAction(false, true)[2],
                      child: operationButtonImage(context, isPressedOperationButtons.value, 2)
                    ),
                  ),
                  SizedBox(height: context.buttonMargin() * 2),
                  ///Floor Buttons
                  Column(children: floorNumbers.floorNumbersList().asMap().entries.map((row) => Column(children: [
                    SizedBox(height: context.buttonMargin()),
                    Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: row.value.asMap().entries.map((floor) => Row(children: [
                        SizedBox(width: context.buttonMargin()),
                        GestureDetector(
                          child: floorButtonImage(context, floor.value, floor.value.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)),
                          onTap: () => floorSelected(floor.value, isFloors[row.key][floor.key]),
                          onLongPress: () => floorCanceled(floor.value),
                          onDoubleTap: () => floorCanceled(floor.value),
                        ),
                        if (floor.key == row.value.length - 1) SizedBox(width: context.buttonMargin()),
                      ])).toList(),
                    ),
                    if (row.key == floorNumbers.length - 1) SizedBox(height: context.buttonMargin()),
                  ])).toList()),
                  SizedBox(height: context.buttonMargin() * 2),
                  ///Operation Buttons (Close: 0, Open: 1)
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [0, 1].expand((i) => [
                      GestureDetector(
                        onTapDown: pressedButtonAction(true, false)[i],
                        onTapUp: pressedButtonAction(false, false)[i],
                        onLongPress: pressedButtonAction(true, true)[i],
                        onLongPressEnd: pressedButtonAction(false, true)[i],
                        child: operationButtonImage(context, isPressedOperationButtons.value, i),
                      ),
                      if (i != 1) SizedBox(width: context.buttonMargin()),
                    ]).toList()
                  ),
                  const Spacer(flex: 1),
                ]),
              ),
            ])
          ]),
          ///Door Cover
          doorCover(context),
          ///Admob Banner
          admobBanner(),
          ///Menu
          if (isMenu) const MyMenuPage(),
          if (isSettings) const MySettingsPage(),
        ]),
      ),
    );
  }
}