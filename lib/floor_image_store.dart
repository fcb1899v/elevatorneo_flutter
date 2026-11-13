// ===== FloorImageStore: holds the few images the moving floor column shows =====
// One store for the whole app, so a rebuilt home screen does not read every image again.

import 'dart:async';
import 'package:flutter/widgets.dart';

/// The one store for the whole app.
/// It keeps the images read by the last [FloorImageStore.hold].
final floorImageStore = FloorImageStore();

class FloorImageStore {
  final Map<String, _Held> _held = {};

  /// Holds exactly the images in [wanted], keyed by their path (and decode width for a photo).
  /// Releases the others, reads the missing ones, and completes when every wanted image is read or has failed.
  Future<void> hold(Map<String, ImageProvider> wanted, ImageConfiguration configuration) async {
    for (final path in _held.keys.toList()) {
      if (!wanted.containsKey(path)) _held.remove(path)!.release();
    }
    final waits = <Future<void>>[];
    wanted.forEach((path, provider) {
      final held = _held[path] ?? _start(path, provider, configuration);
      waits.add(held.ready.future);
    });
    await Future.wait(waits);
  }

  /// Starts reading one image and keeps a listener on it, so the image stays in the cache.
  _Held _start(String path, ImageProvider provider, ImageConfiguration configuration) {
    final ready = Completer<void>();
    final stream = provider.resolve(configuration);
    final listener = ImageStreamListener(
      (info, _) {
        info.dispose();
        if (!ready.isCompleted) ready.complete();
      },
      onError: (error, _) {
        debugPrint("Floor image failed: $path: $error");
        if (!ready.isCompleted) ready.complete();
      },
    );
    final held = _Held(stream, listener, ready);
    _held[path] = held;
    stream.addListener(listener);
    return held;
  }
}

class _Held {
  _Held(this.stream, this.listener, this.ready);
  final ImageStream stream;
  final ImageStreamListener listener;
  final Completer<void> ready;

  /// Removes the listener.
  /// A read still in progress counts as finished.
  void release() {
    stream.removeListener(listener);
    if (!ready.isCompleted) ready.complete();
  }
}
