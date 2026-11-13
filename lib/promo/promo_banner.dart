/// The LETS ELEVATOR ADVENTURE notice shown under the menu grid.
///
/// The card is one button: a silent video, a heading, the logo, a body and a button.
/// A close button at its top right hides it for now.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../analytics_manager.dart';
import '../common_widget.dart';
import '../constant.dart';
import '../extension.dart';
import 'promo_buckets.dart';
import 'promo_card_text.dart';
import 'promo_layout.dart';
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
  /// Creates the card from the menu's [layout] and the text [plan].
  const PromoMenuBanner({
    super.key,
    required this.layout,
    required this.plan,
    required this.isPremium,
    required this.patterns,
    required this.firstPattern,
    required this.stillOnly,
    required this.onDismiss,
    this.onNextPattern,
    this.app = 'elevatorneo',
  });

  /// The sizes of the menu, from `PromoLayout`.
  final PromoLayout layout;

  /// The texts and the gap, from `planPromoCard`.
  final PromoCardPlan plan;

  /// Whether the user already bought the premium version.
  final bool isPremium;

  /// Pattern names in play order.
  final List<String> patterns;

  /// The pattern to play first. The first of [patterns] is used when it is not in the list.
  final String firstPattern;

  /// Whether to show only the still image and never play the video.
  final bool stillOnly;

  /// Called when the close button is pressed.
  final VoidCallback onDismiss;

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

  /// True once the close button was pressed, so the notice counts one close only.
  bool _dismissed = false;

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
          bodyForm: widget.plan.bodyForm,
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
        dismissed: _dismissed,
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
        bodyForm: widget.plan.bodyForm,
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

  /// The video in a box of [w] by [h], with the rounded corners.
  Widget _videoBox(double w, double h) => ClipRRect(
    borderRadius: BorderRadius.circular(0.008 * widget.layout.u),
    child: SizedBox(
      width: w,
      height: h,
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
  );

  /// The store button, [width] wide.
  /// Its text and arrow shrink together when they do not fit.
  Widget _buttonFace(double width, String font, String button) {
    final u = widget.layout.u;
    final height = 0.065 * u;
    return Listener(
      onPointerDown: (_) => _press('button'),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: lampColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.025 * u),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      button,
                      maxLines: 1,
                      style: TextStyle(
                        inherit: false,
                        color: blackColor,
                        fontSize: 0.032 * u,
                        fontFamily: font,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 0.008 * u),
                    Icon(Icons.chevron_right, size: 0.032 * u, color: blackColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The heading: one line that shrinks for Japanese and Chinese, up to two lines otherwise.
  /// The styles do not inherit the theme's text style, so the text is drawn as wide as `planPromoCard` measured it.
  Widget _heading(String font, String heading, int lines, double width) {
    final u = widget.layout.u;
    final style = TextStyle(
      inherit: false,
      color: lampColor,
      fontSize: 0.032 * u,
      fontFamily: font,
      height: 1.2,
    );
    if (_lang == 'ja' || _lang == 'zh') {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(heading, maxLines: 1, style: style),
      );
    }
    return Text(
      heading,
      maxLines: 2,
      textAlign: TextAlign.center,
      style: style,
    );
  }

  /// The close button: a square tap area whose top-right part holds the visible round mark.
  /// It is placed in the banner's box, which is as wide as the screen and starts above the card.
  Widget _closeButton(String closeLabel) {
    final l = widget.layout;
    final u = l.u;
    final inset = l.cardInset;
    final tap = l.closeAreaSize;
    final sideMargin = (l.screenWidth - l.cardWidth) / 2;
    final circleCenterX = sideMargin + l.cardWidth - inset - 0.03 * u;
    // The tap area reaches a little past the card's right edge, but never past the screen.
    final right = math.min(circleCenterX + 0.0775 * u, l.screenWidth);
    final bottom = l.closeAreaOverhang + l.closeAreaBottomFromCardTop;
    final left = right - tap;
    final top = bottom - tap;
    final circleLeft = (circleCenterX - 0.03 * u) - left;
    final circleTop = (l.closeAreaOverhang + inset) - top;
    return Positioned(
      key: const ValueKey('promoClose'),
      left: left,
      top: top,
      width: tap,
      height: tap,
      child: Semantics(
        button: true,
        label: closeLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_handleDismiss()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: circleLeft,
                top: circleTop,
                width: 0.06 * u,
                height: 0.06 * u,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lampColor, width: 0.004 * u),
                  ),
                  child: Center(
                    child: Icon(Icons.close, size: 0.036 * u, color: whiteColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The close button: the notice goes at once; the count, the day and the event follow.
  Future<void> _handleDismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    // Read what the event needs before the notice leaves the tree
    final pattern = _pattern;
    final position = _videoKey.currentState?.currentElapsed ?? Duration.zero;
    final seen = _patternsSeen;
    final visible = DateTime.now().difference(_openedAt);
    final shown = _shown!;
    final lang = _lang;
    final firstPattern = _firstPattern;
    final videoMode = _videoMode;
    final bodyForm = widget.plan.bodyForm;
    final isPremium = widget.isPremium;
    widget.onDismiss();
    final count = await PromoPrefs.recordAdventureDismiss(now: DateTime.now());
    final info = await shown;
    unawaited(
      AnalyticsManager.crossPromoDismissed(
        placement: 'menu',
        isPremium: isPremium,
        lang: lang,
        launchCount: info.launchCount,
        rideCount: info.rideCount,
        daysSinceFirstLaunch: info.daysSinceFirstLaunch,
        shownCount: info.shownCount,
        firstPattern: firstPattern,
        videoMode: videoMode,
        bodyForm: bodyForm,
        dismissCount: '$count',
        videoPattern: pattern,
        videoPosition: videoPositionBucket(position),
        patternsSeen: patternsSeenBucket(seen),
        visible: visibleBucket(visible),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.layout;
    final plan = widget.plan;
    final u = l.u;
    final column = l.columnWidth;
    final font = context.font();
    final name = context.promoAdventureName();
    final button = context.promoButton();
    final separator = switch (_lang) {
      'ja' => '、',
      'zh' => '，',
      _ => ', ',
    };
    final body = plan.body;
    final label = [
      plan.heading,
      name,
      if (body != null) body.replaceAll('\n', ''),
      button,
    ].join(separator);

    final logoWidth = math.min(column - 0.04 * u, 0.35 * u);
    final logoHeight = logoWidth / 3.541;
    final headingHeight = plan.headingLines * 0.032 * u * 1.2;
    final bodyHeight = (body == null ? 0.0 : plan.bodyLines * 0.033 * u * 1.2);
    final gap = plan.gap;

    final content = SizedBox(
      width: column,
      height: l.videoHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The column starts under the close button
          SizedBox(height: 0.08 * u),
          Listener(
            onPointerDown: (_) => _press('text'),
            child: SizedBox(
              width: column,
              height: headingHeight,
              child: _heading(font, plan.heading, plan.headingLines, column),
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            width: column,
            height: logoHeight,
            child: Listener(
              onPointerDown: (_) => _press('text'),
              child: Center(
                child: SizedBox(
                  width: logoWidth,
                  height: logoHeight,
                  child: Image.asset(
                    'assets/images/promo/adventure_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          if (body != null) ...[
            Listener(
              onPointerDown: (_) => _press('text'),
              child: SizedBox(
                width: column,
                height: bodyHeight,
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    inherit: false,
                    color: whiteColor,
                    fontSize: 0.033 * u,
                    fontFamily: font,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: gap),
          ],
          SizedBox(
            width: column,
            height: 0.065 * u,
            child: Center(child: _buttonFace(column, font, button)),
          ),
          SizedBox(height: gap / 2),
        ],
      ),
    );

    // The box is as wide as the screen and taller than the card by the overhang, so the whole tap area is inside it.
    final cardHeight = l.cardHeight;
    final sideMargin = (l.screenWidth - l.cardWidth) / 2;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: SizedBox(
        width: l.screenWidth,
        height: cardHeight + l.closeAreaOverhang,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: const ValueKey('promoCard'),
              top: l.closeAreaOverhang,
              left: sideMargin,
              width: l.cardWidth,
              height: cardHeight,
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
                      // The border is drawn inside the box, so the padding is the rest of the inset.
                      padding: EdgeInsets.all(l.screenHeight * 0.01),
                      decoration: BoxDecoration(
                        color: darkBlackColor,
                        border: Border.all(color: lampColor, width: 0.006 * u),
                        borderRadius: BorderRadius.circular(0.026 * u),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _videoBox(l.videoWidth, l.videoHeight),
                          SizedBox(width: 0.025 * u),
                          content,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _closeButton(context.promoClose()),
          ],
        ),
      ),
    );
  }
}
