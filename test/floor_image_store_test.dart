// Floor image store: photos are decoded to the photo width, and a held set is not read again.
// The photos are written to a temporary folder made by the test and removed at the end.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/floor_image_store.dart';

/// Writes a plain PNG of the given size; its name has image_cropper, so it is read as a photo
Future<String> writePhoto(Directory dir, String name, int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return file.path;
}

void main() {
  testWidgets("T20: a 3213 x 5712 photo is held at the photo width, and at its full size without it", (tester) async {
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('floor_photo_')))!;
    try {
      final path = (await tester.runAsync(() => writePhoto(dir, 'image_cropper_big.png', 3213, 5712)))!;
      const width = 1321;
      final store = FloorImageStore();
      const configuration = ImageConfiguration();

      imageCache.clear();
      imageCache.clearLiveImages();
      await tester.runAsync(() => store.hold(
        {path.providerKey(width): path.imageProvider(photoWidth: width)},
        configuration,
      ));
      debugPrint("T20 decode width $width: ${imageCache.currentSizeBytes} bytes, live ${imageCache.liveImageCount}");
      expect(imageCache.currentSizeBytes, 12406832);
      expect(imageCache.liveImageCount, 1);

      await tester.runAsync(() => store.hold({}, configuration));
      imageCache.clear();
      imageCache.clearLiveImages();
      await tester.runAsync(() => store.hold(
        {path: path.imageProvider()},
        configuration,
      ));
      debugPrint("T20 full size: ${imageCache.currentSizeBytes} bytes, live ${imageCache.liveImageCount}");
      expect(imageCache.currentSizeBytes, 73410624);
      await tester.runAsync(() => store.hold({}, configuration));
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  testWidgets("T21: a replaced picture is released, and a held set is not read again", (tester) async {
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('floor_photo_')))!;
    try {
      final a = (await tester.runAsync(() => writePhoto(dir, 'image_cropper_a.png', 40, 71)))!;
      final b = (await tester.runAsync(() => writePhoto(dir, 'image_cropper_b.png', 41, 72)))!;
      final c = (await tester.runAsync(() => writePhoto(dir, 'image_cropper_c.png', 42, 73)))!;
      const width = 100;
      const configuration = ImageConfiguration();
      final store = FloorImageStore();
      imageCache.clear();
      imageCache.clearLiveImages();

      Map<String, ImageProvider> set(List<String> paths) => {
        for (final p in paths) p.providerKey(width): p.imageProvider(photoWidth: width),
      };

      await tester.runAsync(() => store.hold(set([a, b]), configuration));
      expect(imageCache.liveImageCount, 2);

      await tester.runAsync(() => store.hold(set([a, c]), configuration));
      expect(imageCache.liveImageCount, 2);

      // The same set again: every picture is already held, so nothing is read and the size stays
      final sizeBefore = imageCache.currentSizeBytes;
      await tester.runAsync(() => store.hold(set([a, c]), configuration));
      expect(imageCache.liveImageCount, 2);
      expect(imageCache.currentSizeBytes, sizeBefore);

      await tester.runAsync(() => store.hold({}, configuration));
      expect(imageCache.liveImageCount, 0);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
