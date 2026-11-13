// Each cross-promo event is sent with its name, its keys and its values, with booleans as 0 or 1.
// The sender is replaced by a recorder, so no Firebase call is made.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/analytics_manager.dart';

void main() {
  final events = <Map<String, Object?>>[];

  setUp(() {
    events.clear();
    AnalyticsManager.send = (name, parameters) async => events.add({"name": name, "params": parameters});
  });

  final shownParams = {
    "target": "adventure",
    "placement": "menu",
    "is_premium": 0,
    "lang": "ja",
    "launch_count": "3_5",
    "ride_count": "2_5",
    "days_since_first_launch": "8_30",
    "shown_count": "2",
    "first_pattern": "p2",
    "video_mode": "video",
    "body_form": "full",
  };

  test("crossPromoShown sends the ten shown parameters", () async {
    await AnalyticsManager.crossPromoShown(
      placement: "menu",
      isPremium: false,
      lang: "ja",
      launchCount: "3_5",
      rideCount: "2_5",
      daysSinceFirstLaunch: "8_30",
      shownCount: "2",
      firstPattern: "p2",
      videoMode: "video",
      bodyForm: "full",
    );
    expect(events, [
      {"name": "cross_promo_shown", "params": shownParams},
    ]);
  });

  test("crossPromoVideoPlayed sends the pattern, completed and is_premium as 0 or 1", () async {
    await AnalyticsManager.crossPromoVideoPlayed(pattern: "p3", completed: true, isPremium: true);
    expect(events, [
      {
        "name": "cross_promo_video_played",
        "params": {"target": "adventure", "pattern": "p3", "completed": 1, "is_premium": 1},
      },
    ]);
  });

  test("crossPromoVideoPlayed sends completed as 0 when the pattern stopped early", () async {
    await AnalyticsManager.crossPromoVideoPlayed(pattern: "p1", completed: false, isPremium: false);
    expect(events.single["params"], {"target": "adventure", "pattern": "p1", "completed": 0, "is_premium": 0});
  });

  test("crossPromoTapped sends the shown parameters plus the tap parameters", () async {
    await AnalyticsManager.crossPromoTapped(
      placement: "menu",
      isPremium: false,
      lang: "ja",
      launchCount: "3_5",
      rideCount: "2_5",
      daysSinceFirstLaunch: "8_30",
      shownCount: "2",
      firstPattern: "p2",
      videoMode: "video",
      bodyForm: "full",
      videoPattern: "p3",
      videoPosition: "2_5s",
      patternsSeen: "2",
      targetArea: "button",
      visible: "10_30s",
      openMethod: "sheet",
      opened: true,
    );
    expect(events, [
      {
        "name": "cross_promo_tapped",
        "params": {
          ...shownParams,
          "video_pattern": "p3",
          "video_position": "2_5s",
          "patterns_seen": "2",
          "target_area": "button",
          "visible": "10_30s",
          "open_method": "sheet",
          "opened": 1,
        },
      },
    ]);
  });

  test("crossPromoTapped sends opened as 0 and open_method none when nothing opened", () async {
    await AnalyticsManager.crossPromoTapped(
      placement: "menu",
      isPremium: false,
      lang: "ja",
      launchCount: "1",
      rideCount: "0",
      daysSinceFirstLaunch: "0",
      shownCount: "1",
      firstPattern: "p1",
      videoMode: "still",
      bodyForm: "full",
      videoPattern: "p1",
      videoPosition: "0_2s",
      patternsSeen: "1",
      targetArea: "text",
      visible: "lt1s",
      openMethod: "none",
      opened: false,
    );
    final params = events.single["params"] as Map<String, Object>;
    expect(params["opened"], 0);
    expect(params["open_method"], "none");
  });

  test("crossPromoViewEnded sends placement, visible, tapped, dismissed and is_premium as 0 or 1", () async {
    await AnalyticsManager.crossPromoViewEnded(
      placement: "menu",
      visible: "3_10s",
      tapped: false,
      patternsSeen: "3_plus",
      isPremium: false,
      dismissed: true,
    );
    expect(events, [
      {
        "name": "cross_promo_view_ended",
        "params": {
          "target": "adventure",
          "placement": "menu",
          "visible": "3_10s",
          "tapped": 0,
          "patterns_seen": "3_plus",
          "is_premium": 0,
          "dismissed": 1,
        },
      },
    ]);
  });

  test("crossPromoViewEnded sends dismissed 0 when the card was not closed", () async {
    await AnalyticsManager.crossPromoViewEnded(
      placement: "menu",
      visible: "lt1s",
      tapped: true,
      patternsSeen: "1",
      isPremium: true,
    );
    expect((events.single["params"] as Map)["dismissed"], 0);
  });

  test("crossPromoDismissed sends the shown parameters plus method close_x and the close parameters", () async {
    await AnalyticsManager.crossPromoDismissed(
      placement: "menu",
      isPremium: false,
      lang: "ja",
      launchCount: "3_5",
      rideCount: "2_5",
      daysSinceFirstLaunch: "8_30",
      shownCount: "2",
      firstPattern: "p2",
      videoMode: "video",
      bodyForm: "full",
      dismissCount: "2",
      videoPattern: "p3",
      videoPosition: "2_5s",
      patternsSeen: "2",
      visible: "1_3s",
    );
    expect(events, [
      {
        "name": "cross_promo_dismissed",
        "params": {
          ...shownParams,
          "method": "close_x",
          "dismiss_count": "2",
          "video_pattern": "p3",
          "video_position": "2_5s",
          "patterns_seen": "2",
          "visible": "1_3s",
        },
      },
    ]);
  });

  test("crossPromoStoreReturned sends the return parameters", () async {
    await AnalyticsManager.crossPromoStoreReturned(
      placement: "menu",
      videoPattern: "p2",
      openMethod: "market",
      away: "30s_2m",
    );
    expect(events, [
      {
        "name": "cross_promo_store_returned",
        "params": {
          "target": "adventure",
          "placement": "menu",
          "video_pattern": "p2",
          "open_method": "market",
          "away": "30s_2m",
        },
      },
    ]);
  });

  test("crossPromoTargetFound sends tapped_before as 0 or 1 and the tap history", () async {
    await AnalyticsManager.crossPromoTargetFound(
      tappedBefore: true,
      lastPlacement: "menu",
      lastPattern: "p3",
      sinceTap: "1_24h",
      isPremium: true,
    );
    expect(events, [
      {
        "name": "cross_promo_target_found",
        "params": {
          "target": "adventure",
          "tapped_before": 1,
          "last_placement": "menu",
          "last_pattern": "p3",
          "since_tap": "1_24h",
          "is_premium": 1,
        },
      },
    ]);
  });

  test("crossPromoTargetFound sends tapped_before 0 with no tap history", () async {
    await AnalyticsManager.crossPromoTargetFound(
      tappedBefore: false,
      lastPlacement: "none",
      lastPattern: "none",
      sinceTap: "none",
      isPremium: false,
    );
    expect(events.single["params"], {
      "target": "adventure",
      "tapped_before": 0,
      "last_placement": "none",
      "last_pattern": "none",
      "since_tap": "none",
      "is_premium": 0,
    });
  });
}
