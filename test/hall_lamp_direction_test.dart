// The hall lamp at the ends of the building: the top floor only goes down and the bottom floor only goes up.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/extension.dart';

void main() {
  final floors = [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  test('the top floor shows down even when the car arrives from below', () {
    expect(floors.hallLampDirection(9, "up"), "down");
    expect(floors.hallLampDirection(9, "down"), "down");
  });

  test('the bottom floor shows up even when the car arrives from above', () {
    expect(floors.hallLampDirection(-1, "down"), "up");
    expect(floors.hallLampDirection(-1, "up"), "up");
  });

  test('a middle floor shows the direction of the car', () {
    expect(floors.hallLampDirection(5, "up"), "up");
    expect(floors.hallLampDirection(5, "down"), "down");
  });

  test('an idle car keeps the lamp off at every floor', () {
    expect(floors.hallLampDirection(9, "none"), "none");
    expect(floors.hallLampDirection(-1, "none"), "none");
  });
}
