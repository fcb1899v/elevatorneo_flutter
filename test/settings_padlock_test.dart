import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevatorneo/constant.dart';
import 'package:letselevatorneo/settings.dart';

void main() {
  testWidgets('padlockIcon keeps its square box and draws the shape 92.2 px tall at size 100', (tester) async {
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: padlockIcon(100))));
    expect(tester.getSize(find.byType(SizedBox).first), const Size(100, 100));
    final svg = tester.widget<SvgPicture>(find.byKey(const Key('settingsPadlock')));
    expect(svg.height, closeTo(92.2, 0.1));
  });

  testWidgets('padlockStar is bundled, filled lampColor and outlined in black', (tester) async {
    final text = await rootBundle.loadString(padlockStar);
    expect(text, contains('fill="#F7B249"'));
    expect(text, contains('stroke="#000000"'));
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: padlockIcon(100))));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
