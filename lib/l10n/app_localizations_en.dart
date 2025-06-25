// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR NEO';

  @override
  String get thisApp =>
      'This app is one of the most realistic elevator simulator.';

  @override
  String get menu => 'Menu';

  @override
  String get settings => 'Settings';

  @override
  String get glass => 'Vision Panel';

  @override
  String get aboutLetsElevator => 'About LETS ELEVATOR';

  @override
  String get termsAndPrivacyPolicy => 'Terms and privacy policy';

  @override
  String get terms => 'Terms';

  @override
  String get officialPage => 'Official Page';

  @override
  String get officialShop => 'Official Shop';

  @override
  String get ranking => 'Ranking';

  @override
  String get start => 'START';

  @override
  String get back => 'BACK';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'CANCEL';

  @override
  String get edit => 'EDIT';

  @override
  String get bypass => 'Bypass';

  @override
  String get stop => 'Stop';

  @override
  String get basement => 'basement ';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER floor, ';
  }

  @override
  String get ground => 'Ground floor, ';

  @override
  String get openDoor => 'Doors opening. ';

  @override
  String get closeDoor => 'Doors closing. ';

  @override
  String get pushNumber => 'Please press destination floor';

  @override
  String get upFloor => 'Going up. ';

  @override
  String get downFloor => 'Going down. ';

  @override
  String get notStop => 'Sorry, this floor is restricted. ';

  @override
  String get emergency => 'Emergency stop for check. ';

  @override
  String get return1st => 'Check complete. Returning to first floor.';

  @override
  String get changeNumber => 'Change floor number';

  @override
  String get changeBasementNumber => 'Change basement floor number';

  @override
  String get changeImage => 'Change floor image';

  @override
  String get selectPhoto => 'Select image from album';

  @override
  String get cropPhoto => 'Crop your image';

  @override
  String get eVMile => 'EV Miles';

  @override
  String get eVMileRanking => 'EV Miles\nRanking';

  @override
  String earnMile(Object NUMBER) {
    return 'Earn\n$NUMBER\nEV Miles!';
  }

  @override
  String get aboutEVMile =>
      '\nPoints accumulated through frequent elevator rides.\nAccumulated EV miles unlock various features, which can be adjusted in the menu settings.';

  @override
  String get rooftop => 'The top floor, ';

  @override
  String get vip => 'VIP room floor, ';

  @override
  String get restaurant => 'Restaurant floor, ';

  @override
  String get spa => 'Spa floor, ';

  @override
  String get arcade => 'Game center floor, ';

  @override
  String get foodCourt => 'Food court floor, ';

  @override
  String get indoorPark => 'Indoor park floor, ';

  @override
  String get supermarket => 'Supermarket floor, ';

  @override
  String get station => 'Subway station floor, ';

  @override
  String get parking => 'Parking floor, ';

  @override
  String get apparel => 'Apparel store floor, ';

  @override
  String get electronics => 'Electronics store floor, ';

  @override
  String get outdoor => 'Outdoor gear store floor, ';

  @override
  String get bookstore => 'Bookstore floor, ';

  @override
  String get candy => 'Candy store floor, ';

  @override
  String get toy => 'Toy store floor, ';

  @override
  String get luxury => 'Luxury boutique floor, ';

  @override
  String get sports => 'Sporting goods store floor, ';

  @override
  String get gym => 'Fitness gym floor, ';

  @override
  String get sweets => 'Dessert shop floor, ';

  @override
  String get furniture => 'Furniture store floor, ';

  @override
  String get cinema => 'Multiplex floor, ';

  @override
  String get nameRooftop => 'The Top Floor';

  @override
  String get nameVip => 'VIP room';

  @override
  String get nameRestaurant => 'Restaurant';

  @override
  String get nameSpa => 'Spa';

  @override
  String get nameArcade => 'Arcade';

  @override
  String get nameFoodCourt => 'Food court';

  @override
  String get nameIndoorPark => 'Indoor park';

  @override
  String get nameSupermarket => 'Supermarket';

  @override
  String get nameStation => 'Subway station';

  @override
  String get nameParking => 'Parking';

  @override
  String get nameApparel => 'Apparel store';

  @override
  String get nameElectronics => 'Electronics store';

  @override
  String get nameOutdoor => 'Outdoor gear store';

  @override
  String get nameBookstore => 'Bookstore';

  @override
  String get nameCandy => 'Candy store';

  @override
  String get nameToy => 'Toy store';

  @override
  String get nameLuxury => 'Luxury boutique';

  @override
  String get nameSports => 'Sporting goods store';

  @override
  String get nameGym => 'Fitness gym';

  @override
  String get nameSweets => 'Dessert shop';

  @override
  String get nameFurniture => 'Furniture store';

  @override
  String get nameCinema => 'Multiplex';

  @override
  String get movingElevator => 'Elevator in use, please wait a moment.';

  @override
  String get photoAccessRequired => 'Photo access permission is required\n';

  @override
  String get photoAccessPermission =>
      'To select your photo, please allow photo full access from settings.';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return 'Earn\n$NUMBER EV miles\nby watching ads\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return 'To earn $NUMBER EV miles, please watch ads for the specified duration.';
  }
}
