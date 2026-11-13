/// Stored values for the LETS ELEVATOR ADVENTURE cross-promo.
///
/// Each value is written with the same `"name".setSharedPrefXxx` form as the rest of the app.
/// The ride count is not stored here; it is read from `ReviewManager.rideCountKey`.
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../extension.dart';
import '../review_manager.dart';

/// Reads and writes the promo values in `SharedPreferences`.
class PromoPrefs {
  /// Number of app launches. Incremented on every launch.
  static const String launchCountKey = 'launchCountKey';

  /// Date of the first launch, written as `yyyy-MM-dd` when no value exists yet.
  static const String firstLaunchDateKey = 'firstLaunchDateKey';

  /// Number of times the menu showed the ADVENTURE notice.
  static const String adventureMenuShownCountKey = 'adventureMenuShownCountKey';

  /// The pattern to play next, so the video continues where it stopped.
  static const String adventureVideoNextPatternKey = 'adventureVideoNextPatternKey';

  /// The placement where the notice was last tapped, such as `menu`.
  static const String adventureTappedKey = 'adventureTappedKey';

  /// The time of the last tap, written as an ISO 8601 string.
  static const String adventureTappedAtKey = 'adventureTappedAtKey';

  /// The video pattern that was on screen at the last tap.
  static const String adventureLastTappedPatternKey = 'adventureLastTappedPatternKey';

  /// Whether the "found" event was sent. Once true it stays true.
  static const String adventureFoundLoggedKey = 'adventureFoundLoggedKey';

  /// Number of times the notice was closed with its close button.
  /// It never decreases.
  static const String adventureDismissCountKey = 'adventureDismissCountKey';

  /// Day of the last close, written as `yyyy-MM-dd` in the device's local time.
  static const String adventureDismissedDateKey = 'adventureDismissedDateKey';

  /// Records one app launch: adds 1 to the launch count and writes the first launch date if missing.
  static Future<void> recordLaunch({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final count = launchCountKey.getSharedPrefInt(prefs, 0) + 1;
    launchCountKey.setSharedPrefInt(prefs, count);
    _writeFirstLaunchDateIfMissing(prefs, now ?? DateTime.now());
  }

  /// Returns the stored launch count, or 0 when none is stored.
  static Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return launchCountKey.getSharedPrefInt(prefs, 0);
  }

  /// Returns the stored number of finished rides, read from the ReviewManager key.
  static Future<int> getRideCount() async {
    final prefs = await SharedPreferences.getInstance();
    return ReviewManager.rideCountKey.getSharedPrefInt(prefs, 0);
  }

  /// Returns the stored first launch date, or null when none is stored.
  static Future<DateTime?> getFirstLaunchDate() async {
    final prefs = await SharedPreferences.getInstance();
    final text = firstLaunchDateKey.getSharedPrefString(prefs, '');
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// Adds 1 to the menu shown count and returns the new value.
  static Future<int> incrementAdventureMenuShownCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = adventureMenuShownCountKey.getSharedPrefInt(prefs, 0) + 1;
    adventureMenuShownCountKey.setSharedPrefInt(prefs, count);
    return count;
  }

  /// Returns the stored menu shown count, or 0 when none is stored.
  static Future<int> getAdventureMenuShownCount() async {
    final prefs = await SharedPreferences.getInstance();
    return adventureMenuShownCountKey.getSharedPrefInt(prefs, 0);
  }

  /// Returns the stored next video pattern, or null when none is stored.
  static Future<String?> getAdventureVideoNextPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final text = adventureVideoNextPatternKey.getSharedPrefString(prefs, '');
    return text.isEmpty ? null : text;
  }

  /// Stores the pattern to play next.
  static Future<void> setAdventureVideoNextPattern(String pattern) async {
    final prefs = await SharedPreferences.getInstance();
    adventureVideoNextPatternKey.setSharedPrefString(prefs, pattern);
  }

  /// Records a tap on the notice: the placement, the time and the pattern on screen.
  static Future<void> recordAdventureTap({
    required String placement,
    required String pattern,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    adventureTappedKey.setSharedPrefString(prefs, placement);
    adventureTappedAtKey.setSharedPrefString(prefs, (now ?? DateTime.now()).toIso8601String());
    adventureLastTappedPatternKey.setSharedPrefString(prefs, pattern);
  }

  /// Returns the stored placement of the last tap, or null when none is stored.
  static Future<String?> getAdventureTapped() async {
    final prefs = await SharedPreferences.getInstance();
    final text = adventureTappedKey.getSharedPrefString(prefs, '');
    return text.isEmpty ? null : text;
  }

  /// Returns the stored time of the last tap, or null when none is stored.
  static Future<DateTime?> getAdventureTappedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final text = adventureTappedAtKey.getSharedPrefString(prefs, '');
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// Returns the stored pattern of the last tap, or null when none is stored.
  static Future<String?> getAdventureLastTappedPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final text = adventureLastTappedPatternKey.getSharedPrefString(prefs, '');
    return text.isEmpty ? null : text;
  }

  /// Returns true when the "found" event was already sent on this device.
  static Future<bool> isAdventureFoundLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return adventureFoundLoggedKey.getSharedPrefBool(prefs, false);
  }

  /// Marks the "found" event as sent.
  ///
  /// There is no way to set it back to false, so a device logs it only once.
  static Future<void> markAdventureFoundLogged() async {
    final prefs = await SharedPreferences.getInstance();
    adventureFoundLoggedKey.setSharedPrefBool(prefs, true);
  }

  /// Adds 1 to the dismiss count, writes the day of [now], and returns the new count.
  static Future<int> recordAdventureDismiss({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final count = adventureDismissCountKey.getSharedPrefInt(prefs, 0) + 1;
    adventureDismissCountKey.setSharedPrefInt(prefs, count);
    adventureDismissedDateKey.setSharedPrefString(prefs, dayText(now ?? DateTime.now()));
    return count;
  }

  /// Returns true when the notice may be built now: closed fewer than three times, and not closed today.
  static Future<bool> adventureNoticeAllowed({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final count = adventureDismissCountKey.getSharedPrefInt(prefs, 0);
    final date = adventureDismissedDateKey.getSharedPrefString(prefs, '');
    return !dismissBlocks(count: count, dismissedDate: date, now: now ?? DateTime.now());
  }

  /// Whether a stored dismiss count and day keep the notice away at [now].
  ///
  /// Only "the same day" counts, so a close at night is followed by the notice the next morning.
  static bool dismissBlocks({
    required int count,
    required String dismissedDate,
    required DateTime now,
  }) => count >= 3 || (dismissedDate.isNotEmpty && dismissedDate == dayText(now));

  /// The calendar day of [d] as `yyyy-MM-dd`, in the device's local time.
  static String dayText(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static void _writeFirstLaunchDateIfMissing(SharedPreferences prefs, DateTime now) {
    if (firstLaunchDateKey.getSharedPrefString(prefs, '').isNotEmpty) return;
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    firstLaunchDateKey.setSharedPrefString(prefs, '$y-$m-$d');
  }
}
