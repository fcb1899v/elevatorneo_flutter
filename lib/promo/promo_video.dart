/// Plays the silent promo videos as animated WebP files, without a video plugin.
///
/// Frames are decoded with dart:ui, so no audio session is touched.
/// Patterns play one after another and the list repeats from the first one.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../extension.dart';

/// Returns the bytes of an asset by its name, such as `p1` or `p1_still`.
typedef PromoAssetLoader = Future<Uint8List> Function(String name);

/// Shows a silent promo video made of animated WebP patterns.
///
/// The first frame of [firstPattern] is shown as a still until the animation starts.
/// The widget stops when it is removed, when its [TickerMode] is off or when the app is not in front.
/// It shows only the still when [stillOnly] is true or when the device asks for less motion.
///
/// Read the state with a [GlobalKey] of [PromoVideoState] to get the current pattern and its elapsed time.
class PromoVideo extends StatefulWidget {
  /// Creates a promo video that plays [patterns] in order, starting from [firstPattern].
  const PromoVideo({
    super.key,
    required this.patterns,
    required this.firstPattern,
    required this.loadPattern,
    required this.loadStill,
    this.stillOnly = false,
    this.onPatternChanged,
    this.onPatternEnded,
    @visibleForTesting this.clock,
  });

  /// Pattern names in play order, such as `['p1', 'p2', 'p3']`.
  final List<String> patterns;

  /// The pattern to play first.
  ///
  /// The first pattern of [patterns] is used when this name is not in the list.
  /// Nothing is played when [patterns] is empty.
  final String firstPattern;

  /// Loads the animated WebP of a pattern by its name.
  final PromoAssetLoader loadPattern;

  /// Loads the still image by its name, which is the pattern name with `_still` added.
  final PromoAssetLoader loadStill;

  /// Whether to show only the still and never play the animation.
  final bool stillOnly;

  /// Called with the pattern name when a pattern's first frame is shown.
  final ValueChanged<String>? onPatternChanged;

  /// Called once for each run of a pattern.
  ///
  /// [completed] is true after the last frame.
  /// It is false when the widget is removed before that.
  /// A pause because the app or the [TickerMode] is off does not end the run.
  /// A pattern that cannot be decoded is reported as not completed and the next one is played.
  final void Function(String pattern, bool completed)? onPatternEnded;

  /// Replaces the clock that frames are scheduled against. Used only by tests.
  @visibleForTesting
  final Duration Function()? clock;

  @override
  State<PromoVideo> createState() => PromoVideoState();
}

/// The state of [PromoVideo]. Its getters can be read from outside with a [GlobalKey].
class PromoVideoState extends State<PromoVideo> with WidgetsBindingObserver {
  /// Index of the pattern being loaded or played.
  int _pattern = 0;

  /// Index of the pattern on screen.
  int _shownPattern = 0;

  ui.Image? _image;
  ui.Codec? _codec;
  int _frameCount = 0;
  int _frameIndex = 0;
  Duration _elapsed = Duration.zero;
  int _patternsPlayed = 0;

  bool _running = false;
  bool _loopAlive = false;
  bool _disposed = false;
  bool _appFront = true;
  bool _tickerOn = true;
  bool _reduceMotion = false;
  bool _stillMode = false;
  bool _frameShown = false;
  int _stillToken = 0;
  Timer? _timer;
  Completer<bool>? _waitCompleter;

  final Stopwatch _stopwatch = Stopwatch()..start();

  /// When the first frame of the current pattern was shown, shifted by the time spent paused.
  Duration _patternStart = Duration.zero;

  /// When the animation was paused, or null while it is not paused.
  Duration? _pausedAt;

  /// The next frame of the current pattern, decoded while the current one is held.
  Future<ui.FrameInfo>? _nextFrame;

  /// The number of patterns in a row that failed before showing any frame.
  int _failStreak = 0;

  /// Whether every pattern failed in a round, so the animation does not start again.
  bool _failed = false;

  /// The name of the pattern on screen now.
  String get currentPattern =>
      widget.patterns.isEmpty ? '' : widget.patterns[_shownPattern];

  /// The time played in the current pattern, counted from the frames shown so far.
  Duration get currentElapsed => _elapsed;

