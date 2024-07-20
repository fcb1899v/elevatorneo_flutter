import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admob_rewarded.dart';
import 'common_function.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'admob_banner.dart';
import 'main.dart';

class MyMenuPage extends HookConsumerWidget {
  const MyMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final point = ref.watch(pointProvider);
    final AudioPlayer audioPlayer = AudioPlayer();
    final RewardedAd? ad = rewardedAd();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await audioPlayer.setReleaseMode(ReleaseMode.loop);
        await audioPlayer.setVolume(0.5);
      });
      return null;
    }, []);

    ///Show Rewarded Ad
    showRewardedAd() => ad!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        final prefs = await SharedPreferences.getInstance();
        'Reward earned: ${reward.type}, Amount: ${reward.amount}'.debugPrint();
        "point: $point".debugPrint();
        ref.read(pointProvider.notifier).update((p) => p + reward.amount.toInt());
        final newPoint = ref.read(pointProvider.notifier).state;
        await "pointKey".setSharedPrefInt(prefs, newPoint);
        await gamesSubmitScore(newPoint);
        "point: $point".debugPrint();
        ref.read(isMenuProvider.notifier).update((_) => false);
        Navigator.of(context).pop();
      }
    );

    ///Rewarded Ad Permission
    rewardedAdPermissionAlert() => showDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.earnMilesAfterAdTitle(),
          style: TextStyle(
            color: blackColor,
            fontSize: context.menuAlertTitleFontSize(),
            fontFamily: menuFont,
          ),
        ),
        content: Text(context.earnMilesAfterAdDesc(),
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
    pressedMenuLink(int i) {
      if (i == 0) {
        ref.read(isMenuProvider.notifier).update((state) => false);
        ref.read(isSettingsProvider.notifier).update((state) => true);
      } else if (i == 1) {
        gamesShowLeaderboard();
      } else if (i == 2) {
        "$ad".debugPrint();
        if (ad != null) rewardedAdPermissionAlert();
      }
    }

    ///Menu
    return Scaffold(
      backgroundColor: transpWhiteColor,
      body: SizedBox(
        width: context.width(),
        height: context.height(),
        child: Column(children: [
          const Spacer(flex: 3),
          ///App Logo
          SizedBox(
            width: context.menuTitleWidth(),
            child: Image.asset(appLogo),
          ),
          const Spacer(flex: 2),
          ///Menu Title
          Text(context.menu(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuTitleFontSize(),
              fontWeight: FontWeight.bold,
              fontFamily: menuFont,
            ),
          ),
          const Spacer(flex: 1),
          ///Mode Change
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (i) =>
              i % 2 == 0 ? const Spacer(flex: 1):
              GestureDetector(
                onTap: () async => pressedMenuLink((i - 1) ~/ 2),
                child: menuButton(context, (i - 1) ~/ 2),
              ),
            ),
          ),
          const Spacer(flex: 3),
          ///Menu Links
          BottomNavigationBar(
            items: List<BottomNavigationBarItem>.generate(context.linkLogos().length, (i) =>
              BottomNavigationBarItem(
                icon: Container(
                  margin: EdgeInsets.only(
                    top: context.linksMargin(),
                    bottom: context.linksTitleMargin()
                  ),
                  width: context.linksLogoWidth(),
                  height: context.linksLogoHeight(),
                  child: Image.asset(context.linkLogos()[i]),
                ),
                label: context.linkTitles()[i],
              ),
            ),
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            onTap: (i) => launchUrl(Uri.parse(context.linkLinks()[i])),
            elevation: 0,
            selectedItemColor: lampColor,
            unselectedItemColor: lampColor,
            selectedFontSize: context.linksTitleSize(),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedFontSize: context.linksTitleSize(),
            backgroundColor: blackColor,
          ),
          const AdBannerWidget(),
        ]),
      ),
    );
  }
}