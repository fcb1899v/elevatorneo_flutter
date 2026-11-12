// Checks that every bundled promo WebP decodes on every frame, because a frame the engine cannot decode stops the video.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_config.dart';

void main() {
  for (final name in PromoConfig.allPatterns) {
    testWidgets('promo animation $name decodes every frame at 640x360', (tester) async {
      final bytes = (await rootBundle.load('assets/images/promo/$name.webp')).buffer.asUint8List();
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          var totalMs = 0;
          for (var i = 0; i < codec.frameCount; i++) {
            final frame = await codec.getNextFrame();
            final image = frame.image;
            expect(image.width, 640, reason: '$name frame ${i + 1} width');
            expect(image.height, 360, reason: '$name frame ${i + 1} height');
            totalMs += frame.duration.inMilliseconds;
            image.dispose();
          }
          debugPrint('$name: frames=${codec.frameCount} total=${totalMs}ms');
        } finally {
          codec.dispose();
        }
      });
    });

    testWidgets('promo still ${name}_still decodes at 640x360', (tester) async {
      final bytes = (await rootBundle.load('assets/images/promo/${name}_still.webp')).buffer.asUint8List();
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(bytes);
        try {
          expect(codec.frameCount, 1, reason: '${name}_still frame count');
          final frame = await codec.getNextFrame();
          expect(frame.image.width, 640, reason: '${name}_still width');
          expect(frame.image.height, 360, reason: '${name}_still height');
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
      });
    });
  }
}
