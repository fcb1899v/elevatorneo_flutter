// =============================
// HomePage: Main elevator simulation interface
//
// This file contains the main UI and logic for the elevator simulator.
// It manages elevator movement, door states, button interactions, and user interface.
// Key features:
// - Elevator movement simulation with realistic timing
// - Door state management (opening, closing, opened, closed)
// - Floor button selection and deselection
// - Operation button controls (open, close, emergency)
// - View switching between inside and outside elevator
// - TTS announcements and sound effects
// - Score tracking and game integration
// =============================

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admob_banner.dart';
import 'games_manager.dart';
import 'audio_manager.dart';
import 'tts_manager.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'image_manager.dart';
import 'main.dart';
import 'menu.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- Provider State Management ---
    // Riverpod providers for managing app state across the application
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

    // --- Hooks State Management ---
    // Local state management using Flutter Hooks for reactive UI updates
    final counter = useState(initialFloor);                    // Current elevator position
    final currentFloor = useState(1);                          // Target floor for outside view
    final nextFloor = useState(initialFloor);                  // Next destination floor
    final isOutside = useState(true);                          // View mode (inside/outside elevator)
    final isMoving = useState(false);                          // Elevator movement state
    final isEmergency = useState(false);                       // Emergency mode state
    final isDoorState = useState(closedState);                 // Door state: [opened, closed, opening, closing]
    final isPressedOperationButtons = useState([false, false, false]); // Operation button states: [open, close, alert]
    final isAboveSelectedList = useState(List.generate(max + 1, (_) => false)); // Floor button selections (above ground)
    final isUnderSelectedList = useState(List.generate(min * (-1) + 1, (_) => false)); // Floor button selections (basement)
    final isLoadingData = useState(false);                     // Data loading state
    final imageTopMargin = useState(0.0);                      // Image positioning for elevator movement
    final imageDurationTime = useState(0);                     // Animation duration for movement
    final isWaitingUp = useState(false);                       // Up button waiting state
    final isWaitingDown = useState(false);                     // Down button waiting state
    final nextDirection = useState("none");                    // Next direction of elevator movement (up, down)
    final waitTime = useState(initialWaitTime);                // Wait time between actions
    final openTime = useState(initialOpenTime);                // Door open duration
    final animationController = useAnimationController(duration: Duration(milliseconds: flashTime))..repeat(reverse: true);
    final lifecycle = useAppLifecycleState();                  // App lifecycle state
    final orientation = context.orientation();                 // Screen orientation

    // --- Manager Instances ---
    // Service managers for handling various app functionalities
    final imageManager = useMemoized(() => ImageManager());
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());
    final gamesManager = useMemoized(() => GamesManager(
      isGamesSignIn: false,
      isConnectedInternet: false
    ));

    // --- Widget Instances ---
    // UI widget instances for rendering the interface
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

    // --- Initial Data Loading Effect ---
    // Load initial data when the widget is first created
    useEffect(() {

      Future<void> gamesInit() async {
        final hasInternet = await gamesManager.checkInternetConnection();
        final updatedGamesManager = GamesManager(
            isGamesSignIn: false,
            isConnectedInternet: hasInternet
        );
        final signedIn = await updatedGamesManager.gamesSignIn();
        final reUpdatedGamesManager = GamesManager(
            isGamesSignIn: isGamesSignIn,
            isConnectedInternet: hasInternet
        );
        final bestScore = await reUpdatedGamesManager.getBestScore();
        ref.read(internetProvider.notifier).state = hasInternet;
        ref.read(gamesSignInProvider.notifier).state = signedIn;
        ref.read(pointProvider.notifier).state = bestScore;
      }

      Future<void> initState() async {
        isLoadingData.value = true;
        try {
          if (!isGamesSignIn) gamesInit();
          final images = await imageManager.getImagesList();
          ref.read(floorImagesProvider.notifier).state = images;
          if (context.mounted) {
            imageTopMargin.value = context.imageMarginTop(isOutside.value, counter.value, max);
          }
          await ttsManager.initTts();
        } catch (e) {
          "Error: $e".debugPrint();
        } finally {
          isLoadingData.value = false;
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async => await initState(),);
      return null;
    }, []);


    // --- Orientation Change Effect ---
    // Handle screen orientation changes and update UI accordingly
    useEffect(() {
      debugPrint('orientation changed: $orientation');
      isLoadingData.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) imageTopMargin.value = context.imageMarginTop(isOutside.value, counter.value, max);
      });
      Future.delayed(Duration(seconds: waitTime.value)).then((_) {
        if (context.mounted) isLoadingData.value = false;
      });
      return null;
    }, [orientation]);

    // --- App Lifecycle Effect ---
    // Handle app lifecycle changes (pause, resume) to stop audio and TTS
    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          audioManager.stopAudio();
          ttsManager.stopTts();
        }
      }
      return null;
    }, [lifecycle]);

    // --- Elevator Movement Functions ---
    // Functions for controlling elevator movement and navigation logic

    /// Move elevator upward to the next selected floor
    /// Handles floor-by-floor movement with realistic timing and animations
    counterUp() async {
      await ttsManager.speakText(context.upFloor(), !isOutside.value || currentFloor.value == counter.value);
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
              if (context.mounted) imageTopMargin.value = context.imageMarginTop(isOutside.value, counter.value, max);
              await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
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
                if (!isOutside.value || currentFloor.value == counter.value) await audioManager.playEffectSound(asset: openSound, volume: 0.6);
                if (context.mounted) await ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, floorImages)), !isOutside.value || currentFloor.value == counter.value);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              });
            }
          });
        });
      });
    }

    /// Move elevator downward to the next selected floor
    /// Handles floor-by-floor movement with realistic timing and animations
    counterDown() async {
      await ttsManager.speakText(context.downFloor(), !isOutside.value || currentFloor.value == counter.value);
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
              if (context.mounted) imageTopMargin.value = context.imageMarginTop(isOutside.value, counter.value, max);
              await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
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
                if (!isOutside.value || currentFloor.value == counter.value) await audioManager.playEffectSound(asset: openSound, volume: 0.6);
                if (context.mounted) await ttsManager.speakText(context.openingSound(counter.value, counter.value.roomImageFile(floorNumbers, floorImages)), !isOutside.value || currentFloor.value == counter.value);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              });
            }
          });
        });
      });
    }

    // --- Button Interaction Functions ---
    // Functions for handling user interactions with floor and operation buttons

    /// Handle floor button selection and deselection
    /// Manages floor button states and triggers elevator movement
    floorSelected(int i, bool selectFlag) async {
      isPressedOperationButtons.value = [false, false, false];
      await audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (!isEmergency.value) {
        if (i == counter.value) {
          if (!isMoving.value && i == nextFloor.value && context.mounted) await ttsManager.speakText(context.pushNumber(), true);
        } else if (!selectFlag) {
          if (context.mounted) await ttsManager.speakText(context.notStop(), true);
        } else if (!i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value)) {
          i.trueSelected(isAboveSelectedList.value, isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(isAboveSelectedList.value, isUnderSelectedList.value)) {
            nextFloor.value = i;
            if (!isOutside.value) nextDirection.value = (counter.value < nextFloor.value) ? "up": "down";
          }
          "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
          await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              (counter.value < nextFloor.value) ? counterUp() :
              (counter.value > nextFloor.value) ? counterDown() :
              (context.mounted) ? await ttsManager.speakText(context.pushNumber(), !isOutside.value || currentFloor.value == counter.value): null;
            }
          });
        }
      }
    }

    /// Handle floor button deselection
    /// Removes floor from selection and recalculates next destination
    floorCanceled(int i) async {
      isPressedOperationButtons.value = [false, false, false];
      if (i.isSelected(isAboveSelectedList.value, isUnderSelectedList.value) && i != nextFloor.value) {
        await audioManager.playEffectSound(asset: cancelSound, volume: 0.8);
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

    // --- Door Control Functions ---
    // Functions for managing elevator door states and operations

    /// Open elevator doors and trigger movement if needed
    /// Handles door opening animation and subsequent elevator movement
    doorsOpening() async {
      if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
        if (context.mounted && currentFloor.value == counter.value) await ttsManager.speakText(context.openDoor(), !isOutside.value || currentFloor.value == counter.value);
        isDoorState.value = openingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openingState) {
            isDoorState.value = openedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
          }
        });
      }
    }

    /// Close elevator doors and trigger movement if needed
    /// Handles door closing animation and subsequent elevator movement
    doorsClosing() async {
      if (isWaitingUp.value || isWaitingDown.value) floorSelected(currentFloor.value, true);
      if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
        if (!isOutside.value || currentFloor.value == counter.value) await audioManager.playEffectSound(asset: closeSound, volume: 0.6);
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        if (context.mounted) await ttsManager.speakText(context.closeDoor(), !isOutside.value || currentFloor.value == counter.value);
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            (counter.value < nextFloor.value) ? counterUp():
            (counter.value > nextFloor.value) ? counterDown():
            (context.mounted) ? await ttsManager.speakText(context.pushNumber(), !isOutside.value || currentFloor.value == counter.value): null;
            if (isOutside.value && counter.value != nextFloor.value && !isWaitingDown.value & !isWaitingUp.value) nextDirection.value = "none";
          }
        });
      }
    }

    // --- Operation Button Functions ---
    // Functions for handling operation button interactions (open, close, emergency)
    /// Handle open button press with delayed action and TTS feedback
    pressedOpenAction(bool isOn) async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      if (!isMoving.value) {
        isPressedOperationButtons.value = [isOn, false, false];
        if (isOn) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) async {
              doorsOpening();
            });
          }
        }
      } else {
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    /// Handle close button press with delayed door closing action
    pressedCloseAction(bool isOn) async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(asset: selectSound, volume: 0.8);
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

    /// Handle emergency button press with long press detection for emergency mode
    /// Triggers emergency procedures when elevator is far from current floor
    pressedAlertAction(bool isOn, isLongPressed) async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      await audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      isPressedOperationButtons.value = [false, false, isOn];
      if (isOn && ((currentFloor.value - counter.value).abs() > 5) && ((nextFloor.value - counter.value).abs() > 5)) {
        if (isLongPressed) {
          if (isMoving.value) isEmergency.value = true;
          if (isEmergency.value && isMoving.value) {
            await audioManager.playEffectSound(asset: callSound, volume: 1.0);
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
              if (context.mounted) await ttsManager.speakText(context.emergency(), !isOutside.value || currentFloor.value == counter.value);
              nextFloor.value = counter.value;
              isMoving.value = false;
              isEmergency.value = true;
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
            });
            await Future.delayed(Duration(seconds: openTime.value)).then((_) async {
              if (context.mounted) await ttsManager.speakText(context.return1st(), !isOutside.value || currentFloor.value == counter.value);
            });
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
              if (counter.value != 1) {
                nextFloor.value = 1;
                "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                (counter.value < nextFloor.value) ? counterUp() : counterDown();
              } else {
                if (context.mounted && currentFloor.value == counter.value) await ttsManager.speakText(context.openDoor(), !isOutside.value || currentFloor.value == counter.value);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              }
            });
          }
        }
      }
    }

    // --- View Control Functions ---
    // Functions for managing view switching and waiting button interactions
    /// Switch between inside and outside elevator views
    /// Adjusts image positioning and view state
    changeView() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      isPressedOperationButtons.value = [false, false, false];
      isOutside.value = !isOutside.value;
      "isOutside: ${isOutside.value}".debugPrint();
      if (counter.value != nextFloor.value) nextDirection.value = (counter.value < nextFloor.value) ? "up": "down";
      if (context.mounted) {
        imageTopMargin.value += (isOutside.value) ? - context.changeMarginTop() : context.changeMarginTop();
      }
    }

    /// Handle up waiting button press for outside view
    /// Manages elevator call logic and door states
    pressedWaitUp() {
      if (counter.value != currentFloor.value) {
        isWaitingUp.value = true;
        if (nextDirection.value == "none") nextDirection.value = "up";
        "pressedWaitUp: ${isWaitingDown.value}".debugPrint();
        if (isDoorState.value == openingState || isDoorState.value == openedState) {
          pressedCloseAction(true);
        } else {
          doorsClosing();
        }
      } else {
        doorsOpening();
      }
    }

    /// Handle down waiting button press for outside view
    /// Manages elevator call logic and door states
    pressedWaitDown() {
      if (counter.value != currentFloor.value) {
        isWaitingDown.value = true;
        if (nextDirection.value == "none") nextDirection.value = "down";
        "pressedWaitDown: ${isWaitingDown.value}".debugPrint();
        if (isDoorState.value == openingState || isDoorState.value == openedState) {
          pressedCloseAction(true);
        } else {
          doorsClosing();
        }
      } else {
        doorsOpening();
      }
    }

    // --- Button Action Management ---
    // Helper functions for managing button interactions and effects
    /// Generate button action list for operation buttons
    /// Returns appropriate action handlers based on button state and press type
    List<dynamic> pressedButtonAction(bool isOn, isLongPressed) => [
      (isOn && isLongPressed) ? () => pressedOpenAction(isOn): (_) => pressedOpenAction(isOn),
      (isOn && isLongPressed) ? () => pressedCloseAction(isOn): (_) => pressedCloseAction(isOn),
      (isOn && isLongPressed) ? () => pressedAlertAction(isOn, isLongPressed): (_) => pressedAlertAction(isOn, isLongPressed),
    ];

    // --- Door State Management Effect ---
    // Automatic door state management and timing adjustments
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

    /// Handle menu button press with vibration feedback
    Future<void> pressedMenu() async {
      await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).state = await isMenu.pressedMenu();
    }

    // --- UI Rendering ---
    // Main UI structure with all elevator components and interactions
    return Scaffold(
      backgroundColor: blackColor,
      /// App bar with menu button and point display
      appBar: home.homeAppBar(onPressed: () => pressedMenu()),
      /// Main body with elevator interface
      body: SafeArea(
        top: true,
        bottom: true,
        child: Stack(children: [
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 1.5,
            child: Stack(children: [
              /// Background room images with elevator movement animation
              home.floorImagesWidget(
                currentFloorNumber: currentFloor.value,
                isOutside: isOutside.value,
                margin: imageTopMargin.value,
                duration: imageDurationTime.value,
              ),
              /// Black overlay for hiding elevator during emergency
              home.blackHideWidget(isEmergency.value),
              /// Main elevator structure with doors and buttons
              Row(children: [
                SizedBox(width: context.sideSpacerWidth()),
                Stack(children: [
                  /// Door frame images for visual structure
                  home.upAndDownDoorFrame(),
                  /// Left door frame with conditional visibility
                  home.leftDoorFrame(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  /// Right door frame with conditional visibility
                  home.rightDoorFrame(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  /// Left door image with animation states
                  home.leftDoorImage(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  /// Right door image with animation states
                  home.rightDoorImage(isDoorState.value == closedState || (isDoorState.value != closedState && isOutside.value && currentFloor.value != counter.value)),
                  /// Main elevator frame image
                  home.elevatorFrameImage(isOutside.value),
                  /// Button panel with display and controls
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
                        /// Floor display with movement indicators
                        (!isOutside.value) ? home.displayNumberWidget(
                          number: counter.value,
                          next: nextFloor.value,
                          isMoving: isMoving.value,
                        /// Hall lamp indicating elevator direction
                        ): (counter.value != currentFloor.value) ? home.hallLampLightingWidget(
                          number: counter.value,
                          current: currentFloor.value,
                          nextDirection: nextDirection.value,
                        ): home.hallLampFlashingWidget(
                          animationController: animationController,
                          isDoorState: isDoorState.value,
                          nextDirection: nextDirection.value,
                        ),
                        Spacer(),
                        /// Emergency button (style 2 configuration)
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
                        /// Floor button matrix with selection handling
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
                        /// Operation buttons (close and open)
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
                        /// Emergency button (style 2 configuration - alternative position)
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
                        /// Up and down buttons for outside view
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
                  /// View change button (flashing indicator)
                  if (isDoorState.value == openedState && currentFloor.value == counter.value) GestureDetector(
                    onTap: changeView,
                    child: Container(
                      margin: EdgeInsets.only(
                        top: context.changeViewMarginTop(),
                        left: context.changeViewMarginLeft(),
                      ),
                      child: common.flashButton(
                        animationController: animationController,
                        isUp: true,
                      ),
                    )
                  )
                ])
              ]),
              /// Door cover for visual effects
              home.doorCover()
            ]),
          ),
          /// Menu overlay when menu is active
          if (isMenu) const MenuPage(),
          /// AdMob banner at bottom of screen
          if (!isTest) const AdBannerWidget(),
          /// Loading indicator during data initialization
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]),
      ),
    );
  }
}

