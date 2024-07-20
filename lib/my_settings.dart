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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admob_banner.dart';
import 'common_widget.dart';
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

    final selectedRoomImage = useState("");
    final selectedRoomName  = useState("");
    final selectedNumber = useState(0);
    final isButtonOn = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final isImageOn  = useState(List.generate(5, (_) => List.generate(2, (_) => false)));
    final photoPermission = useState(PermissionStatus.permanentlyDenied);

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

    ///Pressed Button
    pressedButton(int row, int col, bool isTap) {
      isButtonOn.value[row][col] = isTap;
      isButtonOn.value = List.from(isButtonOn.value);
      "${isButtonOn.value}".debugPrint();
    }

    ///Pressed Image
    pressedImage(int row, int col, bool isTap) {
      isImageOn.value[row][col] = isTap;
      isImageOn.value = List.from(isImageOn.value);
      "${isImageOn.value}".debugPrint();
    }

    photoPermissionAlert() => showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.photoAccessRequired(),
          style: TextStyle(
            color: blackColor,
            fontSize: context.settingsAlertTitleFontSize(),
            fontFamily: settingsFont,
          ),
        ),
        content: Text(context.photoAccessPermission(),
          style: TextStyle(
              color: blackColor,
              fontSize: context.settingsAlertFontSize(),
              fontFamily: settingsFont,
          ),
        ),
        actions: [
          TextButton(
            child: Text(context.ok(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.settingsAlertSelectFontSize(),
                fontFamily: settingsFont,
                fontWeight: FontWeight.bold
              ),
            ),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            child: Text(context.cancel(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.settingsAlertSelectFontSize(),
                fontFamily: settingsFont,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    pickAndCropImage(int row, int col) async {
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      'Picked image: ${pickedFile?.path}'.debugPrint();
      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 100,
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
      // pressedImage(row, col, false);
    }

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
              if (point < albumImagePoint) alertLockWidget(context),
            ]),
            const Spacer(flex: 1),
          ]),
          ),
      )
    ).then((_) {
      pressedImage(row, col, false);
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
                  fontSize: context.settingsAlertSelectFontSize(),
                  fontFamily: settingsFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                if (!floorNumbers.contains(selectedNumber.value)) {
                  final prefs = await SharedPreferences.getInstance();
                  final newList = List<int>.from(ref.read(floorNumbersProvider));
                  newList[buttonIndex(row, col)] = selectedNumber.value;
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

    settingsLockWidget(int row, int col) => Container(
      color: transpBlackColor,
      width: context.settingsLockWidth(),
      height: context.settingsImageSelectHeight(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lockIcon(context.settingsLockIconSize()),
          Row(children: [
            const Spacer(flex: 1),
            pointIcon(context.settingsLockIconSize()),
            SizedBox(width: context.settingsLockSpaceSize()),
            Text("${changePointList[row][col]}",
              style: TextStyle(
                color: lampColor,
                fontSize: context.settingsLockFontSize(),
                fontWeight: FontWeight.normal,
                fontFamily: numberFont,
              ),
            ),
            const Spacer(flex: 1),
          ]),
        ],
      ),
    );

    ///Settings
    return Scaffold(
      body: Container(
        color: transpColor,
        child:Column(children: [
          const Spacer(flex: 2),
          ///Settings title
          Text(context.settings(),
            style: TextStyle(
              fontSize: context.settingsTitleFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: settingsFont
            ),
          ),
          SizedBox(height: context.settingsTitleMargin()),
          const Spacer(flex: 1),
          Column(children: floorNumbers.floorNumbersList().asMap().entries.map((row) =>
            Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: row.value.asMap().entries.map((col) {
                  final isChange = (point >= changePointList[row.key][col.key]);
                  return Stack(children: [
                    Row(children: [
                      ///Edit Elevator Button
                      Column(children: [
                        SizedBox(
                          width: context.settingsButtonSize(),
                          height: context.settingsButtonSize(),
                          child: GestureDetector(
                            child: Stack(alignment: Alignment.center,
                              children: [
                                Image.asset(isButtonOn.value[row.key][col.key].numberBackground()),
                                Text(col.value.buttonNumber(),
                                  style: TextStyle(
                                    color: (isButtonOn.value[row.key][col.key]).numberColor(),
                                    fontSize: context.settingsButtonNumberFontSize(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isNotSelectFloor(row.key, col.key)) Container(
                                  width: context.settingsButtonSize(),
                                  height: context.settingsButtonSize(),
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
                        SizedBox(height: context.settingsButtonMargin()),
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
                              context.settingsButtonBorderRadius()
                            )),
                          ),
                          child: Container(
                            width: context.settingsButtonWidth(),
                            height: context.settingsButtonHeight(),
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
                                elevation: context.settingsButtonShadowSize(),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(context.edit(),
                                style: TextStyle(
                                  fontFamily: settingsFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.settingsButtonFontSize(),
                                  color: whiteColor,
                                )
                              ),
                            ),
                          ),
                        ),
                      ]),
                      SizedBox(width: context.settingsButtonMargin()),
                      ///Edit Room Image
                      SizedBox(
                        width: context.settingsImageSelectWidth(),
                        height: context.settingsImageSelectHeight(),
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
                      if (col.key == 0) SizedBox(width: context.settingsButtonSpace()),
                    ]),
                    if (!isChange) settingsLockWidget(row.key, col.key)
                  ]);
                }).toList(),
              ),
              SizedBox(height: context.settingsButtonMargin()),
            ]),
          ).toList()),
          const Spacer(flex: 2),
          const AdBannerWidget(),
        ]),
      ),
    );
  }
}