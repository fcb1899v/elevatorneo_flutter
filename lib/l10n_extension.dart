// =============================
// L10nContextExt: localization helpers (part of extension.dart)
// =============================
part of 'extension.dart';

extension L10nContextExt on BuildContext {
  // --- Localization & Fonts ---
  // Language detection and font selection based on current locale
  String lang() => Localizations.localeOf(this).languageCode;
  String font() =>
      (lang() == "ja") ? "notoJP":
      (lang() == "zh") ? "notoSC":
      (lang() == "ko") ? "bmDohyeon":
      "roboto";

  // --- Localized Strings ---
  // Comprehensive collection of localized strings for all app features
  // Common app strings
  String thisApp() => AppLocalizations.of(this)!.thisApp;
  String openDoor() => AppLocalizations.of(this)!.openDoor;
  String closeDoor() => AppLocalizations.of(this)!.closeDoor;
  String upFloor() => AppLocalizations.of(this)!.upFloor;
  String downFloor() => AppLocalizations.of(this)!.downFloor;
  String pushNumber() => AppLocalizations.of(this)!.pushNumber;
  String emergency() => AppLocalizations.of(this)!.emergency;
  String return1st() => AppLocalizations.of(this)!.return1st;
  String basement(int counter) => (counter < 0) ? AppLocalizations.of(this)!.basement: "";
  String floor(String number) => AppLocalizations.of(this)!.floor(number);
  String notStop() => AppLocalizations.of(this)!.notStop;
  String eVMile() => AppLocalizations.of(this)!.eVMile;
  String eVMileRanking() => AppLocalizations.of(this)!.eVMileRanking;
  String earnMile(String number) => AppLocalizations.of(this)!.earnMile(number);
  String aboutEVMile() => AppLocalizations.of(this)!.aboutEVMile;
  // Room names
  String rooftop() => AppLocalizations.of(this)!.rooftop;
  String vip() => AppLocalizations.of(this)!.vip;
  String restaurant() => AppLocalizations.of(this)!.restaurant;
  String spa() => AppLocalizations.of(this)!.spa;
  String arcade() => AppLocalizations.of(this)!.arcade;
  String foodCourt() => AppLocalizations.of(this)!.foodCourt;
  String indoorPark() => AppLocalizations.of(this)!.indoorPark;
  String supermarket() => AppLocalizations.of(this)!.supermarket;
  String station() => AppLocalizations.of(this)!.station;
  String parking() => AppLocalizations.of(this)!.parking;
  String apparel() => AppLocalizations.of(this)!.apparel;
  String electronics() => AppLocalizations.of(this)!.electronics;
  String outdoor() => AppLocalizations.of(this)!.outdoor;
  String book() => AppLocalizations.of(this)!.bookstore;
  String candy() => AppLocalizations.of(this)!.candy;
  String toy() => AppLocalizations.of(this)!.toy;
  String luxury() => AppLocalizations.of(this)!.luxury;
  String sports() => AppLocalizations.of(this)!.sports;
  String gym() => AppLocalizations.of(this)!.gym;
  String sweets() => AppLocalizations.of(this)!.sweets;
  String furniture() => AppLocalizations.of(this)!.furniture;
  String cinema() => AppLocalizations.of(this)!.cinema;
  // Room image names
  String nameParking() => AppLocalizations.of(this)!.nameParking;
  String nameStation() => AppLocalizations.of(this)!.nameStation;
  String nameSupermarket() => AppLocalizations.of(this)!.nameSupermarket;
  String nameIndoorPark() => AppLocalizations.of(this)!.nameIndoorPark;
  String nameFoodCourt() => AppLocalizations.of(this)!.nameFoodCourt;
  String nameArcade() => AppLocalizations.of(this)!.nameArcade;
  String nameSpa() => AppLocalizations.of(this)!.nameSpa;
  String nameRestaurant() => AppLocalizations.of(this)!.nameRestaurant;
  String nameVip() => AppLocalizations.of(this)!.nameVip;
  String nameRooftop() => AppLocalizations.of(this)!.nameRooftop;
  String nameApparel() => AppLocalizations.of(this)!.nameApparel;
  String nameElectronics() => AppLocalizations.of(this)!.nameElectronics;
  String nameOutdoor() => AppLocalizations.of(this)!.nameOutdoor;
  String nameBook() => AppLocalizations.of(this)!.nameBookstore;
  String nameCandy() => AppLocalizations.of(this)!.nameCandy;
  String nameToy() => AppLocalizations.of(this)!.nameToy;
  String nameLuxury() => AppLocalizations.of(this)!.nameLuxury;
  String nameSports() => AppLocalizations.of(this)!.nameSports;
  String nameGym() => AppLocalizations.of(this)!.nameGym;
  String nameSweets() => AppLocalizations.of(this)!.nameSweets;
  String nameFurniture() => AppLocalizations.of(this)!.nameFurniture;
  String nameCinema() => AppLocalizations.of(this)!.nameCinema;
  // Sound and audio helpers
  String soundPlace(String room) =>
      (room == imageParking) ? parking():
      (room == imageStation) ? station():
      (room == imageSuper) ? supermarket():
      (room == imagePark) ? indoorPark():
      (room == imageFood) ? foodCourt():
      (room == imageArcade) ? arcade():
      (room == imageSpa) ? spa():
      (room == imageRest) ? restaurant():
      (room == imageVip) ? vip():
      (room == imageTop) ? rooftop():
      (room == imageApparel) ? apparel():
      (room == imageElectro) ? electronics():
      (room == imageOutdoor) ? outdoor():
      (room == imageBook) ? book():
      (room == imageCandy) ? candy():
      (room == imageToy) ? toy():
      (room == imageLuxury) ? luxury():
      (room == imageSports) ? sports():
      (room == imageGym) ? gym():
      (room == imageSweets) ? sweets():
      (room == imageFurnit) ? furniture():
      (room == imageCinema) ? cinema():
      "";
  String soundFloor(int counter) =>
      (counter == max) ? "":
      (lang() == "en") ? floor("${counter.enRankNumber()}${basement(counter)}"):
      (lang() == "es") ? "${counter.esRankNumber()}${basement(counter)}":
      (lang() == "fr") ? "${counter.frRankNumber()}${basement(counter)}":
      floor("${basement(counter)}${counter.abs()}");
  String openingSound(int counter, String room) =>
      "${soundFloor(counter)}${soundPlace(room)}${openDoor()}";
  // Room name lists
  List<String> initialRoomName() => [
    nameParking(), nameStation(), nameSupermarket(), nameArcade(), nameFoodCourt(),
    nameBook(), nameSpa(), nameRestaurant(), nameVip(), nameRooftop(),
  ];
  List<String> addRoomName() => [
    nameApparel(), nameElectronics(), nameIndoorPark(), nameOutdoor(), nameCandy(),
    nameToy(), nameLuxury(), nameSports(), nameGym(), nameSweets(),
    nameFurniture(), nameCinema()
  ];
  List<String> roomNameList() => [...initialRoomName(), ...addRoomName()];
  // Menu and settings
  String settings() => AppLocalizations.of(this)!.settings;
  String glass() => AppLocalizations.of(this)!.glass;
  String back() => AppLocalizations.of(this)!.back;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String stop() => AppLocalizations.of(this)!.stop;
  String bypass() => AppLocalizations.of(this)!.bypass;
  String edit() => AppLocalizations.of(this)!.edit;
  String ranking() => AppLocalizations.of(this)!.ranking;
  String changeNumber() => AppLocalizations.of(this)!.changeNumber;
  String changeBasementNumber() => AppLocalizations.of(this)!.changeBasementNumber;
  String changeNumberTitle(bool isBasement) => isBasement ? changeBasementNumber(): changeNumber();
  String changeImage() => AppLocalizations.of(this)!.changeImage;
  String selectPhoto() => AppLocalizations.of(this)!.selectPhoto;
  String cropPhoto() => AppLocalizations.of(this)!.cropPhoto;
  String terms() => AppLocalizations.of(this)!.terms;
  String letsElevator() => AppLocalizations.of(this)!.aboutLetsElevator;
  String officialPage() =>  AppLocalizations.of(this)!.officialPage;
  String officialShop() => AppLocalizations.of(this)!.officialShop;
  String movingElevator() => AppLocalizations.of(this)!.movingElevator;
  String photoAccessRequired() => AppLocalizations.of(this)!.photoAccessRequired;
  String photoAccessPermission() => AppLocalizations.of(this)!.photoAccessPermission;
  String earnMilesAfterAdTitle(String number) => AppLocalizations.of(this)!.earnMilesAfterAdTitle(number);
  String earnMilesAfterAdDesc(String number) => AppLocalizations.of(this)!.earnMilesAfterAdDesc(number);
  String landingPageLink() => (lang() == "ja") ? landingPageJa: landingPageEn;
  String privacyPolicyLink() => (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn;
  String youtubeLink() => (lang() == "ja") ? youtubeJa: youtubeEn;
  String notConnectedInternet() => AppLocalizations.of(this)!.notConnectedInternet;
  // App Tracking Transparency pre-prompt
  String attTitle() => AppLocalizations.of(this)!.attTitle;
  String attDesc() => AppLocalizations.of(this)!.attDesc;
  // Premium upgrade
  String premiumTitle() => AppLocalizations.of(this)!.premiumTitle;
  String premiumDesc() => AppLocalizations.of(this)!.premiumDesc;
  String premiumBuy(String price) => (price.isEmpty) ?
      AppLocalizations.of(this)!.premiumBuy:
      AppLocalizations.of(this)!.premiumPrice(price);
  String premiumRestore() => AppLocalizations.of(this)!.premiumRestore;
  String premiumThanks() => AppLocalizations.of(this)!.premiumThanks;
  String premiumFailed() => AppLocalizations.of(this)!.premiumFailed;
  String premiumRestoreFailed() => AppLocalizations.of(this)!.premiumRestoreFailed;
  String notSignedInGameCenter() => AppLocalizations.of(this)!.notSignedInGameCenter(
    (Platform.isIOS || Platform.isMacOS) ? "Game Center": "Play Games"
  );
  // Menu links and titles
  List<String> linkLogos() => [
    if (Platform.isAndroid) youtubeLogo,
    landingPageLogo,
    privacyPolicyLogo,
    if (lang() == "ja") shopPageLogo,
  ];
  List<String> linkLinks() => [
    if (Platform.isAndroid) youtubeLink(),
    landingPageLink(),
    privacyPolicyLink(),
    if (lang() == "ja") shopLink,
  ];
  List<String> linkTitles() => [
    if (Platform.isAndroid) "Youtube",
    officialPage(),
    terms(),
    if (lang() == "ja") officialShop(),
  ];
  List<String> menuTitles() => [
    settings(),
    eVMileRanking(),
    earnMile(earnMiles),
  ];

}