// =============================
// HomeWidget: Main elevator UI components
//
// Contains all UI widgets for the elevator simulator interface.
// Key features: app bar, floor images, doors, hall lamps, displays, buttons
// =============================
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

  // --- App Bar Components ---
  /// App bar with score display and menu button
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
  /// Tooltip explaining EV mileage system
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
              fontFamily: context.font(),
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
              fontFamily: context.font(),
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

  // --- Floor and Room Images ---
  /// Animated floor images for inside/outside elevator views
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

  /// Black overlay for emergency mode and hiding elements
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
  // --- Door Components ---
  /// Door frame for up/down buttons
  Container upAndDownDoorFrame() => Container(
    alignment: Alignment.centerLeft,
    height: context.roomHeight(),
    margin: EdgeInsets.only(
        top: context.upDownDoorMarginTop(),
        left: context.doorMarginLeft()
    ),
    child: Image.asset(backgroundStyle.doorFrame()),
  );
  /// Animated left door frame
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
  /// Animated right door frame
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

  /// Animated left door with glass style
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
  /// Animated right door with glass style
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
  /// Elevator frame for inside/outside views
  Container elevatorFrameImage(bool isOutside) => Container(
    alignment: Alignment.topCenter,
    width: context.elevatorWidth() ,
    height: context.elevatorHeight(),
    child: Image.asset(backgroundStyle.elevatorFrame(isOutside))
  );
  /// Door cover panels for hiding elevator sides
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

  // --- Hall Lamp Components ---
  /// Static hall lamp showing elevator direction
  SizedBox hallLampLightingWidget({
    required int number,
    required int current,
    required String nextDirection,
  }) => SizedBox(
    height: context.hallLampHeight(),
    child: Image.asset( 
      (nextDirection == "up") ? hallLampUp:
      (nextDirection == "down") ? hallLampDown:
      hallLampOff
    )
  );
  /// Flashing hall lamp with animation control
  SizedBox hallLampFlashingWidget({
    required AnimationController animationController,
    required List<bool> isDoorState,
    required String nextDirection,
  }) => SizedBox(
    height: context.hallLampHeight(),
    child: AnimatedBuilder(
      animation: animationController,
      builder: (context, child) => Image.asset(
        (animationController.value < 0.5 || isDoorState == closedState) ? hallLampOff:
        (nextDirection == "up") ? hallLampUp: hallLampDown,
      ),
    ),
  );

  // --- Display Components ---
  /// Floor display with arrow and number
  Container displayNumberWidget({
    required int number,
    required int next,
    required bool isMoving,
  }) => Container(
    width: context.displayWidth(),
    height: context.displayHeight(),
    color: displayBackgroundColor[buttonStyle],
    child: Column(mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ///Arrow
        Container(
          height: context.displayArrowHeight(buttonStyle),
          alignment: Alignment.topCenter,
          margin: EdgeInsets.only(top: context.displayArrowMarginTop(buttonStyle)),
          child: Image.asset(number.arrowImage(isMoving, next, buttonStyle)),
        ),
        ///Floor number
        displayNumber(number),
      ]
    )
  );
  /// Floor number display with custom fonts
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

  // --- Button Components ---
  /// Operation buttons (open, close, emergency)
  Widget operationButton(List<bool> isPressedList, int number) => Container(
    width: context.operationButtonSize(),
    height: context.operationButtonSize(),
    margin: EdgeInsets.only(top: context.operationButtonMargin()),
    child: Image.asset(isPressedList.operationButtonImage(buttonStyle)[number]),
  );
  /// Floor selection buttons with number display
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
              fontFamily: "roboto",
            ),
          ),
        ),
      ],
    ),
  );
  /// Up/down call buttons for elevator
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

