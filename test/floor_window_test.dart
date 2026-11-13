// Floor window rules: the index of each floor, the window around the car, the panel keys and slots.
// Pure functions in floor_window.dart, tested directly with lengths from size_extension.dart.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/floor_window.dart';

/// Every floor that exists, from B12 to 163 (0F skipped)
List<int> allFloors() => [for (int f = min; f <= max; f++) if (f != 0) f];

// Size ratios from size_extension.dart, in units of the width W
const double elevatorMarginTopW = 0.045;
const double changeMarginTopW = 0.145;
const double doorMarginTopW = 0.193;
const double roomHeightW = 0.73 * 16 / 9;

void main() {
  test("T1: index of every floor, and back again", () {
    expect(floorIndex(-12), 0);
    expect(floorIndex(-1), 11);
    expect(floorIndex(1), 12);
    expect(floorIndex(2), 13);
    expect(floorIndex(163), 174);
    expect(floorCount, 175);
    for (final f in allFloors()) {
      expect(floorAtIndex(floorIndex(f)), f, reason: "round trip of $f");
    }
  });

  test("T2: the lower edge of the window for each height-to-width ratio", () {
    expect(cabinWindowLowerOffset, -2);
    expect(hallLowerOffset(2.00), -2);
    expect(hallLowerOffset(2.17), -2);
    expect(hallLowerOffset(2.23), -2);
    expect(hallLowerOffset(3.185), -3);
    expect(hallLowerOffset(1.5), -2);
  });

  test("T3: windows around B2, B1 and 1 (0F is skipped)", () {
    expect(floorWindow(1, -2, 2), [-2, -1, 1, 2, 3]);
    expect(floorWindow(-1, -2, 2), [-3, -2, -1, 1, 2]);
    expect(floorWindow(2, -2, 2), [-1, 1, 2, 3, 4]);
  });

  test("T4: windows clipped at both ends", () {
    expect(floorWindow(-12, -2, 2), [-12, -11, -10]);
    expect(floorWindow(-11, -2, 2), [-12, -11, -10, -9]);
    expect(floorWindow(163, -2, 2), [161, 162, 163]);
    expect(floorWindow(162, -2, 2), [160, 161, 162, 163]);
  });

  test("T5: for every floor, the window fits, its keys differ, and its floors are consecutive", () {
    for (final size in [5, 6]) {
      final lo = -(size - 3); // 5 means -2..2, 6 means -3..2
      for (final c in allFloors()) {
        final window = floorWindow(c, lo, floorWindowUpperOffset);
        expect(window.length <= size, isTrue, reason: "window of $c with $size");
        final keys = window.map((f) => panelKey(f, size)).toSet();
        expect(keys.length, window.length, reason: "keys collide around $c with $size");
        for (int k = 1; k < window.length; k++) {
          expect(floorIndex(window[k]), floorIndex(window[k - 1]) + 1,
              reason: "not consecutive around $c");
        }
      }
    }
  });

  test("T6: moving one floor at a time, the floor that leaves and the floor that enters share a key", () {
    final indices = List.generate(floorCount, (i) => i);
    List<int>? previous;
    for (final i in indices) {
      final counter = floorAtIndex(i);
      final next = floorWindow(counter, cabinWindowLowerOffset, floorWindowUpperOffset);
      if (previous != null) {
        final leaving = previous.where((f) => !next.contains(f)).toList();
        final entering = next.where((f) => !previous!.contains(f)).toList();
        if (leaving.length == 1 && entering.length == 1) {
          expect(panelKey(leaving.first, 5), panelKey(entering.first, 5),
              reason: "keys differ when moving to $counter");
        }
      }
      previous = next;
    }
  });

  test("T7: every floor that is visible in the car's column is inside the window", () {
    // The column's top moves with q (in floors).
    // Panel top = 0.19 + (q - index) * floorHeight, in W.
    const topOffset = elevatorMarginTopW + changeMarginTopW;
    const visibleBottom = doorMarginTopW + roomHeightW;
    for (final c in allFloors()) {
      final window = floorWindow(c, cabinWindowLowerOffset, floorWindowUpperOffset);
      final centre = floorIndex(c).toDouble();
      for (double q = centre - 1; q <= centre + 1 + 1e-9; q += 0.01) {
        for (final f in allFloors()) {
          final top = topOffset + (q - floorIndex(f)) * floorHeightInWidths;
          final visible = top < visibleBottom && top + floorHeightInWidths > 0;
          if (visible) {
            expect(window.contains(f), isTrue, reason: "$f visible at counter $c, q $q");
          }
        }
      }
    }
  });

  test("T8: every floor that is visible in the hall's column is inside its window, for each screen ratio", () {
    for (final ratio in [1.5, 2.0, 2.17, 2.23, 3.0, 3.185, 3.5, 4.0]) {
      final lo = hallLowerOffset(ratio);
      for (final c in allFloors()) {
        final window = floorWindow(c, lo, floorWindowUpperOffset);
        final centre = floorIndex(c).toDouble();
        for (double t = 0; t <= 1 + 1e-9; t += 0.1) {
          final screenHeight = t * ratio;
          for (double q = centre - 1; q <= centre + 1 + 1e-9; q += 0.05) {
            for (final f in allFloors()) {
              final top = screenHeight - hallLowerBaseRatio + (floorIndex(f) - q) * floorHeightInWidths;
              final visible = top < screenHeight && top + floorHeightInWidths > 0;
              if (visible) {
                expect(window.contains(f), isTrue,
                    reason: "$f visible at counter $c, ratio $ratio, height $screenHeight, q $q");
              }
            }
          }
        }
      }
    }
  });

  test("T9: the car's panel positions match the old reversed list", () {
    final oldOrder = allFloors().reversed.toList();
    for (int k = 0; k < oldOrder.length; k++) {
      expect(cabinPanelSlot(oldOrder[k]), k, reason: "floor ${oldOrder[k]}");
    }
  });

  test("T10: the hall's panel positions match the old list order", () {
    final oldOrder = allFloors();
    for (int k = 0; k < oldOrder.length; k++) {
      expect(hallPanelSlot(oldOrder[k]), k, reason: "floor ${oldOrder[k]}");
    }
  });

  test("T14: the photo decode width, and the zoom limit the viewer uses", () {
    expect(floorImageMaxScale, 1.5);
    expect(roomCacheWidth(293.46, 3), 1321);
    expect(roomCacheWidth(100.0, 1.0), 150);
    expect(roomCacheWidth(100.1, 1.0), 151);
    final homepage = File('lib/homepage.dart').readAsStringSync();
    expect(homepage.contains('maxScale: floorImageMaxScale,'), isTrue);
    expect(homepage.contains('maxScale: 1.5'), isFalse);
  });

  test("T15: the old 175-floor builders are gone from lib", () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('firebase_options.dart'));
    for (final file in files) {
      final text = file.readAsStringSync();
      expect(text.contains('floorImages('), isFalse, reason: "${file.path} still calls floorImages(");
      expect(text.contains('insideImages('), isFalse, reason: "${file.path} still calls insideImages(");
      for (final name in ['roomImage(', 'cropperImage(', 'fittedAssetImage(']) {
        expect(text.contains(name), isFalse, reason: "${file.path} still has $name");
      }
    }
  });
}
