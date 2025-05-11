import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'admob_rewarded.dart';
import 'games_manager.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'admob_banner.dart';
import 'main.dart';
import 'my_app_bar.dart';

class MyMenuPage extends HookConsumerWidget {
  const MyMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final point = ref.watch(pointProvider);
    final isGamesSignedIn = useState(false);
    final RewardedAd? ad = rewardedAd();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!Platform.isAndroid || isTest) {
          isGamesSignedIn.value = await gamesIsSignedIn();
        }
      });
      return null;
    }, []);

    ///Show Rewarded Ad
    showRewardedAd() => ad!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        "showRewardedAd".debugPrint();
        final prefs = await SharedPreferences.getInstance();
        'rewardEarned: ${reward.type}, rewardAmount: ${reward.amount}'.debugPrint();
        final addPoint = (earnMilesInt > reward.amount.toInt()) ? earnMilesInt: reward.amount.toInt();
        ref.read(pointProvider.notifier).update((p) => p + addPoint);
        final newPoint = ref.read(pointProvider.notifier).state;
        await "pointKey".setSharedPrefInt(prefs, newPoint);
        if (!Platform.isAndroid || isTest) await gamesSubmitScore(newPoint);
        if (context.mounted) Navigator.of(context).pop();
      }
    );

    ///Rewarded Ad Permission
    rewardedAdPermissionAlert() => showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.earnMilesAfterAdTitle(earnMiles),
          style: TextStyle(
            color: blackColor,
            fontSize: context.menuAlertTitleFontSize(),
            fontFamily: menuFont,
          ),
        ),
        content: Text(context.earnMilesAfterAdDesc(earnMiles),
          style: TextStyle(
            color: blackColor,
            fontSize: context.menuAlertDescFontSize(),
            fontFamily: menuFont,
          ),
        ),
        actions: [
          TextButton(
            child: Text(context.ok(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.menuAlertSelectFontSize(),
                fontFamily: menuFont,
                fontWeight: FontWeight.bold
              ),
            ),
            onPressed: () => showRewardedAd(),
          ),
          TextButton(
            child: Text(context.cancel(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.menuAlertSelectFontSize(),
                fontFamily: menuFont,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    ///Pressed menu links action
    pressedMenuLink(int i) async {
      if (i == 1) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        "$ad".debugPrint();
        if (ad != null) rewardedAdPermissionAlert();
      } else if (i == 2) {
        await gamesShowLeaderboard();
      } else {
        context.pushSettingsPage();
      }
    }

    ///Menu
    return Scaffold(
      appBar: myAppBar(
        context: context,
        point: point,
        pressedMenu: () => context.pushMyPage(true), ///to MyMenuPage
      ),
      backgroundColor: transpWhiteColor,
      body: Stack(alignment: Alignment.topCenter,
        children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: context.menuMarginTop()),
            /// App Logo
            Text(context.menu(),
              style: TextStyle(
                color: blackColor,
                fontSize: context.menuTitleFontSize(),
                fontFamily: elevatorFont,
              ),
            ),
            /// Menu Rows
            ...List.generate(isGamesSignedIn.value ? 3: 2, (i) =>
              Column(children: [
                GestureDetector(
                  onTap: () async => await pressedMenuLink(i),
                  child: menuButton(context, i),
                ),
              ])
            ),
            SizedBox(height: context.menuMarginBottom())
          ]
        ),
        Column(mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ///Menu Links
            BottomNavigationBar(
              items: List.generate(context.linkLogos().length, (i) =>
                BottomNavigationBarItem(
                  icon: Container(
                    margin: EdgeInsets.symmetric(vertical: context.menuLinksMargin()),
                    width: context.menuLinksLogoSize(),
                    child: Image.asset(context.linkLogos()[i]),
                  ),
                  label: context.linkTitles()[i],
                ),
              ),
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              onTap: (i) =>{
                Vibration.vibrate(duration: vibTime, amplitude: vibAmp),
                launchUrl(Uri.parse(context.linkLinks()[i]))
              },
              elevation: 0,
              selectedItemColor: lampColor,
              unselectedItemColor: lampColor,
              selectedFontSize: context.menuLinksTitleSize(),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedFontSize: context.menuLinksTitleSize(),
              backgroundColor: blackColor,
            ),
            const AdBannerWidget(),
          ]
        )
      ]),
    );
  }
}