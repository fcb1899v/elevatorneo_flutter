// Checks that each promo event value falls into the bucket named in the spec, at both sides of every boundary.

import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_buckets.dart';

void main() {
  test('launch_count buckets', () {
    expect(launchCountBucket(1), '1');
    expect(launchCountBucket(2), '2');
    expect(launchCountBucket(3), '3_5');
    expect(launchCountBucket(5), '3_5');
    expect(launchCountBucket(6), '6_20');
    expect(launchCountBucket(20), '6_20');
    expect(launchCountBucket(21), '21_plus');
    expect(launchCountBucket(0), '1');
  });

  test('ride_count buckets', () {
    expect(rideCountBucket(0), '0');
    expect(rideCountBucket(1), '1');
    expect(rideCountBucket(2), '2_5');
    expect(rideCountBucket(5), '2_5');
    expect(rideCountBucket(6), '6_30');
    expect(rideCountBucket(30), '6_30');
    expect(rideCountBucket(31), '31_plus');
  });

  test('days_since_first_launch buckets', () {
    expect(daysSinceFirstLaunchBucket(0), '0');
    expect(daysSinceFirstLaunchBucket(1), '1_7');
    expect(daysSinceFirstLaunchBucket(7), '1_7');
    expect(daysSinceFirstLaunchBucket(8), '8_30');
    expect(daysSinceFirstLaunchBucket(30), '8_30');
    expect(daysSinceFirstLaunchBucket(31), '31_plus');
  });

  test('shown_count buckets', () {
    expect(shownCountBucket(1), '1');
    expect(shownCountBucket(2), '2');
    expect(shownCountBucket(3), '3_5');
    expect(shownCountBucket(5), '3_5');
    expect(shownCountBucket(6), '6_20');
    expect(shownCountBucket(20), '6_20');
    expect(shownCountBucket(21), '21_plus');
  });

  test('visible buckets', () {
    expect(visibleBucket(const Duration(milliseconds: 999)), 'lt1s');
    expect(visibleBucket(const Duration(milliseconds: 1000)), '1_3s');
    expect(visibleBucket(const Duration(milliseconds: 2999)), '1_3s');
    expect(visibleBucket(const Duration(milliseconds: 3000)), '3_10s');
    expect(visibleBucket(const Duration(milliseconds: 9999)), '3_10s');
    expect(visibleBucket(const Duration(milliseconds: 10000)), '10_30s');
    expect(visibleBucket(const Duration(milliseconds: 29999)), '10_30s');
    expect(visibleBucket(const Duration(milliseconds: 30000)), '30s_plus');
  });

  test('video_position buckets', () {
    expect(videoPositionBucket(Duration.zero), '0_2s');
    expect(videoPositionBucket(const Duration(milliseconds: 1999)), '0_2s');
    expect(videoPositionBucket(const Duration(milliseconds: 2000)), '2_5s');
    expect(videoPositionBucket(const Duration(milliseconds: 4999)), '2_5s');
    expect(videoPositionBucket(const Duration(milliseconds: 5000)), '5s_plus');
  });

  test('patterns_seen buckets', () {
    expect(patternsSeenBucket(1), '1');
    expect(patternsSeenBucket(2), '2');
    expect(patternsSeenBucket(3), '3_plus');
    expect(patternsSeenBucket(9), '3_plus');
  });

  test('away buckets', () {
    expect(awayBucket(const Duration(milliseconds: 4999)), 'lt5s');
    expect(awayBucket(const Duration(seconds: 5)), '5_30s');
    expect(awayBucket(const Duration(seconds: 29)), '5_30s');
    expect(awayBucket(const Duration(seconds: 30)), '30s_2m');
    expect(awayBucket(const Duration(minutes: 2) - const Duration(milliseconds: 1)), '30s_2m');
    expect(awayBucket(const Duration(minutes: 2)), '2m_plus');
  });

  test('since_tap buckets', () {
    expect(sinceTapBucket(null), 'none');
    expect(sinceTapBucket(const Duration(minutes: 59)), 'lt1h');
    expect(sinceTapBucket(const Duration(hours: 1)), '1_24h');
    expect(sinceTapBucket(const Duration(hours: 23)), '1_24h');
    expect(sinceTapBucket(const Duration(hours: 24)), '1_7d');
    expect(sinceTapBucket(const Duration(days: 6)), '1_7d');
    expect(sinceTapBucket(const Duration(days: 7)), '7d_plus');
  });
}
