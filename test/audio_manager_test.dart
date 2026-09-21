// stopAudio before any player exists: a lifecycle pause can arrive before the first sound.
// It must neither throw nor log a failure.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/audio_manager.dart';

void main() {
  test("stopAudio with no player returns quietly", () async {
    final logs = <String>[];
    await runZoned(() => AudioManager().stopAudio(),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => logs.add(line)));
    expect(logs.where((l) => l.contains("Stop audio failed")), isEmpty);
    // Control: the log capture does catch a print in this zone
    // ignore: avoid_print
    runZoned(() => print("Stop audio failed: probe"),
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => logs.add(line)));
    expect(logs, ["Stop audio failed: probe"]);
  });
}
