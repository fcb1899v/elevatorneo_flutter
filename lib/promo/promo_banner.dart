/// The LETS ELEVATOR ADVENTURE notice shown under the menu grid.
///
/// The whole notice is one button: a silent video, a heading, the store name and a button.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../analytics_manager.dart';
import '../common_widget.dart';
import '../constant.dart';
import '../extension.dart';
import 'promo_buckets.dart';
import 'promo_prefs.dart';
import 'promo_store.dart';
import 'promo_video.dart';

/// Reads one promo animation or still from the app's assets by its name.
Future<Uint8List> _loadPromoAsset(String name) async {
  final data = await rootBundle.load('assets/images/promo/$name.webp');
  return data.buffer.asUint8List();
}

/// Shows the notice that opens the store page of LETS ELEVATOR ADVENTURE.
class PromoMenuBanner extends StatefulWidget {
  /// Creates the notice with the given [height] and video [patterns].
  const PromoMenuBanner({
    super.key,
    required this.height,
    required this.isPremium,
    required this.patterns,
    required this.firstPattern,
    required this.stillOnly,
    this.onNextPattern,
    this.app = 'elevatorneo',
  });

  /// Height of the notice. The caller passes the smaller of the free height and the maximum.
  final double height;

  /// Whether the user already bought the premium version.
  final bool isPremium;

  /// Pattern names in play order.
  final List<String> patterns;

  /// The pattern to play first. The first of [patterns] is used when it is not in the list.
  final String firstPattern;

  /// Whether to show only the still image and never play the video.
  final bool stillOnly;

  /// Called with the next pattern each time a pattern starts.
  final ValueChanged<String>? onNextPattern;

  /// The app name put in the store link as `utm_source`.
  final String app;

  /// Loads a promo asset by its name. Tests replace it.
  @visibleForTesting
  static PromoAssetLoader loadAsset = _loadPromoAsset;

  @override
  State<PromoMenuBanner> createState() => _PromoMenuBannerState();
}

/// The values read when the notice opens, shared by the events of one opening.
class _ShownInfo {
  const _ShownInfo({
    required this.launchCount,
    required this.rideCount,
    required this.daysSinceFirstLaunch,
    required this.shownCount,
  });

  final String launchCount;
  final String rideCount;
  final String daysSinceFirstLaunch;
  final String shownCount;
}

/// Counts this opening and reads the usage values. Never throws.
Future<_ShownInfo> _readShownInfo() async {
  try {
    final shown = await PromoPrefs.incrementAdventureMenuShownCount();
    final launches = await PromoPrefs.getLaunchCount();
    final rides = await PromoPrefs.getRideCount();
    final first = await PromoPrefs.getFirstLaunchDate();
    return _ShownInfo(
      launchCount: launchCountBucket(launches),
      rideCount: rideCountBucket(rides),
      daysSinceFirstLaunch: daysSinceFirstLaunchBucket(
        first == null ? 0 : _daysSince(first),
      ),
      shownCount: shownCountBucket(shown),
    );
  } catch (_) {
    return const _ShownInfo(
      launchCount: '1',
      rideCount: '0',
      daysSinceFirstLaunch: '0',
      shownCount: '1',
    );
  }
}

/// Counts whole days from [first] to today, by calendar date.
int _daysSince(DateTime first) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(first.year, first.month, first.day);
  return today.difference(start).inDays;
}

class _PromoMenuBannerState extends State<PromoMenuBanner> {
  final GlobalKey<PromoVideoState> _videoKey = GlobalKey<PromoVideoState>();
  final DateTime _openedAt = DateTime.now();

  late String _firstPattern;
  String _pattern = '';
  int _patternsSeen = 0;
  bool _tapped = false;

  /// True while the store is being opened, so a second tap during that time does not open it again.
  bool _leaving = false;

  /// The area of the last press, set by the inner listeners.
  String _pressArea = 'text';
  bool _innerPress = false;

