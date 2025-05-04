import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:vibration/vibration.dart';
import 'extension.dart';
import 'constant.dart';
import 'common_widget.dart';
import 'games_manager.dart';

AppBar myAppBar({
  required BuildContext context,
  required int point,
  required bool isMenuIcon,
  required VoidCallback pressedMenu,
}) => AppBar(
  backgroundColor: blackColor,
  shadowColor: Colors.transparent,
  automaticallyImplyLeading: false,
  title: Row(children: [
    GestureDetector(
      onTap: () async {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        await gamesShowLeaderboard();
      },
      child: pointIcon(45),
    ),
    Container(
      height: 50,
      margin: const EdgeInsets.only(left: 10, bottom: 2),
      child: HookBuilder(
        builder: (context) => Text(
          "$point",
          style: const TextStyle(
            color: lampColor,
            fontSize: 45,
            fontWeight: FontWeight.normal,
            fontFamily: numberFont,
          ),
        ),
      ),
    ),
    evMileTooltip(context),
  ]),
  actions: [
    (isMenuIcon) ? IconButton(
      icon: menuIcon(context.menuIconSize()),
      onPressed: pressedMenu,
    ): SizedBox(width: context.menuIconSize()),
    const SizedBox(width: 10),
  ],
);