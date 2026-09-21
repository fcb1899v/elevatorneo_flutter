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
  String get basement => 'Sótano ';

  @override
  String floor(Object NUMBER) {
    return '${NUMBER}piso, ';
  }

  @override
  String get ground => 'Planta baja, ';

  @override
  String get openDoor => 'Abriendo puertas.';

  @override
  String get closeDoor => 'Cerrando puertas.';

  @override
  String get pushNumber => 'Seleccione piso.';

  @override
  String get upFloor => 'Subiendo.';

  @override
  String get downFloor => 'Bajando.';

  @override
  String get notStop => 'No se detiene en esta piso.';

  @override
  String get emergency => 'Parada de emergencia para revisión.';

  @override
  String get return1st => 'Verificación completada. Regresando al primer piso.';

  @override
  String get bypass => 'Restringido';

  @override
  String get stop => 'Detener';

  @override
  String get changeNumber => 'Cambiar piso';

  @override
  String get changeBasementNumber => 'Cambiar piso del sótano';

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
    return '¡Gana\n$NUMBER\nmillas EV!';
  }

  @override
  String get aboutEVMile =>
      '\nPuntos acumulados a través de frecuentes viajes en ascensor.\nLas millas EV acumuladas desbloquean varias funciones, que se pueden ajustar en la configuración del menú.';

  @override
  String get rooftop => 'El piso superior, ';

  @override
  String get vip => 'Piso VIP, ';

  @override
  String get restaurant => 'Piso de restaurante, ';

  @override
  String get spa => 'Piso de aguas termales, ';

  @override
  String get arcade => 'Piso de salón recreativo, ';

  @override
  String get foodCourt => 'Piso de patio de comidas, ';

  @override
  String get indoorPark => 'Piso de parque infantil, ';

  @override
  String get supermarket => 'Piso de supermercado, ';

  @override
  String get station => 'Piso de acceso a andenes, ';

  @override
  String get parking => 'Piso de estacionamiento, ';

  @override
  String get apparel => 'Piso de ropa, ';

  @override
  String get electronics => 'Piso de electrónica, ';

  @override
  String get outdoor => 'Piso de aire libre, ';

  @override
  String get bookstore => 'Piso de librería, ';

  @override
  String get candy => 'Piso de chucherías, ';

  @override
  String get toy => 'Piso de juguetería, ';

  @override
  String get luxury => 'Piso de boutique de lujo, ';

  @override
  String get sports => 'Piso de artículos deportivos, ';

  @override
  String get gym => 'Piso de gimnasio, ';

  @override
  String get sweets => 'Piso de pastelería, ';

  @override
  String get furniture => 'Piso de muebles, ';

  @override
  String get cinema => 'Piso de cine, ';

  @override
  String get nameRooftop => 'El Piso Superior';

  @override
  String get nameVip => 'Sala VIP';

  @override
  String get nameRestaurant => 'Restaurante';

  @override
  String get nameSpa => 'Aguas termales';

  @override
  String get nameArcade => 'Salón recreativo';

  @override
  String get nameFoodCourt => 'Patio de comidas';

  @override
  String get nameIndoorPark => 'Parque infantil';

  @override
  String get nameSupermarket => 'Supermercado';

  @override
  String get nameStation => 'Acceso a andenes';

  @override
  String get nameParking => 'Estacionamiento';

  @override
  String get nameApparel => 'Ropa';

  @override
  String get nameElectronics => 'Electrónica';

  @override
  String get nameOutdoor => 'Aire libre';

  @override
  String get nameBookstore => 'Librería';

  @override
  String get nameCandy => 'Chucherías';

  @override
  String get nameToy => 'Juguetería';

  @override
  String get nameLuxury => 'Boutique de lujo';

  @override
  String get nameSports => 'Artículos deportivos';

  @override
  String get nameGym => 'Gimnasio';

  @override
  String get nameSweets => 'Pastelería';

  @override
  String get nameFurniture => 'Muebles';

  @override
  String get nameCinema => 'Cine';

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
  String get rewardAdUnavailable =>
      'No hay vídeo disponible. Revisa tu consentimiento de anuncios o inténtalo más tarde';

  @override
  String notSignedInGameCenter(Object Platform) {
    return 'Inicia sesión en $Platform';
  }

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
  String get premiumTitle => 'Pack Premium';

  @override
  String get premiumNoAds => 'Sin anuncios';

  @override
  String get premiumUnlockAll =>
      'Todos los diseños y funciones,\ntuyos ahora mismo\nsin acumular millas EV';

  @override
  String get premiumOneTime => 'Una compra única';

  @override
  String premiumPrice(Object PRICE) {
    return 'Comprar por $PRICE';
  }

  @override
  String get premiumBuy => 'Comprar';

  @override
  String get premiumRestore => 'Restaurar compras';

  @override
  String get premiumThanks => '¡Gracias! Todo está desbloqueado.';

  @override
  String get premiumFailed => 'No se pudo completar la compra.';

  @override
  String get premiumRestoreFailed =>
      'No se encontró ninguna compra para restaurar.';

  @override
  String get premiumUnavailable =>
      'Las compras no están disponibles.\nInténtalo de nuevo más tarde.';

  @override
  String get nameAppliance => 'Electrodomésticos';

  @override
  String get appliance => 'Piso de electrodomésticos, ';
}
