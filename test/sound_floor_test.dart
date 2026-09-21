// What the arrival announcement actually says, per language. es and fr must not skip
// floor(): without it they speak a bare ordinal, which nothing on screen would show.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';

/// The announcement for [floor] as the app would speak it in [lang]
Future<String> _spoken(WidgetTester tester, String lang, int floor) async {
  late String said;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(lang),
    home: Builder(builder: (context) {
      said = context.soundFloor(floor);
      return const SizedBox.shrink();
    }),
  ));
  return said;
}

void main() {
  testWidgets("the arrival names the floor in every language", (tester) async {
    // Above ground: the noun has to be there, or the ordinal dangles
    const nouns = {
      "ja": "階", "en": "floor", "ko": "층", "zh": "层",
      "es": "piso", "fr": "étage",
    };
    for (final entry in nouns.entries) {
      final said = await _spoken(tester, entry.key, 3);
      expect(said, contains(entry.value),
        reason: "${entry.key} arrival says \"$said\", with no \"${entry.value}\"");
    }
  });

  testWidgets("the basement keeps its own noun, not the floor noun", (tester) async {
    // Sótano / Sous-sol already mean "basement floor"; adding piso / étage
    // after them would be wrong, so the floor noun must not reach the basement branch
    expect(await _spoken(tester, "es", -2), contains("ótano"));
    expect(await _spoken(tester, "es", -2), isNot(contains("piso")));
    expect(await _spoken(tester, "fr", -2), contains("ous-sol"));
    expect(await _spoken(tester, "fr", -2), isNot(contains("étage")));
  });

  // Whole strings, not fragments: the earlier "contains" pair passed while
  // es spoke B2 as the 28th, because the ordinal was built from the signed
  // floor and no branch matched it
  testWidgets("es and fr count the basement from one", (tester) async {
    const said = {
      -1: ["primer Sótano, ", "premier Sous-sol, "],
      -2: ["segundo Sótano, ", "deuxième Sous-sol, "],
      -12: ["duodécimo Sótano, ", "douzième Sous-sol, "],
    };
    for (final e in said.entries) {
      expect(await _spoken(tester, "es", e.key), e.value[0]);
      expect(await _spoken(tester, "fr", e.key), e.value[1]);
    }
  });

  // The remainder above a hundred is 1..99 and needs the whole ordinal, not the
  // tens-only helper: 100 spoke as the 120th, and 101 as the 121st
  testWidgets("the hundreds carry their remainder", (tester) async {
    const es = {100: "centésimo ", 101: "centésimo primer ",
                110: "centésimo décimo ", 119: "centésimo decimonoveno "};
    for (final e in es.entries) {
      expect(await _spoken(tester, "es", e.key), startsWith(e.value));
      expect(await _spoken(tester, "es", e.key), isNot(contains("vigésimo")));
    }
    const fr = {100: "centième ", 101: "centième premier ",
                110: "centième dixième ", 119: "centième dix-neuvième "};
    for (final e in fr.entries) {
      expect(await _spoken(tester, "fr", e.key), startsWith(e.value));
      expect(await _spoken(tester, "fr", e.key), isNot(contains("vingtième")));
    }
  });

  // NEO has no floor 0 (initialFloorNumbers: min, -1, 1, 2, 4, 6, 14, 100, 154, max),
  // so there is no ground-floor branch to test here. LETS covers that case.
}
