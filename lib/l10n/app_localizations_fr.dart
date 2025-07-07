// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR NEO';

  @override
  String get thisApp =>
      'Cette application est un simulateur d\'ascenseur très réaliste.';

  @override
  String get menu => 'Menu';

  @override
  String get settings => 'Paramètres';

  @override
  String get glass => 'Panneau en verre';

  @override
  String get start => 'DÉMARRER';

  @override
  String get back => 'RETOUR';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'ANNULER';

  @override
  String get edit => 'MODIFIER';

  @override
  String get basement => 'Sous-sol';

  @override
  String floor(Object NUMBER) {
    return '$NUMBERᵉ étage, ';
  }

  @override
  String get ground => 'Rez-de-chaussée, ';

  @override
  String get openDoor => 'Ouverture.';

  @override
  String get closeDoor => 'Fermeture.';

  @override
  String get pushNumber => '';

  @override
  String get upFloor => 'Montée.';

  @override
  String get downFloor => 'Descente.';

  @override
  String get notStop => 'Non desservi.';

  @override
  String get emergency => 'Arrêt d\'urgence pour inspection.';

  @override
  String get return1st => 'Vérification terminée. Retour au premier étage.';

  @override
  String get bypass => 'Passer';

  @override
  String get stop => 'Arrêter';

  @override
  String get changeNumber => 'Changer l\'étage';

  @override
  String get changeBasementNumber => 'Changer l\'étage du sous-sol';

  @override
  String get changeImage => 'Changer l\'image de l\'étage';

  @override
  String get selectPhoto => 'Sélectionner une image depuis l\'album';

  @override
  String get cropPhoto => 'Recadrer votre image';

  @override
  String get eVMile => 'Miles EV';

  @override
  String get eVMileRanking => 'Classement\nMiles EV';

  @override
  String earnMile(Object NUMBER) {
    return 'Gagnez\n$NUMBER\nMiles EV !';
  }

  @override
  String get aboutEVMile =>
      '\nPoints accumulés grâce aux trajets fréquents en ascenseur.\nLes Miles EV débloqués permettent d\'activer diverses fonctionnalités, réglables dans les paramètres du menu.';

  @override
  String get rooftop => 'Dernier étage, ';

  @override
  String get vip => 'Étage VIP, ';

  @override
  String get restaurant => 'Étage restaurant, ';

  @override
  String get spa => 'Étage spa, ';

  @override
  String get arcade => 'Étage salle de jeux, ';

  @override
  String get foodCourt => 'Étage aire de restauration, ';

  @override
  String get indoorPark => 'Étage parc intérieur, ';

  @override
  String get supermarket => 'Étage supermarché, ';

  @override
  String get station => 'Étage station de métro, ';

  @override
  String get parking => 'Étage parking, ';

  @override
  String get apparel => 'Étage magasin de vêtements, ';

  @override
  String get electronics => 'Étage magasin d\'électronique, ';

  @override
  String get outdoor => 'Étage magasin d\'équipements extérieurs, ';

  @override
  String get bookstore => 'Étage librairie, ';

  @override
  String get candy => 'Étage confiserie, ';

  @override
  String get toy => 'Étage magasin de jouets, ';

  @override
  String get luxury => 'Étage boutique de luxe, ';

  @override
  String get sports => 'Étage magasin d\'articles de sport, ';

  @override
  String get gym => 'Étage salle de sport, ';

  @override
  String get sweets => 'Étage pâtisserie, ';

  @override
  String get furniture => 'Étage magasin de meubles, ';

  @override
  String get cinema => 'Étage cinéma, ';

  @override
  String get nameRooftop => 'Dernier étage';

  @override
  String get nameVip => 'Salle VIP';

  @override
  String get nameRestaurant => 'Restaurant';

  @override
  String get nameSpa => 'Spa';

  @override
  String get nameArcade => 'Salle de jeux';

  @override
  String get nameFoodCourt => 'Aire de restauration';

  @override
  String get nameIndoorPark => 'Parc intérieur';

  @override
  String get nameSupermarket => 'Supermarché';

  @override
  String get nameStation => 'Station de métro';

  @override
  String get nameParking => 'Parking';

  @override
  String get nameApparel => 'Magasin de vêtements';

  @override
  String get nameElectronics => 'Magasin d\'électronique';

  @override
  String get nameOutdoor => 'Magasin d\'équipements extérieurs';

  @override
  String get nameBookstore => 'Librairie';

  @override
  String get nameCandy => 'Confiserie';

  @override
  String get nameToy => 'Magasin de jouets';

  @override
  String get nameLuxury => 'Boutique de luxe';

  @override
  String get nameSports => 'Magasin d\'articles de sport';

  @override
  String get nameGym => 'Salle de sport';

  @override
  String get nameSweets => 'Pâtisserie';

  @override
  String get nameFurniture => 'Magasin de meubles';

  @override
  String get nameCinema => 'Cinéma';

  @override
  String get movingElevator =>
      'Ascenseur en cours d\'utilisation, veuillez patienter.';

  @override
  String get photoAccessRequired =>
      'Autorisation d\'accès aux photos requise\n';

  @override
  String get photoAccessPermission =>
      'Pour sélectionner votre photo, veuillez autoriser l\'accès complet aux photos depuis les paramètres.';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return 'Gagnez\n$NUMBER Miles EV\nen regardant des publicités\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return 'Pour gagner $NUMBER Miles EV, veuillez regarder les publicités pendant la durée spécifiée.';
  }

  @override
  String get notConnectedInternet => 'Pas de connexion Internet';

  @override
  String notSignedInGameCenter(Object Platform) {
    return 'Connectez-vous à $Platform';
  }

  @override
  String get aboutLetsElevator => 'À propos de LETS ELEVATOR';

  @override
  String get termsAndPrivacyPolicy =>
      'Conditions et politique de confidentialité';

  @override
  String get terms => 'Conditions';

  @override
  String get officialPage => 'Page officielle';

  @override
  String get officialShop => 'Boutique officielle';

  @override
  String get ranking => 'Classement';
}
