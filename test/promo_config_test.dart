// Checks the Remote Config parsing and the current values of the cross-promo switches.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_config.dart';

void main() {
  tearDown(() {
    PromoConfig.reset();
  });

  test('parsePatterns reads a full list in order', () {
    expect(PromoConfig.parsePatterns('p1,p2,p3'), ['p1', 'p2', 'p3']);
  });

  test('parsePatterns trims spaces and keeps the given order', () {
    expect(PromoConfig.parsePatterns(' p3 , p1 '), ['p3', 'p1']);
  });

  test('parsePatterns drops repeats and unknown names', () {
    expect(PromoConfig.parsePatterns('p2,p2,p9'), ['p2']);
  });

  test('parsePatterns falls back to all patterns on an empty string', () {
    expect(PromoConfig.parsePatterns(''), PromoConfig.allPatterns);
  });

  test('parsePatterns falls back to all patterns when no name is known', () {
    expect(PromoConfig.parsePatterns('x,y'), PromoConfig.allPatterns);
  });

  test('applyValues replaces the three values', () {
    PromoConfig.applyValues(menuEnabled: false, patterns: 'p3,p2', videoEnabled: false);
    expect(PromoConfig.menuEnabled, isFalse);
    expect(PromoConfig.videoPatterns, ['p3', 'p2']);
    expect(PromoConfig.videoEnabled, isFalse);
  });

  test('reset puts the defaults back', () {
    PromoConfig.applyValues(menuEnabled: false, patterns: 'p3', videoEnabled: false);
    PromoConfig.reset();
    expect(PromoConfig.menuEnabled, isTrue);
    expect(PromoConfig.videoPatterns, PromoConfig.allPatterns);
    expect(PromoConfig.videoEnabled, isTrue);
  });
}
