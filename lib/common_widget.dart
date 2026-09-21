// ===== CommonWidget: reusable UI components =====
// Backgrounds, flash buttons, loading indicators and responsive helpers.

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

  /// Show a floating notification using the shared app styling
  void commonSnackBar(String text) {
    final snackBar = SnackBar(
      // Shrunk rather than wrapped: the text carries its own line breaks, and a
      // language that overruns should keep them instead of folding a third line
      content: FittedBox(fit: BoxFit.scaleDown,
        child: Text(text,
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
            fontSize: context.snackBarFontSize(),
          ),
          textAlign: TextAlign.center,
        ),
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


