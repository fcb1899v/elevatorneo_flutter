/// Layout numbers for the ADVENTURE notice card in the main menu.
///
/// Every size is derived from the screen width and height, so the card keeps the same proportions on every device.
library;

import 'dart:math' as math;

class PromoLayout {
  const PromoLayout({
    required this.screenWidth,
    required this.screenHeight,
    required this.topInset,
    required this.bottomRowHeight,
  });

  final double screenWidth;
  final double screenHeight;

  /// Status bar band above the menu.
  final double topInset;

  /// Height of the bottom row under the links band.
  /// Unpaid: the ad height.
  /// Paid: the paid bottom row height.
  final double bottomRowHeight;

  /// Unit for every menu size: the smaller of the width and half the height.
  double get u => math.min(screenWidth, screenHeight / 2);

  /// Gap between rows; also the card's vertical spacing unit.
  double get gap => screenHeight * 0.01;

  /// Height of the header band above the grid.
  double get headerBandHeight => screenHeight * 0.07;

  /// Side length of one grid button.
  double get gridButtonSize => 0.255 * u;

  /// Two rows of grid buttons with one gap between them (card shown).
  double get gridHeight => 2 * gridButtonSize + gap;

  /// Two rows of grid buttons with a wider gap (no card shown).
  double get gridHeightWithoutCard => 2 * gridButtonSize + screenHeight * 0.04;

  /// Bottom link band: a 0.17u margin plus one text line.
  double get bottomLinkBandHeight => 0.17 * u + 1.42 * 0.025 * u;

  /// Height left for the card and the spaces around it.
  double get cardAvailableHeight =>
      screenHeight -
      topInset -
      headerBandHeight -
      bottomLinkBandHeight -
      bottomRowHeight -
      3 * gap -
      gridHeight;

  /// Inner padding of the card, measured from its outer edge.
  double get cardInset => screenHeight * 0.01 + 0.006 * u;

  /// Card width, centred on the screen; capped at 1.09u.
  double get cardWidth =>
      math.min(screenWidth - 2 * screenHeight * 0.01, 1.09 * u);

  /// Minimum width of the text column next to the video.
  double get columnMinWidth => 0.2823 * u;

  /// Video height: the smaller of the height limit and the width limit.
  double get videoHeight {
    final byHeight = cardAvailableHeight - 2 * cardInset;
    final byWidth =
        (cardWidth - 2 * cardInset - 0.025 * u - columnMinWidth) * 4 / 3;
    return math.min(byHeight, byWidth);
  }

  /// Video width at 3:4.
  double get videoWidth => 0.75 * videoHeight;

  /// Width of the text column to the right of the video.
  double get columnWidth => cardWidth - 2 * cardInset - 0.025 * u - videoWidth;

  /// Space left over in the card's height; split above and below the card.
  double get remainder => cardAvailableHeight - (videoHeight + 2 * cardInset);

  /// Height of the card.
  double get cardHeight => videoHeight + 2 * cardInset;

  /// Side length of the close button's square tap area.
  double get closeAreaSize => 0.155 * u;

  /// Distance from the card's top edge to the heading's top edge, where the tap area ends.
  double get closeAreaBottomFromCardTop => cardInset + 0.08 * u;

  /// How far the close button's tap area reaches above the card's top edge.
  /// It may reach into the gap above the card, beside the grid buttons.
  double get closeAreaOverhang =>
      math.max(0, closeAreaSize - closeAreaBottomFromCardTop);
}
