import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/promo/promo_layout.dart';

// The NEO admobHeight(), used for the unpurchased bottom row.
double _admobHeight(double height) =>
    height < 600 ? 50 : (height < 1000 ? height / 8 - 25 : 100);

class _Row {
  const _Row({
    required this.name,
    required this.width,
    required this.height,
    required this.topInset,
    required this.bottomInset,
    required this.videoWidth,
    required this.videoHeight,
    required this.columnWidth,
    this.cardWidth,
  });

  final String name;
  final double width;
  final double height;
  final double topInset;
  final double bottomInset;
  final double videoWidth;
  final double videoHeight;
  final double columnWidth;

  /// Only the unpurchased rows list the card width in the spec table.
  final double? cardWidth;
}

// Unpurchased rows of the spec table (section 7), in points.
const _unpurchased = <_Row>[
  _Row(name: 'iPhone SE 1st', width: 320, height: 568, topInset: 20, bottomInset: 0,
    cardWidth: 308.6, videoWidth: 163.2, videoHeight: 217.5, columnWidth: 123.6),
  _Row(name: 'iPhone SE 2nd-3rd', width: 375, height: 667, topInset: 20, bottomInset: 0,
    cardWidth: 361.7, videoWidth: 194.5, videoHeight: 259.3, columnWidth: 141.5),
  _Row(name: 'iPhone 13 mini', width: 375, height: 812, topInset: 50, bottomInset: 34,
    cardWidth: 358.8, videoWidth: 222.8, videoHeight: 297.0, columnWidth: 105.9),
  _Row(name: 'iPhone 16e', width: 390, height: 844, topInset: 47, bottomInset: 34,
    cardWidth: 373.1, videoWidth: 231.7, videoHeight: 308.9, columnWidth: 110.1),
  _Row(name: 'iPhone 17 Pro', width: 402, height: 874, topInset: 62, bottomInset: 34,
    cardWidth: 384.5, videoWidth: 238.7, videoHeight: 318.2, columnWidth: 113.5),
  _Row(name: 'iPhone 11', width: 414, height: 896, topInset: 44, bottomInset: 34,
    cardWidth: 396.1, videoWidth: 246.0, videoHeight: 327.9, columnWidth: 116.9),
  _Row(name: 'iPhone 17 Pro Max', width: 440, height: 956, topInset: 62, bottomInset: 34,
    cardWidth: 420.9, videoWidth: 261.3, videoHeight: 348.3, columnWidth: 124.2),
  _Row(name: 'iPad 5th-6th', width: 768, height: 1024, topInset: 20, bottomInset: 0,
    cardWidth: 558.1, videoWidth: 298.8, videoHeight: 398.4, columnWidth: 219.9),
  _Row(name: 'iPad (A16)', width: 820, height: 1180, topInset: 24, bottomInset: 20,
    cardWidth: 643.1, videoWidth: 355.0, videoHeight: 473.4, columnWidth: 242.6),
  _Row(name: 'iPad Pro 12.9', width: 1024, height: 1366, topInset: 24, bottomInset: 20,
    cardWidth: 744.5, videoWidth: 425.7, videoHeight: 567.5, columnWidth: 266.2),
  _Row(name: 'Android 360x640', width: 360, height: 640, topInset: 24, bottomInset: 48,
    cardWidth: 347.2, videoWidth: 183.8, videoHeight: 245.0, columnWidth: 138.8),
  _Row(name: 'Android 360x800', width: 360, height: 800, topInset: 24, bottomInset: 48,
    cardWidth: 344.0, videoWidth: 213.0, videoHeight: 284.1, columnWidth: 101.6),
  _Row(name: 'Android 412x915', width: 412, height: 915, topInset: 24, bottomInset: 48,
    cardWidth: 393.7, videoWidth: 243.8, videoHeight: 325.1, columnWidth: 116.3),
  _Row(name: 'Pixel 10 Pro (provisional)', width: 427, height: 952, topInset: 24, bottomInset: 48,
    cardWidth: 407.6, videoWidth: 252.3, videoHeight: 336.5, columnWidth: 120.5),
];