  String _lang = 'ja';
  String _videoMode = 'video';
  Future<_ShownInfo>? _shown;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _firstPattern = _resolveFirst();
    _pattern = _firstPattern;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _lang = context.lang();
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
    _videoMode = (widget.stillOnly || reduceMotion) ? 'still' : 'video';
    _shown = _readShownInfo();
    unawaited(
      _shown!.then(
        (info) => AnalyticsManager.crossPromoShown(
          placement: 'menu',
          isPremium: widget.isPremium,
          lang: _lang,
          launchCount: info.launchCount,
          rideCount: info.rideCount,
          daysSinceFirstLaunch: info.daysSinceFirstLaunch,
          shownCount: info.shownCount,
          firstPattern: _firstPattern,
          videoMode: _videoMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(
      AnalyticsManager.crossPromoViewEnded(
        placement: 'menu',
        visible: visibleBucket(DateTime.now().difference(_openedAt)),
        tapped: _tapped,
        patternsSeen: patternsSeenBucket(_patternsSeen),
        isPremium: widget.isPremium,
      ),
    );
    super.dispose();
  }

  /// Returns the pattern to play first, falling back to the first pattern of the list.
  String _resolveFirst() {
    if (widget.patterns.isEmpty) return '';
    return widget.patterns.contains(widget.firstPattern)
        ? widget.firstPattern
        : widget.patterns.first;
  }

  /// Called when a pattern starts. Stores the pattern after it, so the next opening continues from there.
  void _onPatternChanged(String pattern) {
    _pattern = pattern;
    _patternsSeen++;
    final index = widget.patterns.indexOf(pattern);
    if (index < 0) return;
    final next = widget.patterns[(index + 1) % widget.patterns.length];
    unawaited(PromoPrefs.setAdventureVideoNextPattern(next));
    widget.onNextPattern?.call(next);
  }

  void _onPatternEnded(String pattern, bool completed) {
    unawaited(
      AnalyticsManager.crossPromoVideoPlayed(
        pattern: pattern,
        completed: completed,
        isPremium: widget.isPremium,
      ),
    );
  }

  /// Records the area of a press made on one of the inner parts.
  void _press(String area) {
    _pressArea = area;
    _innerPress = true;
  }

  /// Runs last for a press. Falls back to the text area when no inner part was pressed.
  void _onOuterPointerDown() {
    if (!_innerPress) _pressArea = 'text';
    _innerPress = false;
  }

  Future<void> _handleTap(String area) async {
    if (_leaving) return;
    _leaving = true;
    _tapped = true;
    Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    final pattern = _pattern;
    final position = _videoKey.currentState?.currentElapsed ?? Duration.zero;
    final seen = _patternsSeen;
    final visible = DateTime.now().difference(_openedAt);
    unawaited(
      PromoPrefs.recordAdventureTap(placement: 'menu', pattern: pattern),
    );
    final result = await PromoStore.open(
      app: widget.app,
      placement: 'menu',
      onReturned: (away, method) {
        unawaited(
          AnalyticsManager.crossPromoStoreReturned(
            placement: 'menu',
            videoPattern: pattern,
            openMethod: method,
            away: awayBucket(away),
          ),
        );
      },
    );
    _leaving = false;
    final info = await _shown!;
    unawaited(
      AnalyticsManager.crossPromoTapped(
        placement: 'menu',
        isPremium: widget.isPremium,
        lang: _lang,
        launchCount: info.launchCount,
        rideCount: info.rideCount,
        daysSinceFirstLaunch: info.daysSinceFirstLaunch,
        shownCount: info.shownCount,
        firstPattern: _firstPattern,
        videoMode: _videoMode,
        videoPattern: pattern,
        videoPosition: videoPositionBucket(position),
        patternsSeen: patternsSeenBucket(seen),
        targetArea: area,
        visible: visibleBucket(visible),
        openMethod: result.openMethod ?? 'none',
        opened: result.opened,
      ),
    );
    if (!result.opened && mounted) {
      CommonWidget(context).commonSnackBar(context.premiumUnavailable());
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset =
        context.promoBannerPadding() + context.promoBannerBorderWidth();
    final videoHeight = widget.height - 2 * inset;
    final videoWidth = videoHeight * 16 / 9;
    final textWidth =
        context.promoBannerWidth() -
        2 * inset -
        context.promoVideoTextGap() -
        videoWidth;
    final font = context.font();
    final title = context.promoTitle();
    final name = context.promoAdventureName();
    final button = context.promoStoreButton();
    final separator = switch (_lang) {
      'ja' => '、',
      'zh' => '，',
      _ => ', ',
    };
    final label = '$title$separator$name$separator$button';

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: Semantics(
        container: true,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: () => unawaited(_handleTap('button')),
        child: Listener(
          onPointerDown: (_) => _onOuterPointerDown(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => unawaited(_handleTap(_pressArea)),
            child: Container(
              width: context.promoBannerWidth(),
              height: widget.height,
              padding: EdgeInsets.all(context.promoBannerPadding()),
              decoration: BoxDecoration(
                color: darkBlackColor,
                border: Border.all(
                  color: lampColor,
                  width: context.promoBannerBorderWidth(),
                ),
                borderRadius: BorderRadius.circular(
                  context.promoBannerRadius(),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      context.promoVideoRadius(),
                    ),
                    child: SizedBox(
                      width: videoWidth,
                      height: videoHeight,
                      child: Listener(
                        onPointerDown: (_) => _press('video'),
                        child: PromoVideo(
                          key: _videoKey,
                          patterns: widget.patterns,
                          firstPattern: _firstPattern,
                          loadPattern: PromoMenuBanner.loadAsset,
                          loadStill: PromoMenuBanner.loadAsset,
                          stillOnly: widget.stillOnly,
                          onPatternChanged: _onPatternChanged,
                          onPatternEnded: _onPatternEnded,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.promoVideoTextGap()),
                  SizedBox(
                    width: textWidth,
                    height: videoHeight,
                    // Lets the text column be a little taller than the video at the minimum height.
                    child: OverflowBox(
                      maxHeight: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Listener(
                            onPointerDown: (_) => _press('text'),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: lampColor,
                                fontSize: context.promoTitleFontSize(),
                                fontFamily: font,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: context.promoLineGap()),
                          Listener(
                            onPointerDown: (_) => _press('text'),
                            child: Text(
                              name,
                              maxLines: 2,
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: context.promoNameFontSize(textWidth),
                                fontFamily: font,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SizedBox(height: context.promoLineGap()),
                          Listener(
                            onPointerDown: (_) => _press('button'),
                            child: SizedBox(
                              width: textWidth,
                              height: context.promoButtonHeight(),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: lampColor,
                                  borderRadius: BorderRadius.circular(
                                    context.promoButtonHeight() / 2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        button,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: blackColor,
                                          fontSize: context
                                              .promoButtonFontSize(),
                                          fontFamily: font,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      right: context.promoButtonArrowInset(),
                                      child: Center(
                                        child: Icon(
                                          Icons.chevron_right,
                                          size: context.promoButtonFontSize(),
                                          color: blackColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
