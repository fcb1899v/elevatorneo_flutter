// What the arrival announcement actually says, per language.
// es and fr must not skip floor(), or they speak a bare ordinal the screen never shows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/extension.dart';
import 'package:letselevatorneo/l10n/app_localizations.dart';

/// The announcement for [floor] as the app would speak it in [lang]
Future<String> _spoken(WidgetTester tester, String lang, int floor, {bool isTop = false}) async {
  late String said;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(lang),
    home: Builder(builder: (context) {
      said = context.soundFloor(floor, isTop);
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
    // Sótano / Sous-sol already mean "basement floor", so piso / étage after them would be wrong.
    // The floor noun must not reach the basement branch.
    expect(await _spoken(tester, "es", -2), contains("ótano"));
    expect(await _spoken(tester, "es", -2), isNot(contains("piso")));
    expect(await _spoken(tester, "fr", -2), contains("ous-sol"));
    expect(await _spoken(tester, "fr", -2), isNot(contains("étage")));
  });

  // Whole strings, not fragments: a "contains" pair passed while es spoke B2 as the 28th.
  // The ordinal was built from the signed floor, and no branch matched it.
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

  // The remainder above 100 is 1..99 and needs the whole ordinal, not the tens-only helper.
  // Otherwise 100 spoke as the 120th and 101 as the 121st.
  testWidgets("the hundreds carry their remainder", (tester) async {
    const es = {100: "centésimo ", 101: "centésimo primer ",
                110: "centésimo décimo ", 119: "centésimo decimonoveno "};
    for (final e in es.entries) {
      expect(await _spoken(tester, "es", e.key), startsWith(e.value));
      expect(await _spoken(tester, "es", e.key), isNot(contains("vigésimo")));
    }
    const fr = {100: "centième ", 101: "cent unième ",
                110: "cent dixième ", 119: "cent dix-neuvième "};
    for (final e in fr.entries) {
      expect(await _spoken(tester, "fr", e.key), startsWith(e.value));
    }
    // 101 to 119 must not fall back to the hundreds-only "centième" or the tens word
    for (var floor = 101; floor <= 119; floor++) {
      expect(await _spoken(tester, "fr", floor), isNot(contains("centième")));
      expect(await _spoken(tester, "fr", floor), isNot(contains("vingtième")));
    }
  });

  // Whole French strings, so a wrong word cannot pass as a fragment match.
  testWidgets("fr ordinals match the table exactly", (tester) async {
    const table = {
      1: "premier", 2: "deuxième", 9: "neuvième", 10: "dixième", 16: "seizième",
      17: "dix-septième", 20: "vingtième", 21: "vingt et unième", 22: "vingt-deuxième",
      30: "trentième", 35: "trente-cinquième", 41: "quarante et unième",
      59: "cinquante-neuvième", 60: "soixantième", 61: "soixante et unième",
      70: "soixante-dixième", 71: "soixante et onzième", 72: "soixante-douzième",
      77: "soixante-dix-septième", 80: "quatre-vingtième", 81: "quatre-vingt-unième",
      90: "quatre-vingt-dixième", 91: "quatre-vingt-onzième",
      99: "quatre-vingt-dix-neuvième", 100: "centième", 101: "cent unième",
      110: "cent dixième", 119: "cent dix-neuvième", 121: "cent vingt et unième",
      154: "cent cinquante-quatrième", 163: "cent soixante-troisième",
    };
    for (final e in table.entries) {
      expect(await _spoken(tester, "fr", e.key), "${e.value} étage, ",
        reason: "fr floor ${e.key}");
    }
  });

  // A French ordinal must be built once; "ième" appearing twice means two ordinals were stacked.
  testWidgets("fr floors 2 to 163 carry exactly one ième", (tester) async {
    for (var floor = 2; floor <= 163; floor++) {
      final said = await _spoken(tester, "fr", floor);
      expect("ième".allMatches(said).length, 1, reason: "fr floor $floor says \"$said\"");
    }
    expect(await _spoken(tester, "fr", 1), "premier étage, ");
  });

  // Spanish "piso" is masculine, so the not-stop line must read "este piso".
  testWidgets("es notStop uses the masculine este piso", (tester) async {
    late String said;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale("es"),
      home: Builder(builder: (context) {
        said = context.notStop();
        return const SizedBox.shrink();
      }),
    ));
    expect(said, "No se detiene en este piso.");
  });

  // This app has no floor 0, so there is no ground-floor branch to test here.

  testWidgets("a top floor below 163 speaks no floor number", (tester) async {
    // The top button can be renumbered below the structural 163F, so the roof announcement must key off isTop, not the floor number itself.
    expect(await _spoken(tester, "en", 120, isTop: true), "");
    expect(await _spoken(tester, "en", 120, isTop: false), isNot(""));
  });
}
