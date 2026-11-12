// Checks the cross-promo stored values: the first launch date, the counts and the found flag.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_prefs.dart';
import 'package:letselevatorneo/review_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first launch date is written once and not changed on later launches', () async {
    await PromoPrefs.recordLaunch(now: DateTime(2026, 11, 12, 9));
    expect(await PromoPrefs.getFirstLaunchDate(), DateTime(2026, 11, 12));

    await PromoPrefs.recordLaunch(now: DateTime(2026, 11, 20, 9));
    expect(await PromoPrefs.getFirstLaunchDate(), DateTime(2026, 11, 12));
    expect(await PromoPrefs.getLaunchCount(), 2);
  });

  test('launch count adds 1 on every launch', () async {
    await PromoPrefs.recordLaunch(now: DateTime(2026, 11, 12));
    await PromoPrefs.recordLaunch(now: DateTime(2026, 11, 12));
    await PromoPrefs.recordLaunch(now: DateTime(2026, 11, 12));
    expect(await PromoPrefs.getLaunchCount(), 3);
  });

  test('ride count is read from the ReviewManager key and not written', () async {
    SharedPreferences.setMockInitialValues({ReviewManager.rideCountKey: 7});
    expect(await PromoPrefs.getRideCount(), 7);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(ReviewManager.rideCountKey), 7);
  });

  test('menu shown count adds 1 each time', () async {
    expect(await PromoPrefs.incrementAdventureMenuShownCount(), 1);
    expect(await PromoPrefs.incrementAdventureMenuShownCount(), 2);
    expect(await PromoPrefs.getAdventureMenuShownCount(), 2);
  });

  test('next video pattern is stored and read back', () async {
    expect(await PromoPrefs.getAdventureVideoNextPattern(), isNull);
    await PromoPrefs.setAdventureVideoNextPattern('p2');
    expect(await PromoPrefs.getAdventureVideoNextPattern(), 'p2');
  });

  test('a tap stores the placement, the time and the pattern on screen', () async {
    final at = DateTime(2026, 11, 12, 10, 30);
    await PromoPrefs.recordAdventureTap(placement: 'menu', pattern: 'p3', now: at);
    expect(await PromoPrefs.getAdventureTapped(), 'menu');
    expect(await PromoPrefs.getAdventureTappedAt(), at);
    expect(await PromoPrefs.getAdventureLastTappedPattern(), 'p3');
  });

  test('found flag starts false and stays true once set', () async {
    expect(await PromoPrefs.isAdventureFoundLogged(), isFalse);
    await PromoPrefs.markAdventureFoundLogged();
    expect(await PromoPrefs.isAdventureFoundLogged(), isTrue);
    await PromoPrefs.markAdventureFoundLogged();
    expect(await PromoPrefs.isAdventureFoundLogged(), isTrue);
  });
}