// Purchased rows of the spec table (section 7, second table).
// The card width is not listed.
const _purchased = <_Row>[
  _Row(name: 'iPhone SE 1st', width: 320, height: 568, topInset: 20, bottomInset: 0,
    videoWidth: 168.7, videoHeight: 224.9, columnWidth: 118.1),
  _Row(name: 'iPhone SE 2nd-3rd', width: 375, height: 667, topInset: 20, bottomInset: 0,
    videoWidth: 200.7, videoHeight: 267.6, columnWidth: 135.2),
  _Row(name: 'iPhone 13 mini', width: 375, height: 812, topInset: 50, bottomInset: 34,
    videoWidth: 216.5, videoHeight: 288.7, columnWidth: 112.1),
  _Row(name: 'iPhone 16e', width: 390, height: 844, topInset: 47, bottomInset: 34,
    videoWidth: 229.7, videoHeight: 306.3, columnWidth: 112.1),
  _Row(name: 'iPhone 17 Pro', width: 402, height: 874, topInset: 62, bottomInset: 34,
    videoWidth: 229.8, videoHeight: 306.4, columnWidth: 122.4),
  _Row(name: 'iPhone 11', width: 414, height: 896, topInset: 44, bottomInset: 34,
    videoWidth: 246.0, videoHeight: 327.9, columnWidth: 116.9),
  _Row(name: 'iPhone 17 Pro Max', width: 440, height: 956, topInset: 62, bottomInset: 34,
    videoWidth: 257.9, videoHeight: 343.9, columnWidth: 127.5),
  _Row(name: 'iPad 5th-6th', width: 768, height: 1024, topInset: 20, bottomInset: 0,
    videoWidth: 317.5, videoHeight: 423.4, columnWidth: 201.1),
  _Row(name: 'iPad (A16)', width: 820, height: 1180, topInset: 24, bottomInset: 20,
    videoWidth: 358.8, videoHeight: 478.4, columnWidth: 238.9),
  _Row(name: 'iPad Pro 12.9', width: 1024, height: 1366, topInset: 24, bottomInset: 20,
    videoWidth: 429.4, videoHeight: 572.5, columnWidth: 262.5),
  _Row(name: 'Android 360x640', width: 360, height: 640, topInset: 24, bottomInset: 48,
    videoWidth: 153.0, videoHeight: 204.0, columnWidth: 169.6),
  _Row(name: 'Android 360x800', width: 360, height: 800, topInset: 24, bottomInset: 48,
    videoWidth: 213.0, videoHeight: 284.1, columnWidth: 101.6),
  _Row(name: 'Android 412x915', width: 412, height: 915, topInset: 24, bottomInset: 48,
    videoWidth: 243.8, videoHeight: 325.1, columnWidth: 116.3),
  _Row(name: 'Pixel 10 Pro (provisional)', width: 427, height: 952, topInset: 24, bottomInset: 48,
    videoWidth: 252.3, videoHeight: 336.5, columnWidth: 120.5),
];

PromoLayout _unpurchasedLayout(_Row row) => PromoLayout(
      screenWidth: row.width,
      screenHeight: row.height,
      topInset: row.topInset,
      bottomRowHeight: _admobHeight(row.height),
    );

// Purchased: the bottom row is 0.075 x min(height, 1000) plus the bottom inset.
PromoLayout _purchasedLayout(_Row row) => PromoLayout(
      screenWidth: row.width,
      screenHeight: row.height,
      topInset: row.topInset,
      bottomRowHeight: 0.075 * (row.height < 1000 ? row.height : 1000) + row.bottomInset,
    );

void main() {
  group('unpurchased rows of the spec table', () {
    for (final row in _unpurchased) {
      test(row.name, () {
        final layout = _unpurchasedLayout(row);
        expect(layout.cardWidth, closeTo(row.cardWidth!, 1.0), reason: 'cardWidth');
        expect(layout.videoWidth, closeTo(row.videoWidth, 1.0), reason: 'videoWidth');
        expect(layout.videoHeight, closeTo(row.videoHeight, 1.0), reason: 'videoHeight');
        expect(layout.columnWidth, closeTo(row.columnWidth, 1.0), reason: 'columnWidth');
      });
    }
  });

  group('purchased rows of the spec table', () {
    for (final row in _purchased) {
      test(row.name, () {
        final layout = _purchasedLayout(row);
        expect(layout.videoWidth, closeTo(row.videoWidth, 1.0), reason: 'videoWidth');
        expect(layout.videoHeight, closeTo(row.videoHeight, 1.0), reason: 'videoHeight');
        expect(layout.columnWidth, closeTo(row.columnWidth, 1.0), reason: 'columnWidth');
      });
    }
  });

  test('u is the smaller of the width and half the height', () {
    expect(
        const PromoLayout(screenWidth: 320, screenHeight: 568, topInset: 0, bottomRowHeight: 0).u,
        closeTo(284, 1e-9));
    expect(
        const PromoLayout(screenWidth: 768, screenHeight: 1024, topInset: 0, bottomRowHeight: 0).u,
        closeTo(512, 1e-9));
  });

  test('the video is 3:4 and the card keeps the side gap', () {
    for (final row in [..._unpurchased, ..._purchased]) {
      final layout = _unpurchasedLayout(row);
      expect(layout.videoWidth / layout.videoHeight, closeTo(0.75, 1e-9), reason: row.name);
      expect(layout.cardWidth, lessThanOrEqualTo(row.width - 2 * layout.gap + 1e-9),
          reason: row.name);
      expect(layout.cardWidth, lessThanOrEqualTo(1.09 * layout.u + 1e-9), reason: row.name);
    }
  });

  test('the grid without a card is wider by the spec gap', () {
    const layout =
        PromoLayout(screenWidth: 375, screenHeight: 667, topInset: 20, bottomRowHeight: 0);
    expect(layout.gridHeightWithoutCard, closeTo(2 * 0.255 * 333.5 + 667 * 0.04, 1e-9));
  });
}
