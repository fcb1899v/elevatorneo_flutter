import 'package:flutter/material.dart';
import 'constant.dart';
import 'extension.dart';

class CommonWidget {

  final BuildContext context;

  CommonWidget(this.context);

  ///Background
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

  ///Flash button
  FadeTransition flashButton({
    required AnimationController animationController,
    required IconData icon,
    required bool isDark
  }) => FadeTransition(
    opacity: animationController.drive(CurveTween(curve: Curves.easeInOut)),
    child: Container(
      width: context.settingsSelectButtonSize(),
      height: context.settingsSelectButtonSize(),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? blackColor: whiteColor,
      ),
      child: Icon(icon,
        size: context.settingsSelectButtonIconSize(),
        color: isDark ? whiteColor: blackColor,
      ),
    ),
  );

  ///Circular Progress Indicator
  Widget commonCircularProgressIndicator() => Container(
    alignment: Alignment.center,
    width: context.width(),
    height: context.height(),
    color: transpBlackColor,
    child: CircularProgressIndicator(
      color: lampColor,
      strokeWidth: context.circleStrokeWidth(),
    ),
  );
}


