/// Decides what the notice card shows, by measuring its text with the app's fonts.
///
/// The sizes come from `PromoLayout`; this file only counts lines and picks the body text.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'promo_layout.dart';

/// Japanese body phrases, cut at the places a line may break.
const List<String> jaBodyPhrases = [
  '好きなだけ、',
  '呼んで、',
  '乗って、',
  'ボタンを',
  '押して、',
  '高層ビルを',
  '冒険できる',
  '超リアルな',
  '3D',
  'エレベーター',
  'シミュレーター',
];

/// Japanese short body phrases.
const List<String> jaBodyShortPhrases = [
  '超リアルな',
  '3D',
  'エレベーター',
  'シミュレーター',
];

/// What the card shows. [showCard] is false when even the heading, logo and button do not fit.
class PromoCardPlan {
  const PromoCardPlan({
    required this.showCard,
    this.gap = 0,
    this.heading = '',
    this.body,
    this.bodyLines = 0,
    this.headingLines = 0,
    this.bodyForm = 'none',
  });

  /// Which body was shown: `full`, `short` or `none`. Sent with the shown event.
  final String bodyForm;

  /// Whether the card is drawn at all.
  final bool showCard;

  /// The space G between the card's rows.
  final double gap;

  /// The heading text.
  final String heading;

  /// The body text with the line breaks chosen, or null when no body fits.
  final String? body;

  /// Lines of [body].
  final int bodyLines;

  /// Lines of [heading].
  final int headingLines;
}

/// Fits the heading and the body into the column, and picks the first body that leaves G of at least 0.04u.
PromoCardPlan planPromoCard({
  required PromoLayout layout,
  required String lang,
  required String fontFamily,
  required String heading,
  required String body,
  required String bodyShort,
}) {
  final u = layout.u;
  final column = layout.columnWidth;
  final headingStyle = TextStyle(fontFamily: fontFamily, fontSize: 0.032 * u, height: 1.2);
  final bodyStyle = TextStyle(fontFamily: fontFamily, fontSize: 0.033 * u, height: 1.2);

  // Chinese and Japanese headings stay on one line and shrink instead; the others may take two.
  final oneLineHeading = lang == 'ja' || lang == 'zh';
  final headingLines = oneLineHeading ? 1 : _countLines(heading, headingStyle, column);
  if (headingLines > 2) {
    return const PromoCardPlan(showCard: false);
  }

  final logoWidth = math.min(column - 0.04 * u, 0.35 * u);
  final logoHeight = logoWidth / 3.541;
  final buttonHeight = 0.065 * u;
  final headingHeight = headingLines * 0.032 * u * 1.2;
  final fixed = 0.08 * u + headingHeight + logoHeight + buttonHeight;
  final room = layout.videoHeight;
  final minGap = 0.04 * u;

  for (final candidate in [body, bodyShort]) {
    final fit = _fitBody(lang, candidate, bodyStyle, column);
    final bodyHeight = fit.lines * 0.033 * u * 1.2;
    final gap = (room - fixed - bodyHeight) / 3.5;
    if (gap >= minGap) {
      return PromoCardPlan(
        showCard: true,
        gap: gap,
        heading: heading,
        body: fit.text,
        bodyLines: fit.lines,
        headingLines: headingLines,
        bodyForm: candidate == body ? 'full' : 'short',
      );
    }
  }

  // No body: the gaps are G, G and G/2 (2.5G in all).
  final gapNoBody = (room - fixed) / 2.5;
  if (gapNoBody >= minGap) {
    return PromoCardPlan(
      showCard: true,
      gap: gapNoBody,
      heading: heading,
      body: null,
      headingLines: headingLines,
    );
  }
  return const PromoCardPlan(showCard: false);
}

class _BodyFit {
  const _BodyFit(this.text, this.lines);

  final String text;
  final int lines;
}

/// Japanese breaks only between phrases; the other languages break where the text layout breaks.
_BodyFit _fitBody(String lang, String text, TextStyle style, double width) {
  if (lang != 'ja') {
    return _BodyFit(text, _countLines(text, style, width));
  }
  final phrases = text == jaBodyPhrases.join()
      ? jaBodyPhrases
      : (text == jaBodyShortPhrases.join() ? jaBodyShortPhrases : [text]);
  final lines = <String>[];
  var current = '';
  for (final phrase in phrases) {
    final candidate = current + phrase;
    if (current.isNotEmpty && _singleLineWidth(candidate, style) > width) {
      lines.add(current);
      current = phrase;
    } else {
      current = candidate;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  return _BodyFit(lines.join('\n'), lines.length);
}

TextPainter _painter(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
  textScaler: TextScaler.noScaling,
);

double _singleLineWidth(String text, TextStyle style) {
  final painter = _painter(text, style)..layout();
  return painter.width;
}

int _countLines(String text, TextStyle style, double width) {
  final painter = _painter(text, style)..layout(maxWidth: math.max(width, 1));
  return painter.computeLineMetrics().length;
}
