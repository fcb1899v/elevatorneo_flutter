// Floor panels: only the window's floors are built, with the same pictures and positions as before.
// Drawn on an iPhone 17 Pro size (402 x 874 points at 3x).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/floor_image_store.dart';
import 'package:letselevatorneo/floor_window.dart';
import 'package:letselevatorneo/homepage.dart';

const double screenWidth = 402;
const double screenHeight = 874;

/// The providers handed to the panels, built from the car's style (not from its inside path)
final Map<String, ImageProvider> providers = initialFloorImages
    .floorImageProviders(initialBackgroundStyle, roomCacheWidth(293.46, 3));

/// Every Image on screen must use the provider from the shared map, not a fallback built on the spot
void expectSharedProviders(WidgetTester tester) {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  expect(images, isNotEmpty);
  for (final image in images) {
    final name = (image.image as AssetImage).assetName;
    expect(providers.containsKey(name), isTrue, reason: name);
    expect(identical(image.image, providers[name]), isTrue, reason: name);
  }
}

/// Pumps only the moving column, in a screen of the size above
Future<void> pumpColumn(
  WidgetTester tester, {
  required int counter,
  required int currentFloor,
  required bool isOutside,
  required double margin,
}) async {
  tester.view.physicalSize = const Size(screenWidth * 3, screenHeight * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery.fromView(
        view: tester.view,
        child: Builder(
          builder: (context) {
            final home = HomeWidget(
              context,
              floorNumbers: initialFloorNumbers,
              floorStops: initialFloorStops,
              floorImages: initialFloorImages,
              imageProviders: providers,
              buttonStyle: initialButtonStyle,
              buttonShape: initialButtonShape,
              glassStyle: initialGlassStyle,
              backgroundStyle: initialBackgroundStyle,
              isGamesSignIn: false,
              isConnectedInternet: false,
              point: 0,
            );
            return Stack(
              children: [
                home.floorImagesWidget(
                  currentFloorNumber: currentFloor,
                  counter: counter,
                  screenHeight: context.height(),
                  isOutside: isOutside,
                  margin: margin,
                  duration: 0,
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// The asset path each Image in a floor's panel shows, picture first
List<String> panelAssets(WidgetTester tester, int floor, int count) {
  final key = ValueKey(panelKey(floor, count));
  return [
    for (final image in tester.widgetList<Image>(
      find.descendant(of: find.byKey(key), matching: find.byType(Image)),
    ))
      (image.image as AssetImage).assetName,
  ];
}

void main() {
  testWidgets(
    "T11: the car's column builds five panels, with the window's pictures and positions",
    (tester) async {
      // Counter 1 with the car's view: the column's top is the old margin for floor 1
      const width = screenWidth;
      final margin = (0.045 + 0.145) * width - 162 * 1.57 * width;
      await pumpColumn(
        tester,
        counter: 1,
        currentFloor: 1,
        isOutside: false,
        margin: margin,
      );

      expectSharedProviders(tester);

      // Floor 1's picture starts at 0.19 W, as it did before the change
      final pictureTop = tester.getTopLeft(
        find
            .descendant(
              of: find.byKey(ValueKey(panelKey(1, 5))),
              matching: find.byType(Image),
            )
            .first,
      );
      expect(pictureTop.dy, closeTo(0.19 * width, 0.01));
      expect(pictureTop.dx, closeTo(0.023 * width, 0.01));

      // Buttonless floors show the plain floor picture, button floors show their own room
      expect(panelAssets(tester, -2, 5).first, imageFloor);
      expect(panelAssets(tester, 3, 5).first, imageFloor);
      expect(
        panelAssets(tester, -1, 5).first,
        initialFloorImages[initialFloorNumbers.indexOf(-1)],
      );
      expect(
        panelAssets(tester, 2, 5).first,
        initialFloorImages[initialFloorNumbers.indexOf(2)],
      );
    },
  );

  testWidgets("T12: five panels are two images each, ten images in all", (
    tester,
  ) async {
    const width = screenWidth;
    final margin = (0.045 + 0.145) * width - 162 * 1.57 * width;
    await pumpColumn(
      tester,
      counter: 1,
      currentFloor: 1,
      isOutside: false,
      margin: margin,
    );
    expectSharedProviders(tester);
    expect(find.byType(Image), findsNWidgets(10));
    // The column's own AnimatedPositioned is a Positioned too, so count only the keyed panels
    expect(
      find.byWidgetPredicate((w) => w is Positioned && w.key is ValueKey),
      findsNWidgets(5),
    );
  });

  testWidgets(
    "T13: the hall's column shows the car's picture only at the car's floor",
    (tester) async {
      final inside = initialBackgroundStyle.insideElevator();

      // Counter 2 is in the window, so floor 2 shows the car's inside picture
      await pumpColumn(
        tester,
        counter: 2,
        currentFloor: 2,
        isOutside: true,
        margin: 0,
      );
      expectSharedProviders(tester);
      expect(panelAssets(tester, 2, 5).first, inside);
      expect(panelAssets(tester, 1, 5).first, imageDark);
      expect(panelAssets(tester, 4, 5).first, imageDark);

      // Counter 10: floorIndex(10) is 21, so the window is indexes 19 to 23, which is floors 8 to 12
      await pumpColumn(
        tester,
        counter: 10,
        currentFloor: 2,
        isOutside: true,
        margin: 0,
      );
      expectSharedProviders(tester);
      final lower = hallLowerOffset(screenHeight / screenWidth);
      final window = floorWindow(10, lower, floorWindowUpperOffset);
      expect(window, [8, 9, 10, 11, 12]);
      // Exactly those five floors are built, found by their panel keys
      final keys = {for (final f in window) panelKey(f, 5)};
      final built = tester.widgetList<Positioned>(
        find.byWidgetPredicate((w) => w is Positioned && w.key is ValueKey),
      );
      expect(built.length, 5);
      expect({for (final p in built) (p.key as ValueKey).value}, keys);
      // The car's picture is not there at all
      final assets = [
        for (final image in tester.widgetList<Image>(find.byType(Image)))
          (image.image as AssetImage).assetName,
      ];
      expect(assets.contains(inside), isFalse);
      expect(assets.every((a) => a == imageDark), isTrue);
    },
  );

  test("The shared map holds the room pictures, the two bands and the car's inside, and nothing else", () {
    final expected = {
      ...initialFloorImages,
      imageFloor,
      imageDark,
      initialBackgroundStyle.insideElevator(),
    };
    expect(providers.keys.toSet(), expected);
    // Every key is a real asset path, not a path with the car's inside path wrapped twice
    for (final key in providers.keys) {
      expect(key.contains('.png.png'), isFalse, reason: key);
      expect(key.contains('inside_assets'), isFalse, reason: key);
    }
  });

  testWidgets(
    "The store reads every picture of the shared map without a failure",
    (tester) async {
      final messages = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          messages.add(message ?? '');
      addTearDown(() => debugPrint = original);

      final store = FloorImageStore();
      await tester.runAsync(() async {
        await store.hold(providers, ImageConfiguration.empty);
        // Reading is done when hold completes; a failed read would have been printed by then
      });
      expect(messages.where((m) => m.contains('Floor image failed')), isEmpty);
    },
  );
}
