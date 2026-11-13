// ===== Floor window: the few floors whose panels the moving column builds =====
// Pure functions only, with floors numbered by index so that 0F is skipped.

import 'dart:math' as math;
import 'constant.dart';

/// Number of floors with a room, from B12 to 163. 0F is not counted.
const int floorCount = max - min;

/// Floors above the car floor that the window always includes.
const int floorWindowUpperOffset = 2;

/// Floors below the car floor for the car's own view.
const int cabinWindowLowerOffset = -2;

/// Hall view: the lower edge depends on the screen's height-to-width ratio.
const double hallLowerBaseRatio = 1.615;

/// One floor's height, in units of the width.
const double floorHeightInWidths = 1.57;

/// Largest zoom the user can pinch to.
/// The photos are decoded for it, so they stay sharp.
const double floorImageMaxScale = 1.5;

/// Width in pixels to decode a room photo to: the room's width at the largest zoom.
int roomCacheWidth(double roomWidth, double devicePixelRatio) =>
    (roomWidth * devicePixelRatio * floorImageMaxScale).ceil();

/// Index of floor [f] counted from B12 (0).
/// Floor 0 has no index.
int floorIndex(int f) => f - min - (f > 0 ? 1 : 0);

/// Floor number at index [i]: the reverse of [floorIndex].
int floorAtIndex(int i) {
  final f = i + min;
  return (f >= 0) ? f + 1 : f;
}

/// Lower floor offset of the hall view for a screen whose height is [heightPerWidth] times its width.
/// A small epsilon keeps the exact boundary (3.185) on the lower side, as the spec states it.
int hallLowerOffset(double heightPerWidth) {
  if (heightPerWidth <= hallLowerBaseRatio) return cabinWindowLowerOffset;
  final extra = ((heightPerWidth - hallLowerBaseRatio) / floorHeightInWidths + 1e-9).floor();
  return cabinWindowLowerOffset - extra;
}

/// The floors from [counter] + [lo] to [counter] + [hi], counted in index, clipped to B12 to 163.
List<int> floorWindow(int counter, int lo, int hi) {
  final center = floorIndex(counter);
  final from = math.max(0, center + lo);
  final to = math.min(floorCount - 1, center + hi);
  return [for (int i = from; i <= to; i++) floorAtIndex(i)];
}

/// Key of a floor's panel: its index modulo the window size [count].
/// Floors that leave the window and enter it on the other side share a key.
int panelKey(int floor, int count) => floorIndex(floor) % count;

/// Slot of the car's column (top first).
/// The slot is in units of one floor's height.
int cabinPanelSlot(int floor) => floorCount - 1 - floorIndex(floor);

/// Slot of the hall column (B12 first).
/// The slot is in units of one floor's height.
int hallPanelSlot(int floor) => floorIndex(floor);
