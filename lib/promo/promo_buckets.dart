/// Rounds the counts and durations of the cross-promo events into the bucket names of the spec.
///
/// Each bucket is a half-open range: the lower bound is included and the upper bound is excluded.
/// So `1_3s` means 1 second or more and less than 3 seconds.
/// Values below the lowest bound fall into the lowest bucket.
library;

/// Buckets the number of app launches into `1`, `2`, `3_5`, `6_20` or `21_plus`.
///
/// Counts of 1 or less are `1`.
String launchCountBucket(int count) {
  if (count <= 1) return '1';
  if (count == 2) return '2';
  if (count <= 5) return '3_5';
  if (count <= 20) return '6_20';
  return '21_plus';
}

/// Buckets the number of rides finished into `0`, `1`, `2_5`, `6_30` or `31_plus`.
///
/// Counts of 0 or less are `0`.
String rideCountBucket(int count) {
  if (count <= 0) return '0';
  if (count == 1) return '1';
  if (count <= 5) return '2_5';
  if (count <= 30) return '6_30';
  return '31_plus';
}

/// Buckets the days since the first launch into `0`, `1_7`, `8_30` or `31_plus`.
///
/// Days of 0 or less are `0`.
String daysSinceFirstLaunchBucket(int days) {
  if (days <= 0) return '0';
  if (days <= 7) return '1_7';
  if (days <= 30) return '8_30';
  return '31_plus';
}

/// Buckets how many times the menu promo was shown into the same bands as [launchCountBucket].
///
/// Counts of 1 or less are `1`.
String shownCountBucket(int count) => launchCountBucket(count);

/// Buckets the time the promo was visible into `lt1s`, `1_3s`, `3_10s`, `10_30s` or `30s_plus`.
///
/// `999` milliseconds is `lt1s`. `1000` milliseconds is `1_3s`.
String visibleBucket(Duration visible) {
  if (visible < const Duration(seconds: 1)) return 'lt1s';
  if (visible < const Duration(seconds: 3)) return '1_3s';
  if (visible < const Duration(seconds: 10)) return '3_10s';
  if (visible < const Duration(seconds: 30)) return '10_30s';
  return '30s_plus';
}

/// Buckets the position in the video into `0_2s`, `2_5s` or `5s_plus`.
///
/// `1999` milliseconds is `0_2s`. `2000` milliseconds is `2_5s`.
String videoPositionBucket(Duration position) {
  if (position < const Duration(seconds: 2)) return '0_2s';
  if (position < const Duration(seconds: 5)) return '2_5s';
  return '5s_plus';
}

/// Buckets the number of video patterns seen in one menu visit into `1`, `2` or `3_plus`.
///
/// Counts of 1 or less are `1`.
String patternsSeenBucket(int count) {
  if (count <= 1) return '1';
  if (count == 2) return '2';
  return '3_plus';
}

/// Buckets the time spent in the store into `lt5s`, `5_30s`, `30s_2m` or `2m_plus`.
///
/// `4999` milliseconds is `lt5s`. `5000` milliseconds is `5_30s`.
String awayBucket(Duration away) {
  if (away < const Duration(seconds: 5)) return 'lt5s';
  if (away < const Duration(seconds: 30)) return '5_30s';
  if (away < const Duration(minutes: 2)) return '30s_2m';
  return '2m_plus';
}

/// Buckets the time since the last tap into `lt1h`, `1_24h`, `1_7d` or `7d_plus`.
///
/// `null` means the promo was never tapped, and returns `none`.
String sinceTapBucket(Duration? sinceTap) {
  if (sinceTap == null) return 'none';
  if (sinceTap < const Duration(hours: 1)) return 'lt1h';
  if (sinceTap < const Duration(hours: 24)) return '1_24h';
  if (sinceTap < const Duration(days: 7)) return '1_7d';
  return '7d_plus';
}
