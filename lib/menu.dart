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
import 'homepage.dart';
import 'main.dart';
import 'settings.dart';

class MenuPage extends HookConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final isConnectedInternet = ref.watch(internetProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final RewardedAd? ad = rewardedAd();
    final isLoadingData = useState(false);

    //Class
    final common = CommonWidget(context);
    final menu = MenuWidget(context,
      isConnectedInternet: isConnectedInternet,
      isGamesSignIn: isGamesSignIn,
    );
    final gamesManager = useMemoized(() => GamesManager(
      isGamesSignIn: isGamesSignIn,
      isConnectedInternet: isConnectedInternet,
    ));

    //Initialize
    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(internetProvider.notifier).state = await gamesManager.checkInternetConnection();
        ref.read(gamesSignInProvider.notifier).state = await gamesManager.gamesSignIn();
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
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
        "pointKey".setSharedPrefInt(prefs, newPoint);
        await gamesManager.gamesSubmitScore(newPoint);
        ref.read(isMenuProvider.notifier).update((f) => !f);
        if (context.mounted) context.pushFadeReplacement(HomePage());
      }
    );

    ///Pressed menu links action
    pressedMenuLink(int i) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (i == 0) {
        if (context.mounted) context.pushFadeReplacement(SettingsPage());
      } else if (!isConnectedInternet) {
        menu.showSnackBar(context.notConnectedInternet());
      } else if (i == 1) {
        "$ad".debugPrint();
        if (ad != null) menu.rewardedAdPermissionAlert(onTap: () => showRewardedAd());
      } else if (!isGamesSignIn) {
        menu.showSnackBar(context.notSignedInGameCenter());
      } else {
        await gamesManager.gamesShowLeaderboard();
      }
    }

    ///Menu
    return Scaffold(
      body: Stack(alignment: Alignment.topCenter,
        children: [
          common.commonBackground(menuBackGroundImage),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 1),
              /// Menu Rows
              ...List.generate(3, (i) =>
                GestureDetector(
                  onTap: () async => await pressedMenuLink(i),
                  child: menu.menuButton(i),
                ),
              ),
              Spacer(flex: 1),
              ///Bottom menu links
              menu.bottomMenuLink(),
              ///Admob banner space
              Container(
                height: context.admobHeight(),
                color: blackColor,
              )
            ]
          ),
          ///Progress Indicator
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]
      ),
    );
  }
}

class MenuWidget {

  final BuildContext context;
  final bool isConnectedInternet;
  final bool isGamesSignIn;

  MenuWidget(this.context, {
    required this.isConnectedInternet,
    required this.isGamesSignIn,
  });

  ///Menu Button
  Widget menuButton(int i) => Container(
    width: context.menuButtonSize(),
    height: context.menuButtonSize(),
    margin: EdgeInsets.symmetric(vertical: context.menuButtonMargin()),
    child: Image.asset(
      (i == 0) ? settingsButton:
      (i == 1) ? adRewardButton:
      (i == 2) ? rankingButton:
      squareButton
    ),
  );

  ///Bottom navi
  Widget bottomMenuLink() => Container(
    color: blackColor,
    padding: EdgeInsets.symmetric(vertical: context.menuLinksMargin()),
    child: BottomNavigationBar(
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
        (isConnectedInternet) ? launchUrl(Uri.parse(context.linkLinks()[i])):
          showSnackBar(context.notConnectedInternet()),
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
  );

  ///AlertDialog for rewarded ad permission
  void rewardedAdPermissionAlert({
    required void Function() onTap
  }) => showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(context.earnMilesAfterAdTitle(earnMiles),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertTitleFontSize(),
          fontFamily: context.normalFont(),
        ),
      ),
      content: Text(context.earnMilesAfterAdDesc(earnMiles),
        style: TextStyle(
          color: blackColor,
          fontSize: context.menuAlertDescFontSize(),
          fontFamily: context.normalFont(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.popPage(),
          child: Text(context.cancel(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.normalFont(),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(context.ok(),
            style: TextStyle(
              color: blackColor,
              fontSize: context.menuAlertSelectFontSize(),
              fontFamily: context.normalFont(),
            ),
          ),
        ),
      ],
    ),
  );

  void showSnackBar(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: blackColor,
          fontSize: context.snackBarFontSize(),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final snackBar = SnackBar(
      content: Text(text,
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.snackBarFontSize(),
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: lampColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.snackBarBorderRadius()),
      ),
      padding: EdgeInsets.all(context.snackBarPadding()),
      margin: EdgeInsets.symmetric(
        horizontal: context.snackBarSideMargin(textPainter),
        vertical: context.snackBarBottomMargin(),
      ),
    );
    "showSnackBar: $text".debugPrint();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}