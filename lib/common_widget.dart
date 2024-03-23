import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'admob_banner.dart';
import 'constant.dart';
import 'extension.dart';
import 'main.dart';

///Icon
//Menu Icon
Icon menuIcon(double size) =>
    Icon(Icons.menu, color: whiteColor, size: size);
//EV Mileage Icon
Widget pointIcon(double size) =>
    Image.asset(pointImage, height: size);
//Lock Icon
Icon lockIcon(double size) =>
    Icon(CupertinoIcons.lock_fill, color: lampColor, size: size,);

///Image
//UpAndDownDoorFrame
Container upAndDownDoorFrame(BuildContext context) =>
    Container(
      alignment: Alignment.centerLeft,
      height: context.roomHeight(),
      margin: EdgeInsets.only(
          top: context.doorMarginTop(),
          left: context.doorMarginLeft()
      ),
      child: Image.asset(doorFrame),
    );

//LeftDoorFrame
AnimatedContainer leftDoorFrame(BuildContext context, bool isClosedState) =>
    AnimatedContainer(
      duration: const Duration(seconds: 2),
      transform: Matrix4.translationValues(isClosedState ? 0: - context.doorWidth(), 0, 0),
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
AnimatedContainer rightDoorFrame(BuildContext context, bool isClosedState) =>
    AnimatedContainer(
      duration: const Duration(seconds: 2),
      transform: Matrix4.translationValues(isClosedState ? 0: context.doorWidth(), 0, 0),
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
AnimatedContainer leftDoorImage(BuildContext context, bool isClosedState) =>
    AnimatedContainer(
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
      child: Image.asset(leftDoor),
    );

//RightDoor
AnimatedContainer rightDoorImage(BuildContext context, bool isClosedState) =>
    AnimatedContainer(
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
      child: Image.asset(rightDoor),
    );

//Elevator Frame
Container elevatorFrameImage(BuildContext context) =>
    Container(
      alignment: Alignment.topCenter,
      width: context.elevatorWidth() ,
      height: context.elevatorHeight(),
      child: Image.asset(elevatorFrame)
    );
//DoorCover
Row doorCover(BuildContext context) =>
    Row(children: [
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

///Button
//Open or Close Button (Close: 0, Open: 1, Alert:2)
Container operationButtonImage(BuildContext context, List<bool> isPressedList, int number) =>
    Container(
      width: context.operationButtonSize() + 2 * context.buttonBorderWidth(),
      height: context.operationButtonSize() + 2 * context.buttonBorderWidth(),
      decoration: BoxDecoration(
        color: transpColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(context.buttonBorderRadius()),
        border: Border.all(
          color: (number == 1) ? whiteColor: (number == 2) ? yellowColor: greenColor,
          width: context.buttonBorderWidth(),
        ),
      ),
      child: Image.asset(isPressedList.operateBackGround()[number]),
    );
//Floor Button
SizedBox floorButtonImage(BuildContext context, int floorNumber, bool isSelected) =>
    SizedBox(
      width: context.floorButtonSize(),
      height: context.floorButtonSize(),
      child: Stack(alignment: Alignment.center,
        children: [
          Image.asset(isSelected.numberBackground()),
          Text(floorNumber.buttonNumber(),
            style: TextStyle(
              color: isSelected ? lampColor: whiteColor,
              fontSize: context.buttonNumberFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

///Admob Banner
Center admobBanner() =>
    const Center(child:
      Column(children: [
        Spacer(),
        if (isShowAds) AdBannerWidget(),
      ]),
    );

///About EV Mileage Tooltip
Container evMileTooltip(BuildContext context) => Container(
  height: 40,
  alignment: Alignment.topCenter,
  margin: const EdgeInsets.only(left: 5),
  child: Tooltip(
    richMessage: TextSpan(
      text: context.eVMile(),
      style: const TextStyle(
        color: lampColor,
        fontWeight: FontWeight.bold,
        fontFamily: menuFont,
        height: 2.4,
        decoration: TextDecoration.underline,
        decorationColor: whiteColor,
        fontSize: 20,
      ),
      children: <TextSpan>[
        TextSpan(
          text: context.aboutEVMile(),
          style: const TextStyle(
            color: whiteColor,
            fontStyle: FontStyle.normal,
            fontFamily: menuFont,
            height: 1.5,
            decoration: TextDecoration.none,
            fontSize: 16,
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.all(20), //吹き出しのpadding
    margin: const EdgeInsets.all(20), //吹き出しのmargin
    verticalOffset: 15, //childのwidget２ら垂直方向にどれだけ離すか
    preferBelow: true, //メッセージを子widgetの上に出すか下に出すか
    decoration: const BoxDecoration(
      color: transpBlackColor,
      borderRadius: BorderRadius.all(Radius.circular(20))
    ),//吹き出しの形や色の調整
    showDuration: const Duration(milliseconds: toolTipTime),
    triggerMode: TooltipTriggerMode.tap,
    enableFeedback: true,
    child: const Icon(CupertinoIcons.question_circle,
      color: Colors.white,
      size: 15,
    ),
  ),
);

///Close Button
GestureDetector shutButton(BuildContext context) =>
    GestureDetector(
      onTap: () => context.popPage(),
      child: Icon(Icons.close,
        size: context.menuAlertTitleFontSize(),
        color: whiteColor,
      ),
    );
