// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR NEO';

  @override
  String get thisApp =>
      'Esta aplicación es un simulador de ascensores muy realista.';

  @override
  String get menu => 'Menú';

  @override
  String get settings => 'Configuración';

  @override
  String get glass => 'Panel de vidrio';

  @override
  String get aboutLetsElevator => 'Acerca de LETS ELEVATOR';

  @override
  String get termsAndPrivacyPolicy => 'Términos y política de privacidad';

  @override
  String get terms => 'Términos';

  @override
  String get officialPage => 'Página Oficial';

  @override
  String get officialShop => 'Tienda Oficial';

  @override
  String get ranking => 'Clasificación';

  @override
  String get start => 'INICIAR';

  @override
  String get back => 'ATRÁS';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get edit => 'EDITAR';

  @override
  String get bypass => 'Omitir';

  @override
  String get stop => 'Detener';

  @override
  String get basement => 'Sótano';

  @override
  String floor(Object NUMBER) {
    return 'Piso $NUMBER, ';
  }

  @override
  String get ground => 'Planta baja, ';

  @override
  String get openDoor => 'Abriendo puertas.';

  @override
  String get closeDoor => 'Cerrando puertas.';

  @override
  String get pushNumber => 'Seleccione planta.';

  @override
  String get upFloor => 'Subiendo.';

  @override
  String get downFloor => 'Bajando.';

  @override
  String get notStop => 'No se detiene en esta planta.';

  @override
  String get emergency => 'Parada de emergencia para verificación. ';

  @override
  String get return1st => 'Verificación completa. Regresando al primer piso.';

  @override
  String get changeNumber => 'Cambiar número de piso';

  @override
  String get changeBasementNumber => 'Cambiar número de piso del sótano';

  @override
  String get changeImage => 'Cambiar imagen del piso';

  @override
  String get selectPhoto => 'Seleccionar imagen del álbum';

  @override
  String get cropPhoto => 'Recortar tu imagen';

  @override
  String get eVMile => 'Millas EV';

  @override
  String get eVMileRanking => 'Millas EV\nClasificación';

  @override
  String earnMile(Object NUMBER) {
    return '¡Gana\n$NUMBER\nMillas EV!';
  }

  @override
  String get aboutEVMile =>
      '\nPuntos acumulados a través de frecuentes viajes en ascensor.\nLas millas EV acumuladas desbloquean varias funciones, que se pueden ajustar en la configuración del menú.';

  @override
  String get rooftop => 'El piso superior, ';

  @override
  String get vip => 'Piso de sala VIP, ';

  @override
  String get restaurant => 'Piso de restaurante, ';

  @override
  String get spa => 'Piso de spa, ';

  @override
  String get arcade => 'Piso de centro de juegos, ';

  @override
  String get foodCourt => 'Piso de patio de comidas, ';

  @override
  String get indoorPark => 'Piso de parque interior, ';

  @override
  String get supermarket => 'Piso de supermercado, ';

  @override
  String get station => 'Piso de estación de metro, ';

  @override
  String get parking => 'Piso de estacionamiento, ';

  @override
  String get apparel => 'Piso de tienda de ropa, ';

  @override
  String get electronics => 'Piso de tienda de electrónicos, ';

  @override
  String get outdoor => 'Piso de tienda de equipos al aire libre, ';

  @override
  String get bookstore => 'Piso de librería, ';

  @override
  String get candy => 'Piso de tienda de dulces, ';

  @override
  String get toy => 'Piso de tienda de juguetes, ';

  @override
  String get luxury => 'Piso de boutique de lujo, ';

  @override
  String get sports => 'Piso de tienda de artículos deportivos, ';

  @override
  String get gym => 'Piso de gimnasio, ';

  @override
  String get sweets => 'Piso de tienda de postres, ';

  @override
  String get furniture => 'Piso de tienda de muebles, ';

  @override
  String get cinema => 'Piso de multicines, ';

  @override
  String get nameRooftop => 'El Piso Superior';

  @override
  String get nameVip => 'Sala VIP';

  @override
  String get nameRestaurant => 'Restaurante';

  @override
  String get nameSpa => 'Spa';

  @override
  String get nameArcade => 'Arcade';

  @override
  String get nameFoodCourt => 'Patio de comidas';

  @override
  String get nameIndoorPark => 'Parque interior';

  @override
  String get nameSupermarket => 'Supermercado';

  @override
  String get nameStation => 'Estación de metro';

  @override
  String get nameParking => 'Estacionamiento';

  @override
  String get nameApparel => 'Tienda de ropa';

  @override
  String get nameElectronics => 'Tienda de electrónicos';

  @override
  String get nameOutdoor => 'Tienda de equipos al aire libre';

  @override
  String get nameBookstore => 'Librería';

  @override
  String get nameCandy => 'Tienda de dulces';

  @override
  String get nameToy => 'Tienda de juguetes';

  @override
  String get nameLuxury => 'Boutique de lujo';

  @override
  String get nameSports => 'Tienda de artículos deportivos';

  @override
  String get nameGym => 'Gimnasio';

  @override
  String get nameSweets => 'Tienda de postres';

  @override
  String get nameFurniture => 'Tienda de muebles';

  @override
  String get nameCinema => 'Multicines';

  @override
  String get movingElevator => 'Ascensor en uso, por favor espere un momento.';

  @override
  String get photoAccessRequired => 'Se requiere permiso de acceso a fotos\n';

  @override
  String get photoAccessPermission =>
      'Para seleccionar tu foto, por favor permite el acceso completo a fotos desde la configuración.';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return 'Gana\n$NUMBER millas EV\nviendo anuncios\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return 'Para ganar $NUMBER millas EV, por favor vea anuncios durante la duración especificada.';
  }

  @override
  String get notConnectedInternet => 'Sin conexión a Internet';

  @override
  String notSignedInGameCenter(Object Platform) {
    return 'Inicia sesión en $Platform';
  }
}
