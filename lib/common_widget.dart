// =============================
// CommonWidget: Reusable UI components for elevator simulator
//
// This file contains common UI widgets that are used throughout the application.
// These components provide consistent styling and behavior across different screens.
// Key features:
// - Responsive background image handling
// - Animated flash buttons with directional indicators
// - Loading indicators with consistent styling
// - Cross-platform UI elements
// - Responsive design adaptations
// =============================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'constant.dart';
import 'extension.dart';

class CommonWidget {

  final BuildContext context;

  CommonWidget(this.context);

  // --- Background Components ---
  // Responsive background image handling for different screen orientations
  Widget commonBackground(String image) =>
    (context.width() > context.height()) ? ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Image.asset(image,
          fit: BoxFit.fitWidth,
          width: context.width(),
        ),
      ),
    ): SizedBox(
      width: context.width(),
      height: context.height(),
      child: FittedBox(
        fit: BoxFit.fill,
        child: Image.asset(image),
      ),
    );

  // --- Interactive Button Components ---
  // Animated buttons with visual feedback and directional indicators
  FadeTransition flashButton({
    required AnimationController animationController,
    required bool isUp
  }) => FadeTransition(
    opacity: animationController.drive(CurveTween(curve: Curves.easeInOut)),
    child: Container(
      width: context.settingsSelectButtonSize(),
      height: context.settingsSelectButtonSize(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: blackColor,
        border: Border.all(color: whiteColor, 
          width: context.settingsSelectBorderWidth(), 
        ),
      ),
      child: Container(
        margin: isUp ? EdgeInsets.only(bottom: context.settingsSelectIconMargin()):
          EdgeInsets.only(top: context.settingsSelectIconMargin()),
        child: Icon(isUp ? CupertinoIcons.arrowtriangle_up_fill: CupertinoIcons.arrowtriangle_down_fill,
          size: context.settingsSelectIconSize(),
          color: whiteColor,
        ),
      ),
    ),
  );

  // --- Premium Upgrade Components ---
  // Purchase entry point shown where the user meets a locked feature
  /// Offer the premium unlock, with a restore option required by both stores
  void upgradeAlert({
    required String price,
    required void Function() onBuy,
    required void Function() onRestore,
  }) => showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.premiumTitle(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertTitleFontSize(),
          fontFamily: context.font(),
        ),
      ),
      content: Text(context.premiumDesc(),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertDescFontSize(),
          fontFamily: context.font(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.popPage(),
          child: Text(context.cancel(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
        TextButton(
          onPressed: onRestore,
          child: Text(context.premiumRestore(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
        TextButton(
          onPressed: onBuy,
          child: Text(context.premiumBuy(price),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: context.font(),
            ),
          ),
        ),
      ],
    ),
  );

  // --- Loading and Feedback Components ---
  // Loading indicators and user feedback elements
  /// Show a floating notification using the shared app styling
  void commonSnackBar(String text) {
    final snackBar = SnackBar(
      content: Text(text,
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.snackBarFontSize(),
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: lampColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.snackBarBorderRadius()),
      ),
      padding: EdgeInsets.all(context.snackBarPadding()),
      margin: EdgeInsets.symmetric(
        horizontal: context.snackBarPadding(),
        vertical: context.snackBarBottomMargin(),
      ),
    );
    "commonSnackBar: $text".debugPrint();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget commonCircularProgressIndicator() => Container(
    alignment: Alignment.center,
    width: context.width(),
    height: context.height(),
    color: transpBlackColor,
    child: SizedBox(
      width: context.circleSize(),
      height: context.circleSize(),
      child: CircularProgressIndicator(
        color: lampColor,
        strokeWidth: context.circleStrokeWidth(),
      ),
    )
  );
}


