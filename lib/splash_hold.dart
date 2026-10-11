import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// The shortest time the launch splash stays on screen, counted from the start of main().
const splashMinDuration = Duration(seconds: 3);

/// Background and image of the launch splash.
/// They match the iOS launch screen; its colour set is display-p3, and the colour here is the sRGB equivalent.
const splashColor = Color(0xFFF7B249);
const splashImageAsset = 'assets/icon/icon.png';
const splashImageSize = 256.0;

/// Keeps the launch splash up for at least [minDuration] after launch.
/// iOS keeps the native splash (FlutterNativeSplash.preserve); Android shows [SplashOverlay] as the first Flutter frame.
/// When initialization already took that long, [removeWhenReady] removes it at once.
class SplashHold {
  /// [elapsed], [delay] and [remove] can be replaced in tests.
  SplashHold({
    this.minDuration = splashMinDuration,
    this.elapsed,
    Future<void> Function(Duration)? delay,
    void Function()? remove,
  })  : _delay = delay ?? Future<void>.delayed,
        _remove = remove ?? FlutterNativeSplash.remove;

  final Duration minDuration;
  final Duration Function()? elapsed;
  final Future<void> Function(Duration) _delay;
  final void Function() _remove;
  final Stopwatch _stopwatch = Stopwatch();
  bool _removed = false;

  /// True while the Flutter splash covers the app.
  /// [SplashOverlay] listens to it.
  final ValueNotifier<bool> visible = ValueNotifier<bool>(true);

  /// The splash image, decoded before runApp so the very first frame already has it.
  ui.Image? image;

  /// Starts the clock.
  /// Call it first in main(), right before FlutterNativeSplash.preserve.
  void start() => _stopwatch.start();

  /// Decodes [splashImageAsset] for [SplashOverlay].
  /// Failure leaves the plain background.
  Future<void> loadImage() async {
    try {
      final data = await rootBundle.load(splashImageAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      image = (await codec.getNextFrame()).image;
    } catch (e) {
      debugPrint('Splash image: $e');
    }
  }

  /// Time still to wait before the splash may go: never negative.
  Duration remaining() {
    final left = minDuration - (elapsed?.call() ?? _stopwatch.elapsed);
    return left > Duration.zero ? left : Duration.zero;
  }

  /// Completes once the splash is gone, at once if it already is.
  Future<void> whenRemoved() {
    if (!visible.value) return Future.value();
    final done = Completer<void>();
    void onChange() {
      if (visible.value) return;
      visible.removeListener(onChange);
      done.complete();
    }
    visible.addListener(onChange);
    return done.future;
  }

  /// Waits out the remaining time, then removes the splash once.
  /// It touches no widget, so it is safe to finish after the caller was disposed.
  Future<void> removeWhenReady() async {
    if (_removed) return;
    _removed = true;
    final wait = remaining();
    if (wait > Duration.zero) await _delay(wait);
    _remove();
    visible.value = false;
  }
}

/// The app-wide instance used by main() and the first page.
final splashHold = SplashHold();

/// Android only: draws the splash over [child] until [SplashHold.visible] turns false.
/// iOS returns [child] as is, because its native splash is still up.
class SplashOverlay extends StatelessWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return child;
    return Stack(
      fit: StackFit.expand,
      textDirection: TextDirection.ltr,
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: splashHold.visible,
          builder: (context, visible, _) => visible
              ? AbsorbPointer(
                  child: ColoredBox(
                    color: splashColor,
                    child: Center(
                      child: RawImage(
                        image: splashHold.image,
                        width: splashImageSize,
                        height: splashImageSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
