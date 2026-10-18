// PremiumPage: the full-screen purchase page, not a short alert, for people asking "what is this?".
// It names no feature: one icon per premiumTabList entry, so a new feature needs no edit here.

import 'package:flutter/material.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'extension.dart';
import 'settings.dart' show padlockIcon;

// One plain platform font throughout, since context.font() gives Korean a display face.
// The PREMIUM board keeps letsgo, its own alphabet.
/// It stays open until the user is premium, so a cancelled or failed purchase can be retried at once.
class PremiumPage extends StatefulWidget {
  const PremiumPage({
    super.key,
    required this.price,
    required this.onBuy,
    required this.onRestore,
    required this.isPremium,
  });

  final String price;
  final Future<void> Function() onBuy;
  final Future<void> Function() onRestore;

  /// Read once a purchase or restore ends: the page closes only when this is true
  final bool Function() isPremium;

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  bool _isBusy = false;

  String get price => widget.price;

  /// Runs a purchase or restore with the page locked, then closes the page only if the user ended up premium.
  /// A second tap while one runs does nothing
  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
        if (widget.isPremium()) Navigator.of(context).pop();
      }
    }
  }

  // The back gesture and the close button are dead while a purchase runs, so the result lands on this page
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_isBusy, child: _scaffold(context));

  Widget _scaffold(BuildContext context) {
    final common = CommonWidget(context);
    return Scaffold(
      // Transparent, so the banner HomePage paints below this route shows through
      backgroundColor: transpColor,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // The menu's metal, darkened: its centre highlight matches the white text.
                // Undarkened, it swallows the text.
                common.commonBackground(menuBackGroundImage),
                Container(color: transpBlackColor),
                SafeArea(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: _isBusy ? null : () => context.popPage(),
                          icon: Icon(
                            Icons.close,
                            color: whiteColor,
                            size: context.premiumCloseSize(),
                          ),
                        ),
                      ),
                      // Centred in what the close button leaves.
                      // Scrolls only on a short screen, which then shows the page, not a stripe.
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Identity
                                _sign(context),
                                SizedBox(height: context.premiumGapInner()),
                                Text(
                                  context.premiumTitle(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: whiteColor,
                                    fontSize: context.premiumNameFontSize(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: context.premiumGapBlock()),
                                // What you get
                                _plate(context),
                                SizedBox(height: context.premiumGapInner()),
                                Text(
                                  context.premiumUnlockAll(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: whiteColor,
                                    fontSize: context.premiumBodyFontSize(),
                                  ),
                                ),
                                SizedBox(height: context.premiumGapInner()),
                                _tabIcons(context),
                                SizedBox(height: context.premiumGapBlock()),
                                // Action
                                Text(
                                  context.premiumOneTime(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: whiteColor,
                                    fontSize: context.premiumNoteFontSize(),
                                  ),
                                ),
                                SizedBox(height: context.premiumGapInner()),
                                price.isEmpty ? _unavailableNote(context): _buyButton(context),
                                SizedBox(height: context.premiumGapInner()),
                                TextButton(
                                  onPressed: _isBusy ? null : () => _run(widget.onRestore),
                                  child: Text(
                                    context.premiumRestore(),
                                    style: TextStyle(
                                      color: whiteColor,
                                      fontSize: context
                                          .premiumRestoreFontSize(),
                                      decoration: TextDecoration.underline,
                                      decorationColor: whiteColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Covers the page and takes every tap while the store answers
                if (_isBusy) common.commonCircularProgressIndicator(),
              ],
            ),
          ),
          // The ad keeps showing while the page is open: it is what the purchase removes.
          // It keeps earning until then.
          SizedBox(height: context.admobHeight()),
        ],
      ),
    );
  }

  /// The indicator board, squared off and unframed like the floor display in the app bar.
  /// The font letsgodigital is that display's own alphabet.
  Widget _sign(BuildContext context) => Container(
    width: context.premiumContentWidth(),
    height: context.premiumSignHeight(),
    alignment: Alignment.center,
    color: darkBlackColor,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        "PREMIUM",
        style: TextStyle(
          color: lampColor,
          fontSize: context.premiumSignFontSize(),
          fontFamily: "letsgo",
        ),
      ),
    ),
  );

  /// The headline benefit, in a framed plate.
  /// No icon: the words carry it
  Widget _plate(BuildContext context) => Container(
    width: context.premiumContentWidth(),
    padding: EdgeInsets.symmetric(vertical: context.premiumPlatePadding()),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: darkBlackColor,
      borderRadius: BorderRadius.circular(context.premiumPlateRadius()),
      border: Border.all(color: grayColor, width: context.premiumBorderWidth()),
    ),
    child: Text(
      context.premiumNoAds(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: whiteColor,
        fontSize: context.premiumPlateFontSize(),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  /// One icon per settings tab the unlock opens.
  /// Reading premiumTabList rather than a hand-written list is what keeps this page correct over time
  Widget _tabIcons(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: premiumTabList
        .map(
          (tab) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.premiumIconMargin(),
            ),
            child: Image.asset(
              "$assetsSettings${tab}SettingsPressed.png",
              width: context.premiumIconSize(),
              height: context.premiumIconSize(),
            ),
          ),
        )
        .toList(),
  );

  // No price means the store has nothing to sell (offline, unsold here, in review).
  // The reason replaces the Buy button, and Restore stays.
  Widget _unavailableNote(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.premiumIconMargin()),
    child: Text(context.premiumUnavailable(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: whiteColor,
        fontSize: context.premiumNoteFontSize(),
      ),
    ),
  );

  /// The only amber frame on the page, so the eye lands on it last and stays
  Widget _buyButton(BuildContext context) => GestureDetector(
    onTap: _isBusy ? null : () => _run(widget.onBuy),
    child: Container(
      width: context.premiumContentWidth(),
      height: context.premiumBuyHeight(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: darkBlackColor,
        borderRadius: BorderRadius.circular(context.premiumBuyRadius()),
        border: Border.all(
          color: lampColor,
          width: context.premiumBuyBorderWidth(),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          padlockIcon(context.premiumBuyFontSize()),
          SizedBox(width: context.premiumIconMargin()),
          Text(
            context.premiumBuy(price),
            style: TextStyle(
              color: lampColor,
              fontSize: context.premiumBuyFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
