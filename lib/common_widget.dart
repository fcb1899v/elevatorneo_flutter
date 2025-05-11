import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'constant.dart';
import 'extension.dart';

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
Container upAndDownDoorFrame(BuildContext context, String elevatorStyle) =>
    Container(
      alignment: Alignment.centerLeft,
      height: context.roomHeight(),
      margin: EdgeInsets.only(
          top: context.doorMarginTop(),
          left: context.doorMarginLeft()
      ),
      child: Image.asset(elevatorStyle.doorFrame()),
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
AnimatedContainer leftDoorImage(BuildContext context, String elevatorStyle, String glassStyle, bool isClosedState) =>
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
      child: Image.asset(elevatorStyle.leftDoor(glassStyle)),
    );

//RightDoor
AnimatedContainer rightDoorImage(BuildContext context, String elevatorStyle, String glassStyle, bool isClosedState) =>
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
      child: Image.asset(elevatorStyle.rightDoor(glassStyle)),
    );

//Elevator Frame
Container elevatorFrameImage(BuildContext context, String elevatorStyle) =>
    Container(
      alignment: Alignment.topCenter,
      width: context.elevatorWidth() ,
      height: context.elevatorHeight(),
      child: Image.asset(elevatorStyle.elevatorFrame())
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

///Display
Container displayNumber(BuildContext context, int counter, bool isMoving, int nextFloor) =>
    Container(
        width: context.displayWidth(),
        height: context.displayHeight(),
        margin: EdgeInsets.only(
            top: context.displayMarginTop(),
            left: context.displayMarginLeft()
        ),
        color: darkBlackColor,
        child: Row(children: [
          const Spacer(),
          ///Arrow
          displayArrow(context, counter.arrowImage(isMoving, nextFloor)),
          ///Floor number
          Container(
            alignment: Alignment.topRight,
            width: context.displayNumberWidth(),
            height: context.displayNumberHeight(),
            child: useMemoized(() => HookBuilder(
              builder: (context) => Text(counter.displayNumber(),
                style: TextStyle(
                  color: lampColor,
                  fontSize: context.displayNumberFontSize(),
                  fontWeight: FontWeight.normal,
                  fontFamily: numberFont,
                ),
              ),
            ), [counter]),
          ),
          const Spacer(),
        ])
    );

Container displayArrow(BuildContext context, String arrowImage) =>
    Container(
      margin: EdgeInsets.only(left: context.displayArrowMargin()),
      width: context.displayArrowWidth(),
      height: context.displayArrowHeight(),
      child: Image.asset(arrowImage),
    );


///Button
//Open or Close Button (Close: 0, Open: 1, Alert:2)
SizedBox operationButton(BuildContext context, int styleNumber, List<bool> isPressedList, int number) =>
    SizedBox(
      width: context.operationButtonSize(), //+ 2 * context.buttonBorderWidth(),
      height: context.operationButtonSize(), //+ 2 * context.buttonBorderWidth(),
      child: Image.asset(isPressedList.operationButtonImage(styleNumber)[number]),
    );

//Floor Button
SizedBox floorButtonImage(BuildContext context, int buttonStyle, String buttonShape, int floorNumber, bool isSelected) =>
    SizedBox(
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

///About EV Mileage Tooltip
Container evMileTooltip(BuildContext context) => Container(
  height: 40,
  alignment: Alignment.topCenter,
  margin: const EdgeInsets.only(left: 5),
  child: Tooltip(
    richMessage: TextSpan(
      children: <InlineSpan>[
        WidgetSpan(
          child: pointIcon(context.tooltipTitleFontSize()),
        ),
        TextSpan(
          text: " ${context.eVMile()}",
          style: TextStyle(
            color: lampColor,
            fontWeight: FontWeight.bold,
            fontFamily: menuFont,
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
            fontFamily: menuFont,
            decoration: TextDecoration.none,
            fontSize: context.tooltipDescFontSize(),
          ),
        ),
      ],
    ),
    padding: EdgeInsets.all(context.tooltipPaddingSize()), //吹き出しのpadding
    margin: EdgeInsets.all(context.tooltipMarginSize()), //吹き出しのmargin
    verticalOffset: context.tooltipOffsetSize(), //childのwidget２ら垂直方向にどれだけ離すか
    preferBelow: true, //メッセージを子widgetの上に出すか下に出すか
    decoration: BoxDecoration(
      color: transpBlackColor,
      borderRadius: BorderRadius.all(Radius.circular(context.tooltipBorderRadius()))
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

///Menu Button
Container menuButton(BuildContext context, int i) => Container(
  width: context.menuButtonSize(),
  height: context.menuButtonSize(),
  margin: EdgeInsets.only(
    top: (i == 0) ? context.menuButtonBottomMargin(): 0,
    bottom: context.menuButtonBottomMargin(),
  ),
  child: Image.asset(
    (i == 0) ? settingsButton:
    (i == 1) ? adRewardButton:
    (i == 2) ? rankingButton:
    squareButton
  ),
);

alertLockWidget(BuildContext context)  => Container(
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
      lockIcon(context.settingsAlertLockIconSize()),
      SizedBox(width: context.settingsAlertLockSpaceSize()),
      pointIcon(context.settingsAlertLockIconSize()),
      SizedBox(width: context.settingsLockMargin()),
      Text("$albumImagePoint",
        style: TextStyle(
          color: lampColor,
          fontSize: context.settingsAlertLockFontSize(),
          fontWeight: FontWeight.normal,
          fontFamily: numberFont,
        ),
      ),
      const Spacer(flex: 1),
    ]),
  ]),
);

Widget circularProgressIndicator(BuildContext context) =>
    Stack(children: [
      Container(
        width: context.width(),
        height: context.height(),
        color: transpBlackColor,
      ),
      Center(
        child: SizedBox(
          width: context.circleSize(),
          height: context.circleSize(),
          child: CircularProgressIndicator(
            color: whiteColor,
            strokeWidth: context.circleStrokeWidth(),
          )
        )
      ),
    ]);

Divider myDivider(BuildContext context) => Divider(
  height: context.dividerHeight(),
  thickness: context.dividerThickness(),
  color: grayColor,
);