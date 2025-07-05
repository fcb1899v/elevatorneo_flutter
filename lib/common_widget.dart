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

  // --- Loading and Feedback Components ---
  // Loading indicators and user feedback elements
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