  /// The number of patterns that started since the widget was opened.
  int get patternsPlayed => _patternsPlayed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appFront = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    final first = widget.patterns.indexOf(widget.firstPattern);
    _pattern = first < 0 ? 0 : first;
    _shownPattern = _pattern;
    unawaited(_loadStill());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
    _tickerOn = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appFront = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _reportUnfinished();
    _stop();
    if (!_loopAlive) _releaseCodec();
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.expand(
        child: RawImage(image: _image, fit: BoxFit.contain),
      ),
    );
  }

  /// Starts or stops the animation to match the current conditions.
  void _sync() {
    if (_disposed) return;
    final motionOff = widget.stillOnly || _reduceMotion;
    if (motionOff) {
      _stop();
      if (!_stillMode) {
        _stillMode = true;
        _frameShown = false;
        unawaited(_loadStill());
      }
      return;
    }
    _stillMode = false;
    if (_appFront && _tickerOn) {
      _start();
    } else {
      _stop();
    }
  }

  Duration _now() => widget.clock?.call() ?? _stopwatch.elapsed;

  void _start() {
    if (_disposed || _failed || widget.patterns.isEmpty) return;
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedAt = null;
      _patternStart += _now() - pausedAt;
    }
    _running = true;
    if (!_loopAlive) unawaited(_loop());
  }

  /// Pauses the animation. The pattern resumes from where it stopped.
  void _stop() {
    if (!_running) return;
    _running = false;
    _pausedAt = _now();
    _timer?.cancel();
    _timer = null;
    final waiting = _waitCompleter;
    _waitCompleter = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete(false);
  }

  /// Reports the pattern that is cut off before its last frame as not completed.
  void _reportUnfinished() {
    if (_codec == null || _frameIndex == 0) return;
    widget.onPatternEnded?.call(widget.patterns[_pattern], false);
  }

  /// Shows the still of the pattern on screen, unless a frame is already on screen.
  Future<void> _loadStill() async {
    if (widget.patterns.isEmpty) return;
    final token = ++_stillToken;
    final bytes = await widget.loadStill(
      '${widget.patterns[_shownPattern]}_still',
    );
    if (!mounted || token != _stillToken) return;
    if (_frameShown && !_stillMode) return;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted || token != _stillToken || (_frameShown && !_stillMode)) {
      frame.image.dispose();
      return;
    }
    _show(frame.image);
  }

  /// Plays frames until the loop is stopped. Only one loop runs at a time.
  ///
  /// Each frame is shown at the pattern's start plus the lengths of the frames before it.
  /// The time spent decoding therefore does not slow the animation down.
  Future<void> _loop() async {
    _loopAlive = true;
    try {
      while (_running) {
        try {
          if (_codec == null) {
            final bytes = await widget.loadPattern(widget.patterns[_pattern]);
            if (_disposed) break;
            final codec = await ui.instantiateImageCodec(bytes);
            if (_disposed) {
              codec.dispose();
              break;
            }
            _codec = codec;
            _frameCount = codec.frameCount;
            _frameIndex = 0;
          }
          if (_frameIndex == 0) {
            final frame = await _codec!.getNextFrame();
            if (_disposed) {
              frame.image.dispose();
              break;
            }
            _patternStart = _now();
            if (_pausedAt != null) _pausedAt = _patternStart;
            _showFrame(frame.image, frame.duration);
          } else if (_frameIndex < _frameCount) {
            // Decode the next frame while the current one is held.
            _nextFrame ??= _codec!.getNextFrame()..ignore();
            if (!await _waitUntilDue() || !_running) break;
            final frame = await _nextFrame!;
            _nextFrame = null;
            if (_disposed) {
              frame.image.dispose();
              break;
            }
            _showFrame(frame.image, frame.duration);
          } else {
            if (!await _waitUntilDue() || !_running) break;
            _finishPattern();
          }
        } catch (e) {
          if (_disposed) break;
          _abandonPattern(e);
          if (_failed) break;
        }
      }
    } finally {
      _loopAlive = false;
      if (_disposed) {
        _releaseCodec();
      } else if (_running) {
        _start();
      }
    }
  }

  /// Gives up the pattern that cannot be decoded and moves on to the next one.
  ///
  /// The last image stays on screen.
  /// The animation stops for good when a whole round of patterns fails without showing a frame.
  void _abandonPattern(Object error) {
    final name = widget.patterns[_pattern];
    'PromoVideo: decode error in $name: $error'.debugPrint();
    if (_frameIndex == 0) _failStreak++;
    _releaseCodec();
    _frameIndex = 0;
    _pattern = (_pattern + 1) % widget.patterns.length;
    if (_failStreak >= widget.patterns.length) {
      _failed = true;
      _running = false;
    }
    widget.onPatternEnded?.call(name, false);
  }

  /// Shows a frame of the pattern and counts it toward the pattern's elapsed time.
  void _showFrame(ui.Image image, Duration duration) {
    if (_frameIndex == 0) {
      _shownPattern = _pattern;
      _elapsed = Duration.zero;
      _patternsPlayed++;
      _frameShown = true;
      widget.onPatternChanged?.call(widget.patterns[_pattern]);
    }
    _elapsed += duration;
    _frameIndex++;
    _failStreak = 0;
    _show(image);
  }

  void _finishPattern() {
    final name = widget.patterns[_pattern];
    _releaseCodec();
    _frameIndex = 0;
    _pattern = (_pattern + 1) % widget.patterns.length;
    widget.onPatternEnded?.call(name, true);
  }

  /// Waits until the frame after the ones shown so far is due.
  ///
  /// Returns at once when it is already due. Returns false when the wait is stopped early.
  Future<bool> _waitUntilDue() {
    final remaining = _patternStart + _elapsed - _now();
    if (remaining <= Duration.zero) return Future.value(_running);
    return _wait(remaining);
  }

  /// Waits for [duration]. Returns false when the wait is stopped early.
  Future<bool> _wait(Duration duration) {
    final completer = Completer<bool>();
    _waitCompleter = completer;
    _timer = Timer(duration, () {
      _timer = null;
      _waitCompleter = null;
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  void _show(ui.Image image) {
    if (!mounted) {
      image.dispose();
      return;
    }
    final old = _image;
    setState(() => _image = image);
    old?.dispose();
  }

  /// Releases the codec, after the frame still being decoded has finished.
  void _releaseCodec() {
    final codec = _codec;
    final pending = _nextFrame;
    _codec = null;
    _nextFrame = null;
    if (pending == null) {
      codec?.dispose();
      return;
    }
    pending.then((frame) {
      frame.image.dispose();
      codec?.dispose();
    }, onError: (Object _) => codec?.dispose());
  }
}
