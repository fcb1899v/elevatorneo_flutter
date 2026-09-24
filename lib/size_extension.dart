// ===== SizeExt: responsive layout sizes (part of extension.dart) =====
part of 'extension.dart';

extension SizeExt on BuildContext {
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  double widthResponsible() => (width() < height() / 2) ? width(): height() / 2;

  // --- UI Layout & Sizing ---
  // Progress indicator
  double circleSize() => widthResponsible() * 0.08;
  double circleStrokeWidth() => widthResponsible() * 0.01;
  // App bar
  double homeAppBarHeight() => height() * 0.07;
  double homeAppBarIconSize() => widthResponsible() * 0.09;
  double homeAppBarIconMarginLeft() => widthResponsible() * 0.02;
  double homeAppBarPointFontSize() => widthResponsible() * 0.08;
  double homeAppBarPointMarginLeft() => widthResponsible() * 0.04;
  double homeAppBarPointMarginBottom() => widthResponsible() * 0.01;
  double homeAppBarMenuButtonSize() => widthResponsible() * 0.09;
  double homeAppBarMenuButtonMargin() => widthResponsible() * 0.045;
  // Tooltip
  double tooltipIconSize() => widthResponsible() * 0.04;
  double tooltipHeight() => widthResponsible() * 0.09;
  double tooltipMarginLeft() => widthResponsible() * 0.01;
  double tooltipTitleFontSize() => widthResponsible() * 0.05;
  double tooltipDescFontSize() => widthResponsible() *0.04;
  double tooltipTitleMargin() => widthResponsible() * 0.01;
  double tooltipPaddingSize() => widthResponsible() * 0.04;
  double tooltipMarginSize() => widthResponsible() * 0.02;
  double tooltipBorderRadius() => widthResponsible() * 0.04;
  double tooltipOffsetSize() => widthResponsible() * 0.02;
  // Elevator layout
  double elevatorWidth() => widthResponsible();
  double elevatorHeight() => widthResponsible() * 16/9;
  double doorWidth() => widthResponsible() * 0.355;
  double doorMarginLeft() => widthResponsible() * 0.023;
  double doorMarginTop() => widthResponsible() * 0.193;
  double upDownDoorMarginTop() => widthResponsible() * 0.191;
  double elevatorMarginTop() => widthResponsible() * 0.045;
  double changeMarginTop() => widthResponsible() * 0.145;
  double roomWidth() => widthResponsible() * 0.73;
  double roomHeight() => roomWidth() * 16/9;
  double floorHeight() => widthResponsible() * 1.57;
  double sideFrameWidth() => widthResponsible() * 0.024;
  double sideSpacerWidth() => (width() - elevatorWidth()) / 2;
  double outsideMarginTop(int counter, int max) =>
      elevatorMarginTop() - (max - counter - (counter < 0 ? 1: 0)) * floorHeight();
  double insideMarginTop(int counter, int max) =>
      elevatorMarginTop() + changeMarginTop() - (max - counter - (counter < 0 ? 1: 0)) * floorHeight();
  double imageMarginTop(bool isOutside, int counter, int max) =>
      (isOutside) ? outsideMarginTop(counter, max): insideMarginTop(counter, max);
  // Display
  double displayHeight() => widthResponsible() * 0.24;
  double displayWidth()  => widthResponsible() * 0.18;
  double displayArrowHeight(int buttonStyle) => widthResponsible() * 0.06;
  double displayArrowMarginTop(int buttonStyle) => widthResponsible() * 0.04;
  double displayNumberHeight() => widthResponsible() * 0.10;
  double displayNumberMarginTop(int buttonStyle) => widthResponsible() * 0.035;
  double displayNumberMarginRight(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.012: 0.015);
  double displayNumberFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.06: 0.06);
  double displayMarginFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.03);
  double displayAlphabetFontSize(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0.065: 0.1);
  double displayAlphabetMargin(int buttonStyle) => widthResponsible() * (buttonStyle == 0 ? 0: 0.02);
  // Hall Lamp
  double hallLampHeight() => widthResponsible() * 0.32;
  // Buttons
  double buttonPanelWidth() => widthResponsible() * 0.23;
  double buttonPanelHeight() => widthResponsible() * 1.05;
  double buttonPanelMarginTop() => widthResponsible() * 0.1;
  double buttonPanelMarginLeft() => widthResponsible() * 0.76;
  double buttonSize() => widthResponsible() * 0.08;
  double operationButtonSize() => widthResponsible() * 0.085;
  double operationButtonMargin() => widthResponsible() * 0.05;
  double upDownButtonMargin() => widthResponsible() * 0.05;
  double floorButtonMargin() => widthResponsible() * 0.02;
  double floorButtonNumberFontSize(int i) =>
      widthResponsible() * floorButtonNumberSizeFactor[i] * 0.03;
  // A one-sided margin is halved by centring, so double it
  double floorButtonNumberMarginTop(int i, double size) =>
      floorButtonNumberOffset[i] > 0 ? 2 * size * floorButtonNumberOffset[i]: 0;
  double floorButtonNumberMarginBottom(int i, double size) =>
      floorButtonNumberOffset[i] < 0 ? -2 * size * floorButtonNumberOffset[i]: 0;
  double changeViewMarginTop() => widthResponsible() * 0.028;
  double changeViewMarginLeft() => widthResponsible() * 0.32;
  // AdMob
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? (height() / 8 - 25): 100;
  double admobWidth() => widthResponsible() - 100;
  // Menu
  double menuButtonSize() => widthResponsible() * 0.28;
  double menuButtonMargin() => widthResponsible() * 0.06;

  // --- Premium purchase page ---
  // Sized against a 430dp-wide iPhone: content 382dp = 0.888, side margins 24dp = 0.056
  double premiumContentWidth() => widthResponsible() * 0.888;
  double premiumSignHeight() => widthResponsible() * 0.242;      // 104dp
  double premiumSignFontSize() => widthResponsible() * 0.163;    // 70dp
  // The product name outranks its description, so it is set larger
  double premiumNameFontSize() => widthResponsible() * 0.065;    // 28dp
  double premiumPlateFontSize() => widthResponsible() * 0.051;   // 22dp
  double premiumBodyFontSize() => widthResponsible() * 0.044;    // 19dp
  double premiumNoteFontSize() => widthResponsible() * 0.033;    // 14dp
  double premiumBuyFontSize() => widthResponsible() * 0.051;     // 22dp
  double premiumRestoreFontSize() => widthResponsible() * 0.037; // 16dp
  double premiumIconSize() => widthResponsible() * 0.172;        // 74dp
  double premiumIconMargin() => widthResponsible() * 0.019;      // 8dp (16dp apart)
  double premiumCloseSize() => widthResponsible() * 0.065;       // 28dp
  double premiumBuyHeight() => widthResponsible() * 0.167;       // 72dp
  double premiumPlatePadding() => widthResponsible() * 0.030;    // 13dp (60dp tall)
  double premiumPlateRadius() => widthResponsible() * 0.019;     // 8dp
  double premiumBuyRadius() => widthResponsible() * 0.033;       // 14dp
  double premiumBorderWidth() => widthResponsible() * 0.005;     // 2dp
  double premiumBuyBorderWidth() => widthResponsible() * 0.012;  // 5dp
  // Tight within a block, loose between blocks; leftover space stays at the bottom
  double premiumGapInner() => widthResponsible() * 0.033;        // 14dp
  double premiumGapBlock() => widthResponsible() * 0.084;        // 36dp
  double menuMarginTop() => height() * 0.02;
  double menuMarginBottom() => height() * 0.25;
  double menuAlertTitleFontSize()  => (widthResponsible() * 0.06 > 36) ? 36: widthResponsible() * 0.06;
  double menuAlertDescFontSize()   => (widthResponsible() * 0.032 > 14) ? 14: widthResponsible() * 0.032;
  double menuAlertSelectFontSize() => (widthResponsible() * 0.040 > 24) ? 24: widthResponsible() * 0.040;
  double menuAlertIconMargin()     => widthResponsible() * 0.01;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() * 0.025;
  double menuLinksMargin() => widthResponsible() * 0.01;
  // SnackBar
  double snackBarFontSize() => widthResponsible() * 0.04;
  double snackBarBorderRadius() => widthResponsible()  * 0.05;
  double snackBarPadding() => widthResponsible()  * 0.02;
  double snackBarSideMargin(TextPainter textPainter) => (widthResponsible() * 0.9 - textPainter.size.width) / 2;
  double snackBarBottomMargin() => height() * 0.03;
  // Settings
  // App Bar
  double settingsAppBarHeight() => height() * 0.07;
  double settingsAppBarFontSize() => height() * 0.032;
  double settingsAppBarBackButtonSize() => height() * 0.05;
  double settingsAppBarBackButtonMargin() => height() * 0.01;
  // Select top button
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  double settingsSelectBorderWidth() => height() * 0.002;
  double settingsSelectIconMargin() => height() * 0.004;
  double settingsSelectIconSize() => height() * 0.036;
  // Common
  double settingsLockFontSize() => height() * 0.03;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  // Change floor image
  double settingsFloorImageLockWidth() => height() * 0.18;
  double settingsFloorImageLockHeight() => height() * 0.20;
  double settingsFloorImageHeight() => height() * 0.19;
  double settingsFloorImageWidth() => settingsFloorImageHeight() * 9 / 16;
  double settingsFloorImageMargin() => height() * 0.01;
  double settingsArrowMarginTop() => height() * 0.03;
  // Change button number
  double settingsButtonSize() => height() * 0.07;
  double settingsButtonNumberSize()   => height() * 0.075;
  double settingsButtonNumberFontSize() => height() * 0.03;
  double settingsButtonNumberMargin() => height() * 0.015;
  double settingsButtonNumberLockWidth() => height() * 0.20;
  double settingsButtonNumberLockHeight() => height() * 0.11;
  // Change floor stop
  double settingsFloorStopFontSize() => height() * 0.015;
  double settingsFloorStopMargin() => height() * 0.005;
  double settingsFloorStopToggleScale() => height() * 0.001;
  // Change button style
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.08;
  // Change button shape
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.02;
  double settingsButtonShapeMarginTop() => height() * 0.03;
  double settingsButtonShapeMarginBottom() => height() * 0.025;
  double settingsButtonShapeLockHeight() => height() * 0.19;
  double settingsButtonShapeLockWidth() => width() * 0.9;
  double settingsButtonShapeLockMarginTop() => height() * 0.114;
  // Change background image
  double settingsBackgroundHeight() => height() * 0.27;
  double settingsBackgroundWidth() => settingsBackgroundHeight() * 0.62;
  double settingsBackgroundMargin() => height() * 0.015;
  double settingsBackgroundLockHeight() => settingsBackgroundHeight() + height() * 0.017;
  double settingsBackgroundLockWidth() => width() * 0.9;
  double settingsBackgroundLockMargin() => height() * 0.292;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  double settingsGlassFontSize() => height() * 0.03;
  double settingsGlassShadowShift() => height() * 0.002;
  // Settings Alert Dialog
  double settingsAlertTitleFontSize() => widthResponsible() * 0.05;
  double settingsAlertFontSize() => widthResponsible() * 0.05;
  double settingsAlertDescFontSize() => widthResponsible() * 0.04;
  double settingsAlertCloseIconSize() =>  widthResponsible() * 0.1;
  double settingsAlertCloseIconSpace() =>  widthResponsible() * 0.05;
  double settingsAlertSelectFontSize() => widthResponsible() * 0.05;
  double settingsAlertFloorNumberPickerHeight() => widthResponsible() * 0.4;
  double settingsAlertFloorNumberHeight() => widthResponsible() * 0.16;
  double settingsAlertFloorNumberFontSize() => widthResponsible() * 0.1;
  double settingsAlertImageSelectHeight() => widthResponsible() * 0.4;
  double settingsAlertDropdownMargin() => widthResponsible() * 0.01;
  double settingsAlertIconSize() => widthResponsible() * 0.06;
  double settingsAlertIconMargin() => widthResponsible() * 0.01;
  double settingsAlertLockFontSize() => widthResponsible() * 0.07;
  double settingsAlertLockIconSize() => widthResponsible() * 0.05;
  double settingsAlertLockSpaceSize() => widthResponsible() * 0.02;
  double settingsAlertLockBorderWidth() => widthResponsible() * 0.002;
  double settingsAlertLockBorderRadius() => widthResponsible() * 0.04;
  // Divider
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
}
