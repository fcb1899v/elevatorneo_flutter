// Floor panel rules: the picker range, the save guard, and the stop toggles.
// Pure functions in constant.dart / extension.dart, tested directly, not through widgets.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letselevatorneo/image_manager.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/extension.dart';

/// Every button that is not 1F, as the (row, col) the widgets pass around
List<List<int>> selectableCells() {
  final cells = <List<int>>[];
  for (int row = 0; row < reversedButtonIndex.length; row++) {
    for (int col = 0; col < reversedButtonIndex[row].length; col++) {
      if (!isNotSelectFloor(row, col)) cells.add([row, col]);
    }
  }
  return cells;
}

void expectValidPanel(List<int> list, String reason) {
  expect(list.length, initialFloorNumbers.length, reason: reason);
  expect(list[oneFloorIndex], 1, reason: reason);
  expect(list.contains(0), isFalse, reason: reason);
  expect(list.first >= min && list.last <= max, isTrue, reason: reason);
  for (int i = 1; i < list.length; i++) {
    expect(list[i] > list[i - 1], isTrue, reason: "$reason: not ascending at $i");
  }
}

void main() {
  test("the initial panel obeys every rule", () {
    expectValidPanel(initialFloorNumbers, "initial");
  });

  test("every offered floor is accepted and keeps the panel valid", () {
    for (final cell in selectableCells()) {
      final row = cell[0], col = cell[1];
      final list = List<int>.from(initialFloorNumbers);
      final first = list.selectFirstFloor(row, col);
      final last = list.selectLastFloor(row, col);
      expect(last >= first, isTrue, reason: "empty range at $cell");
      for (int i = 0; i < list.selectDiffFloor(row, col); i++) {
        final value = list.selectedFloor(i, row, col);
        final index = reversedButtonIndex[row][col];
        expect(isInFloorGap(list, index, value), isTrue,
          reason: "offered $value at $cell but the save refuses it");
        expectValidPanel(
          List<int>.from(list)..[index] = value, "picked $value at $cell");
      }
    }
  });

  test("a value meant for another button is refused", () {
    // The picker reports an index, not a floor, so a stale selection can reach the save.
    // It would push the panel past max unless the save refuses it.
    final list = List<int>.from(initialFloorNumbers);
    for (final cell in selectableCells()) {
      final row = cell[0], col = cell[1];
      final index = reversedButtonIndex[row][col];
      final offered = <int>{
        for (int i = 0; i < list.selectDiffFloor(row, col); i++)
          list.selectedFloor(i, row, col),
      };
      for (int value = min - 2; value <= max + 2; value++) {
        expect(isInFloorGap(list, index, value), offered.contains(value),
          reason: "$value at $cell: the save and the picker disagree");
      }
    }
    expect(isInFloorGap(list, list.length - 1, max + 1), isFalse);
    expect(isInFloorGap(list, 0, min - 1), isFalse);
    expect(isInFloorGap(list, oneFloorIndex, 2), isFalse);
    expect(isInFloorGap(list, oneFloorIndex - 1, 0), isFalse);
    expect(isInFloorGap(list, oneFloorIndex + 1, 1), isFalse);
  });

  test("a broken saved panel is repaired, and only the broken part", () {
    // A valid panel is left alone
    expect(normalizedFloorNumbers(initialFloorNumbers), initialFloorNumbers);
    // A list of the wrong length has nothing to repair
    expect(normalizedFloorNumbers([1, 2]), initialFloorNumbers);

    // 1F is put back and the buttons around it are pushed clear of it
    final noOneFloor = List<int>.from(initialFloorNumbers)..[oneFloorIndex] = 0;
    expectValidPanel(normalizedFloorNumbers(noOneFloor), "1F was 0");

    // The old basement picker let each button be set on its own
    final tangled = List<int>.from(initialFloorNumbers);
    for (int i = 0; i < oneFloorIndex; i++) {
      tangled[i] = -1;
    }
    final repaired = normalizedFloorNumbers(tangled);
    expectValidPanel(repaired, "duplicated basement");
    // Above ground was fine, so it is untouched
    for (int i = oneFloorIndex + 1; i < repaired.length; i++) {
      expect(repaired[i], initialFloorNumbers[i], reason: "moved a good floor at $i");
    }

    // Repair that runs off the end has nothing sensible left to keep
    final over = List<int>.from(initialFloorNumbers)..[initialFloorNumbers.length - 1] = max + 5;
    expect(normalizedFloorNumbers(over), initialFloorNumbers);
    final unordered = List<int>.from(initialFloorNumbers)..[oneFloorIndex + 1] = max;
    expect(normalizedFloorNumbers(unordered), initialFloorNumbers);

    // Whatever comes in, what comes out is a panel the pickers can work with
    for (final broken in [
      List<int>.generate(initialFloorNumbers.length, (_) => 0),
      List<int>.generate(initialFloorNumbers.length, (i) => -i),
      List<int>.generate(initialFloorNumbers.length, (_) => 1),
    ]) {
      final out = normalizedFloorNumbers(broken);
      expectValidPanel(out, "repaired $broken");
    }
  });

  test("each side of 1F keeps at least one stop", () {
    // Exhaustive over every panel state and every toggle it allows
    final n = initialFloorStops.length;
    bool sidesOk(List<bool> s) =>
      s.sublist(0, oneFloorIndex).contains(true) &&
      s.sublist(oneFloorIndex + 1).contains(true);
    for (int m = 0; m < (1 << n); m++) {
      final stops = List<bool>.generate(n, (i) => (m >> i) & 1 == 1)..[oneFloorIndex] = true;
      if (!sidesOk(stops)) continue;
      for (int i = 0; i < n; i++) {
        if (i == oneFloorIndex) continue;
        for (final value in [true, false]) {
          if (!value && isOnlyStop(stops, i)) continue;  // the switch is disabled
          expect(sidesOk(List<bool>.from(stops)..[i] = value), isTrue,
            reason: "setting $i to $value emptied a side");
        }
      }
    }
  });

  test("a saved state with an empty side is repaired", () {
    final none = List<bool>.generate(initialFloorStops.length, (_) => false);
    final fixed = normalizedFloorStops(none);
    expect(fixed[oneFloorIndex], isTrue);
    expect(fixed.sublist(0, oneFloorIndex).contains(true), isTrue);
    expect(fixed.sublist(oneFloorIndex + 1).contains(true), isTrue);
    expect(normalizedFloorStops([true, false]).length, initialFloorStops.length);
  });
  group("persistence", () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    Future<Set<String>> savedKeys(String prefix) async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((k) => k.startsWith(prefix)).toSet();
    }

    test("a floor outside the gap is neither returned nor written", () async {
      final manager = ImageManager();
      final before = List<int>.from(initialFloorNumbers);
      for (final attempt in [
        [before.length - 1, max + 1],     // past the top of the building
        [0, min - 1],                     // past the bottom
        [oneFloorIndex, 2],               // 1F never moves
        [oneFloorIndex - 1, 0],           // floor 0 does not exist
        [oneFloorIndex + 1, before[oneFloorIndex + 2]],  // onto its neighbour
      ]) {
        final after = await manager.saveFloorNumber(
          currentList: before, newIndex: attempt[0], newValue: attempt[1]);
        expect(after, before, reason: "accepted ${attempt[1]} at ${attempt[0]}");
      }
      expect(await savedKeys("numbersKey"), isEmpty);
    });

    test("a floor inside the gap is returned and written", () async {
      final manager = ImageManager();
      final before = List<int>.from(initialFloorNumbers);
      final index = before.length - 1;
      // A value the panel does not already hold, so saving the old list fails
      final moved = before[index] - 1;
      expect(moved, isNot(before[index]));
      final after = await manager.saveFloorNumber(
        currentList: before, newIndex: index, newValue: moved);
      expect(after[index], moved);
      expectValidPanel(after, "saved the top floor");

      // What reached storage, not just which keys exist
      final prefs = await SharedPreferences.getInstance();
      final stored = List<int>.generate(before.length,
        (i) => prefs.getInt("numbersKey$i") ?? 0);
      expect(stored, after);
      expect(stored, isNot(before));
    });

    test("the last stop on a side is neither returned nor written", () async {
      final manager = ImageManager();
      final before = List<bool>.generate(initialFloorStops.length,
        (i) => i == oneFloorIndex || i == oneFloorIndex - 1 || i == oneFloorIndex + 1);
      for (final index in [oneFloorIndex - 1, oneFloorIndex + 1]) {
        final after = await manager.saveFloorStops(
          currentList: before, newIndex: index, newValue: false);
        expect(after, before, reason: "emptied a side at $index");
      }
      expect(await savedKeys("stopsKey"), isEmpty);
    });

    test("a stop that is not the last one is written", () async {
      final manager = ImageManager();
      final before = List<bool>.generate(initialFloorStops.length, (_) => true);
      final after = await manager.saveFloorStops(
        currentList: before, newIndex: oneFloorIndex + 1, newValue: false);
      expect(after[oneFloorIndex + 1], isFalse);
      expect(await savedKeys("stopsKey"), isNotEmpty);
    });
  });

  group("the top button always shows R, whatever floor it is set to", () {
    // The top button can be renumbered below the structural 163F.
    // "R" must key off isTop, not this floor's own number.
    test("a top floor below 163 still shows R", () {
      expect(120.displayAlphabet(true), "R");
      expect(120.buttonNumber(true), "R");
      expect(120.displayNumber(true), "");
    });

    test("the same floor number away from the top shows its number", () {
      expect(120.displayAlphabet(false), "");
      expect(120.buttonNumber(false), "120");
      expect(120.displayNumber(false), "120");
    });
  });
}
