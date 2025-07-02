import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @letsElevator.
  ///
  /// In en, this message translates to:
  /// **'LETS ELEVATOR NEO'**
  String get letsElevator;

  /// No description provided for @thisApp.
  ///
  /// In en, this message translates to:
  /// **'This app is one of the most realistic elevator simulator.'**
  String get thisApp;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Vision Panel'**
  String get glass;

  /// No description provided for @aboutLetsElevator.
  ///
  /// In en, this message translates to:
  /// **'About LETS ELEVATOR'**
  String get aboutLetsElevator;

  /// No description provided for @termsAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy'**
  String get termsAndPrivacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @officialPage.
  ///
  /// In en, this message translates to:
  /// **'Official Page'**
  String get officialPage;

  /// No description provided for @officialShop.
  ///
  /// In en, this message translates to:
  /// **'Official Shop'**
  String get officialShop;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @bypass.
  ///
  /// In en, this message translates to:
  /// **'Bypass'**
  String get bypass;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @basement.
  ///
  /// In en, this message translates to:
  /// **'basement '**
  String get basement;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'{NUMBER} floor, '**
  String floor(Object NUMBER);

  /// No description provided for @ground.
  ///
  /// In en, this message translates to:
  /// **'Ground floor, '**
  String get ground;

  /// No description provided for @openDoor.
  ///
  /// In en, this message translates to:
  /// **'Doors opening. '**
  String get openDoor;

  /// No description provided for @closeDoor.
  ///
  /// In en, this message translates to:
  /// **'Doors closing. '**
  String get closeDoor;

  /// No description provided for @pushNumber.
  ///
  /// In en, this message translates to:
  /// **'Please press destination floor'**
  String get pushNumber;

  /// No description provided for @upFloor.
  ///
  /// In en, this message translates to:
  /// **'Going up. '**
  String get upFloor;

  /// No description provided for @downFloor.
  ///
  /// In en, this message translates to:
  /// **'Going down. '**
  String get downFloor;

  /// No description provided for @notStop.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this floor is restricted. '**
  String get notStop;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop for check. '**
  String get emergency;

  /// No description provided for @return1st.
  ///
  /// In en, this message translates to:
  /// **'Check complete. Returning to first floor.'**
  String get return1st;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change floor number'**
  String get changeNumber;

  /// No description provided for @changeBasementNumber.
  ///
  /// In en, this message translates to:
  /// **'Change basement floor number'**
  String get changeBasementNumber;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change floor image'**
  String get changeImage;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select image from album'**
  String get selectPhoto;

  /// No description provided for @cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop your image'**
  String get cropPhoto;

  /// No description provided for @eVMile.
  ///
  /// In en, this message translates to:
  /// **'EV miles'**
  String get eVMile;

  /// No description provided for @eVMileRanking.
  ///
  /// In en, this message translates to:
  /// **'EV miles\nRanking'**
  String get eVMileRanking;

  /// No description provided for @earnMile.
  ///
  /// In en, this message translates to:
  /// **'Earn\n{NUMBER}\nEV miles!'**
  String earnMile(Object NUMBER);

  /// No description provided for @aboutEVMile.
  ///
  /// In en, this message translates to:
  /// **'\nPoints accumulated through frequent elevator rides.\nAccumulated EV miles unlock various features, which can be adjusted in the menu settings.'**
  String get aboutEVMile;

  /// No description provided for @rooftop.
  ///
  /// In en, this message translates to:
  /// **'The top floor, '**
  String get rooftop;

  /// No description provided for @vip.
  ///
  /// In en, this message translates to:
  /// **'VIP room floor, '**
  String get vip;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant floor, '**
  String get restaurant;

  /// No description provided for @spa.
  ///
  /// In en, this message translates to:
  /// **'Spa floor, '**
  String get spa;

  /// No description provided for @arcade.
  ///
  /// In en, this message translates to:
  /// **'Game center floor, '**
  String get arcade;

  /// No description provided for @foodCourt.
  ///
  /// In en, this message translates to:
  /// **'Food court floor, '**
  String get foodCourt;

  /// No description provided for @indoorPark.
  ///
  /// In en, this message translates to:
  /// **'Indoor park floor, '**
  String get indoorPark;

  /// No description provided for @supermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket floor, '**
  String get supermarket;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Subway station floor, '**
  String get station;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking floor, '**
  String get parking;

  /// No description provided for @apparel.
  ///
  /// In en, this message translates to:
  /// **'Apparel store floor, '**
  String get apparel;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics store floor, '**
  String get electronics;

  /// No description provided for @outdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor gear store floor, '**
  String get outdoor;

  /// No description provided for @bookstore.
  ///
  /// In en, this message translates to:
  /// **'Bookstore floor, '**
  String get bookstore;

  /// No description provided for @candy.
  ///
  /// In en, this message translates to:
  /// **'Candy store floor, '**
  String get candy;

  /// No description provided for @toy.
  ///
  /// In en, this message translates to:
  /// **'Toy store floor, '**
  String get toy;

  /// No description provided for @luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury boutique floor, '**
  String get luxury;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sporting goods store floor, '**
  String get sports;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Fitness gym floor, '**
  String get gym;

  /// No description provided for @sweets.
  ///
  /// In en, this message translates to:
  /// **'Dessert shop floor, '**
  String get sweets;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture store floor, '**
  String get furniture;

  /// No description provided for @cinema.
  ///
  /// In en, this message translates to:
  /// **'Multiplex floor, '**
  String get cinema;

  /// No description provided for @nameRooftop.
  ///
  /// In en, this message translates to:
  /// **'The Top Floor'**
  String get nameRooftop;

  /// No description provided for @nameVip.
  ///
  /// In en, this message translates to:
  /// **'VIP room'**
  String get nameVip;

  /// No description provided for @nameRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get nameRestaurant;

  /// No description provided for @nameSpa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get nameSpa;

  /// No description provided for @nameArcade.
  ///
  /// In en, this message translates to:
  /// **'Arcade'**
  String get nameArcade;

  /// No description provided for @nameFoodCourt.
  ///
  /// In en, this message translates to:
  /// **'Food court'**
  String get nameFoodCourt;

  /// No description provided for @nameIndoorPark.
  ///
  /// In en, this message translates to:
  /// **'Indoor park'**
  String get nameIndoorPark;

  /// No description provided for @nameSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get nameSupermarket;

  /// No description provided for @nameStation.
  ///
  /// In en, this message translates to:
  /// **'Subway station'**
  String get nameStation;

  /// No description provided for @nameParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get nameParking;

  /// No description provided for @nameApparel.
  ///
  /// In en, this message translates to:
  /// **'Apparel store'**
  String get nameApparel;

  /// No description provided for @nameElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics store'**
  String get nameElectronics;

  /// No description provided for @nameOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor gear store'**
  String get nameOutdoor;

  /// No description provided for @nameBookstore.
  ///
  /// In en, this message translates to:
  /// **'Bookstore'**
  String get nameBookstore;

  /// No description provided for @nameCandy.
  ///
  /// In en, this message translates to:
  /// **'Candy store'**
  String get nameCandy;

  /// No description provided for @nameToy.
  ///
  /// In en, this message translates to:
  /// **'Toy store'**
  String get nameToy;

  /// No description provided for @nameLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury boutique'**
  String get nameLuxury;

  /// No description provided for @nameSports.
  ///
  /// In en, this message translates to:
  /// **'Sporting goods store'**
  String get nameSports;

  /// No description provided for @nameGym.
  ///
  /// In en, this message translates to:
  /// **'Fitness gym'**
  String get nameGym;

  /// No description provided for @nameSweets.
  ///
  /// In en, this message translates to:
  /// **'Dessert shop'**
  String get nameSweets;

  /// No description provided for @nameFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture store'**
  String get nameFurniture;

  /// No description provided for @nameCinema.
  ///
  /// In en, this message translates to:
  /// **'Multiplex'**
  String get nameCinema;

  /// No description provided for @movingElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator in use, please wait a moment.'**
  String get movingElevator;

  /// No description provided for @photoAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo access is required\n'**
  String get photoAccessRequired;

  /// No description provided for @photoAccessPermission.
  ///
  /// In en, this message translates to:
  /// **'To select a photo, please allow full photo access in settings.'**
  String get photoAccessPermission;

  /// No description provided for @earnMilesAfterAdTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn {NUMBER} EV miles\nby watching ads\n'**
  String earnMilesAfterAdTitle(Object NUMBER);

  /// No description provided for @earnMilesAfterAdDesc.
  ///
  /// In en, this message translates to:
  /// **'To earn {NUMBER} EV miles, please watch the ad for the required time.'**
  String earnMilesAfterAdDesc(Object NUMBER);

  /// No description provided for @notConnectedInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get notConnectedInternet;

  /// No description provided for @notSignedInGameCenter.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {Platform}'**
  String notSignedInGameCenter(Object Platform);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
