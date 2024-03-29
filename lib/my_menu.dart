import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'admob_banner.dart';
import 'main.dart';

class MyMenuPage extends HookConsumerWidget {
  final bool isHome;
  const MyMenuPage({super.key, required this.isHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final floorNumbers = ref.watch(floorNumbersProvider);
    final roomImages = ref.watch(roomImagesProvider);
    final point = ref.watch(pointProvider);

    final selectedRoomImage = useState("");
    final selectedRoomName  = useState("");
    final selectedNumber = useState(0);
    final isButtonOn = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final isImageOn  = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final isSoundOn = useState(true);
    final photoPermission = useState(PermissionStatus.permanentlyDenied);
    final counter = useState(0);

    final AudioPlayer audioPlayer = AudioPlayer();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        "$floorNumbers".debugPrint();
        "$roomImages".debugPrint();
        "point: $point".debugPrint();
        await audioPlayer.setReleaseMode(ReleaseMode.loop);
        await audioPlayer.setVolume(0.5);
      });
      return null;
    }, []);

    ///Pressed menu button action
    pressedMenu() async {
      selectButton.playAudio(audioPlayer, isSoundOn.value);
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(isMenuProvider.notifier).state = false;
    }

    ///Pressed menu links action
    pressedMenuLink(int i) async {
      pressedMenu();
      launchUrl(Uri.parse(context.menuLinks()[i]));
    }
    // GamesServices.signIn(shouldEnableSavedGame: true);

    ///Pressed Button
    pressedButton(int row, int col, bool isTap) async {
      isButtonOn.value[row][col] = isTap;
      isButtonOn.value = List.from(isButtonOn.value);
      "${isButtonOn.value}".debugPrint();
    }

    ///Pressed Image
    pressedImage(int row, int col, bool isTap) async {
      isImageOn.value[row][col] = isTap;
      isImageOn.value = List.from(isImageOn.value);
      "${isImageOn.value}".debugPrint();
    }

    photoPermissionAlert() => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.photoAccessRequired(),
          style: TextStyle(
            color: blackColor,
            fontSize: context.menuAlertTitleFontSize(),
            fontFamily: menuFont,
          ),
        ),
        content: Text(context.photoAccessPermission(),
          style: TextStyle(
              color: blackColor,
              fontSize: context.menuImageSelectFontSize(),
              fontFamily: menuFont,
          ),
        ),
        actions: [
          TextButton(
            child: Text(context.ok(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.menuImageSelectFontSize(),
                fontFamily: menuFont,
                fontWeight: FontWeight.bold
              ),
            ),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            child: Text(context.cancel(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.menuImageSelectFontSize(),
                fontFamily: menuFont,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    alertLockWidget()  => Container(
      decoration: BoxDecoration(
        color: transpBlackColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(context.menuAlertLockBorderRadius()),
        border: Border.all(
          color: whiteColor,
          width: context.menuAlertLockBorderWidth(),
        ),
      ),
      child: Column(children: [
        SizedBox(height: context.menuAlertLockIconSize() + context.menuAlertLockSpaceSize()),
        Row(children: [
          const Spacer(flex: 1),
          lockIcon(context.menuAlertLockIconSize()),
          SizedBox(width: context.menuAlertLockSpaceSize()),
          pointIcon(context.menuAlertLockIconSize()),
          SizedBox(width: context.menuLockSpaceSize()),
          Text("$albumImagePoint",
            style: TextStyle(
              color: lampColor,
              fontSize: context.menuAlertLockFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont,
            ),
          ),
          const Spacer(flex: 1),
        ]),
      ]),
    );

    pickAndCropImage(int row, int col) async {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      'Picked image: ${pickedFile?.path}'.debugPrint();
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
          aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
          aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: context.cropPhoto(),
              toolbarColor: lampColor,
              toolbarWidgetColor: whiteColor,
              initAspectRatio: CropAspectRatioPreset.ratio16x9,
              lockAspectRatio: true
            ),
            IOSUiSettings(
              title: context.cropPhoto(),
            ),
            WebUiSettings(
              context: context,
            ),
          ],
        );
        if (croppedFile != null) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = path.basename(croppedFile.path);
          final File savedImage = await File(croppedFile.path).copy('${directory.path}/$fileName');
          'Cropped image path: ${croppedFile.path}'.debugPrint();
          final prefs = await SharedPreferences.getInstance();
          final newList = List<String>.from(ref.read(roomImagesProvider));
          newList[buttonIndex(row, col)] = savedImage.path;
          await "roomsKey".setSharedPrefListString(prefs, newList);
          ref.read(roomImagesProvider.notifier).state = newList;
        }
      }
      pressedImage(row, col, false);
    }

    roomPickerDialog(int row, int col) async => await showDialog(
      context: context,
      builder: (context) {
        final Iterable<String> remainIterable = roomImageList.remainIterable(roomImages, buttonIndex(row, col));
        selectedRoomImage.value = roomImageList.selectedRoomImage(roomImages, buttonIndex(row, col));
        selectedRoomName.value = roomImageList.selectedRoomName(context, roomImages, buttonIndex(row, col));
        pressedImage(row, col, true);
        return AlertDialog(
          backgroundColor: transpBlackColor,
          title: Row(children: [
            const Spacer(),
            Text(context.changeImage(),
              style: TextStyle(
                fontSize: context.menuAlertTitleFontSize(),
                fontWeight: FontWeight.bold,
                fontFamily: menuFont,
                color: whiteColor,
              ),
            ),
            const Spacer(),
            ///Close button
            shutButton(context),
          ]),
          content: SizedBox(
            height: context.menuImageSelectAlertHeight(),
            child: Column(children: [
              Container(
                margin: EdgeInsets.all(context.menuDropdownMargin()),
                child: DropdownButton<String>(
                  value: selectedRoomImage.value,
                  onChanged: (String? newValue) async {
                    if (newValue != null) {
                      final prefs = await SharedPreferences.getInstance();
                      selectedRoomImage.value = newValue;
                      selectedRoomName.value = roomImageList.roomName(context, newValue);
                      "Room: ${selectedRoomName.value}: ${selectedRoomImage.value}".debugPrint();
                      final newList = List<String>.from(ref.read(roomImagesProvider));
                      newList[buttonIndex(row, col)] = selectedRoomImage.value;
                      await "roomsKey".setSharedPrefListString(prefs, newList);
                      ref.read(roomImagesProvider.notifier).state = newList;
                    }
                    pressedImage(row, col, false);
                    context.popPage();
                  },
                  items: remainIterable.map((image) => DropdownMenuItem<String>(
                    value: image,
                    child: Text(roomImageList.roomName(context, image),
                      style: TextStyle(
                        fontSize: context.menuDropdownFontSize(),
                        fontFamily: menuFont,
                        color: whiteColor,
                      ),
                    ),
                  )).toList(),
                  dropdownColor: transpBlackColor,
                ),
              ),
              const Spacer(flex: 1),
              Stack(children: [
                GestureDetector(
                  child: Container(
                    margin: EdgeInsets.all(context.menuAlertLockSpaceSize()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_outlined,
                          color: whiteColor,
                          size: context.menuIconSize(),
                          semanticLabel: context.selectPhoto(),
                        ),
                        SizedBox(width: context.menuAlertIconMargin()),
                        Text(context.selectPhoto(),
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: context.menuImageSelectFontSize(),
                            fontFamily: menuFont,
                          ),
                        ),
                      ]
                    ),
                  ),
                  onTap: () async {
                    photoPermission.value = await Permission.photos.status;
                    "photoPermission: ${photoPermission.value}";
                    if (Platform.isAndroid || photoPermission.value.isGranted) {
                      pickAndCropImage(row, col);
                    } else if (photoPermission.value.isDenied) {
                      photoPermission.value = await Permission.photos.request();
                    } else {
                      photoPermissionAlert();
                    }
                  }
                ),
                if (!isAllFree && (point < albumImagePoint)) alertLockWidget(),
              ]),
              const Spacer(flex: 1),
            ]),
          ),
        );
      }
    ).then((_) {
      pressedImage(row, col, false);
    });

    floorInputDialog(int row, int col) async => await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: transpBlackColor,
        title: Text(context.changeNumberTitle(isBasement(row, col)),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.menuAlertTitleFontSize(),
            fontWeight: FontWeight.bold,
            fontFamily: menuFont,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          height: context.menuFloorNumberAlertHeight(),
          child: CupertinoPicker(
            itemExtent: context.menuAlertSelectNumberSize(),
            scrollController: FixedExtentScrollController(
              initialItem: isBasement(row, col).selectInitialIndex(floorNumbers,buttonIndex(row, col))
            ),
            onSelectedItemChanged: (int index) {
              selectedNumber.value = isBasement(row, col).selectedFloorNumber(index); // 選択された数字を更新
              "${selectedNumber.value}".debugPrint();
            },
            children: List.generate(isBasement(row, col).selectDiffFloor(floorNumbers, buttonIndex(row, col)), (int index) =>
              Text('${index + isBasement(row, col).selectFirstFloor(floorNumbers, buttonIndex(row, col))}',
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.menuAlertSelectNumberSize(),
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
                  fontSize: context.menuImageSelectFontSize(),
                  fontFamily: menuFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                context.popPage();
                pressedButton(row, col, false);
              }
            ),
            const Spacer(flex: 2),
            TextButton(
              child: Text(context.ok(),
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.menuImageSelectFontSize(),
                  fontFamily: menuFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                if (!floorNumbers.contains(selectedNumber.value)) {
                  final prefs = await SharedPreferences.getInstance();
                  final newList = List<int>.from(ref.read(floorNumbersProvider));
                  newList[buttonIndex(row, col)] = selectedNumber.value + isBasement(row, col).selectFirstFloor(floorNumbers, buttonIndex(row, col)) - 1;
                  await "floorsKey".setSharedPrefListInt(prefs, newList);
                  ref.read(floorNumbersProvider.notifier).state = newList;
                }
                pressedButton(row, col, false);
                pressedImage(row, col, true);
                context.popPage();
                await roomPickerDialog(row, col);
              }
            ),
            const Spacer(flex: 1),
          ]),
        ]
      ),
    ).then((_) {
      pressedButton(row, col, false);
    });

    menuLockWidget(int row, int col) => Container(
      color: transpBlackColor,
      width: context.menuLockWidth(),
      height: context.menuImageHeight(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lockIcon(context.menuLockIconSize()),
          Row(children: [
            const Spacer(flex: 1),
            pointIcon(context.menuLockIconSize()),
            SizedBox(width: context.menuLockSpaceSize()),
            Text("${changePointList[row][col]}",
              style: TextStyle(
                color: lampColor,
                fontSize: context.menuLockFontSize(),
                fontWeight: FontWeight.normal,
                fontFamily: numberFont,
              ),
            ),
            const Spacer(flex: 1),
          ]),
        ],
      ),
    );

    ///Menu
    return Scaffold(
      body: Container(
        color: transpColor,
        child:Column(children: [
          const Spacer(flex: 2),
          GestureDetector(
            onTap: () async {
              counter.value++;
              "${counter.value}".debugPrint();
              if (counter.value == 30) {
                ref.read(pointProvider.notifier).state = 100000;
                "${ref.read(pointProvider.notifier).state}".debugPrint();
              }
            },
            child: Text(context.settings(),
              style: TextStyle(
                fontSize: context.menuTitleFontSize(),
                fontWeight: FontWeight.bold,
                fontFamily: menuFont
              ),
            ),
          ),
          SizedBox(height: context.menuButtonBottomMargin()),
          const Spacer(flex: 1),
          Column(children: floorNumbers.floorNumbersList().asMap().entries.map((row) =>
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: row.value.asMap().entries.map((col) {
                  final isChange = (isAllFree || (point >= changePointList[row.key][col.key]));
                  return Stack(children: [
                    Row(children: [
                    ///Edit Elevator Button
                      Column(children: [
                        SizedBox(
                          width: context.menuButtonSize(),
                          height: context.menuButtonSize(),
                          child: GestureDetector(
                            child: Stack(alignment: Alignment.center,
                              children: [
                                Image.asset(isButtonOn.value[row.key][col.key].numberBackground()),
                                Text(col.value.buttonNumber(),
                                  style: TextStyle(
                                    color: (isButtonOn.value[row.key][col.key]).numberColor(),
                                    fontSize: context.menuButtonFontSize(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isNotSelectFloor(row.key, col.key)) Container(
                                  width: context.menuButtonSize(),
                                  height: context.menuButtonSize(),
                                  color: transpBlackColor,
                                ),
                              ],
                            ),
                            onTap: () => {
                              isNotSelectFloor(row.key, col.key) ?
                                pressedImage(row.key, col.key, true):
                                pressedButton(row.key, col.key, true),
                              isNotSelectFloor(row.key, col.key) ?
                                roomPickerDialog(row.key, col.key):
                                floorInputDialog(row.key, col.key),
                            },
                          ),
                        ),
                        SizedBox(height: context.menuEditButtonMargin()),
                        Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                isButtonOn.value[row.key][col.key] ? lampColor: blackColor,
                                isButtonOn.value[row.key][col.key] ? lampColor: grayColor
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(
                              context.menuEditBorderRadius()
                            )),
                          ),
                          child: Container(
                            width: context.menuEditButtonWidth(),
                            height: context.menuEditButtonHeight(),
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                (isNotSelectFloor(row.key, col.key)) ?
                                  pressedImage(row.key, col.key, true):
                                  pressedButton(row.key, col.key, true);
                                (isNotSelectFloor(row.key, col.key)) ?
                                  roomPickerDialog(row.key, col.key):
                                  floorInputDialog(row.key, col.key);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: transpColor,
                                foregroundColor: transpColor,
                                shadowColor: blackColor,
                                elevation: context.menuEditShadowSize(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(context.edit(),
                                style: TextStyle(
                                  fontFamily: menuFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.menuEditFontSize(),
                                  color: whiteColor,
                                )
                              ),
                            ),
                          ),
                        ),
                      ]),
                      SizedBox(width: context.menuButtonMargin()),
                      ///Edit Room Image
                      SizedBox(
                        width: context.menuImageWidth(),
                        height: context.menuImageHeight(),
                        child:  GestureDetector(
                          child: Stack(children:[
                            roomImages.roomsList()[row.key][col.key].roomImage(),
                            if (isImageOn.value[row.key][col.key] && isChange) Container(color: transpLampColor),
                          ]),
                          onTap: () {
                            pressedImage(row.key, col.key, true);
                            roomPickerDialog(row.key, col.key);
                          }
                        ),
                      ),
                      if (col.key == 0) SizedBox(width: context.menuButtonMargin() * 2),
                    ]),
                    if (!isChange) menuLockWidget(row.key, col.key)
                  ]);
                }).toList(),
              ),
              SizedBox(height: context.menuButtonBottomMargin()),
            ]),
          ).toList()),
          if (Platform.isAndroid) const Spacer(flex: 2),
          ///Menu Links
          if (Platform.isAndroid) Row(children: [
            const Spacer(flex: 1),
            ...List.generate(context.menuLogos().length, (i) => Container(
              width: context.menuLogoSize(),
              margin: EdgeInsets.symmetric(horizontal: context.menuLogoMargin()),
              child: GestureDetector(
                onTap: () => pressedMenuLink(i),
                child: Image.asset(context.menuLogos()[i]),
              ),
            )),
            const Spacer(flex: 1),
          ]),
          const Spacer(flex: 2),
          const AdBannerWidget(),
        ]),
      ),
    );
  }
}