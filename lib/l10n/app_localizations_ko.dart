// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get letsElevator => '렛츠 엘리베이터 네오';

  @override
  String get thisApp => '이 앱은 정말 실감나는 엘리베이터 시뮬레이터입니다.';

  @override
  String get menu => '메뉴';

  @override
  String get settings => '설정';

  @override
  String get glass => '관찰창';

  @override
  String get start => '시작';

  @override
  String get back => '뒤로';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get edit => '변경';

  @override
  String get basement => '지하';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER층에 도착하셨습니다. ';
  }

  @override
  String get ground => '지상층에 도착하셨습니다. ';

  @override
  String get openDoor => '문이 열립니다.';

  @override
  String get closeDoor => '문이 닫힙니다.';

  @override
  String get pushNumber => '층을 선택하세요.';

  @override
  String get upFloor => '올라갑니다.';

  @override
  String get downFloor => '내려갑니다.';

  @override
  String get notStop => '정차하지 않습니다.';

  @override
  String get emergency => '엘리베이터 점검을 위해 비상 정지합니다. ';

  @override
  String get return1st => '점검이 완료되었습니다. 1층으로 돌아갑니다. ';

  @override
  String get bypass => '통과 층';

  @override
  String get stop => '정차 층';

  @override
  String get changeNumber => '목적지 층수 변경';

  @override
  String get changeBasementNumber => '지하 층수 변경';

  @override
  String get changeImage => '플로어 이미지 변경';

  @override
  String get selectPhoto => '앨범에서 이미지 선택';

  @override
  String get cropPhoto => '이미지 자르기';

  @override
  String get eVMile => 'EV마일';

  @override
  String get eVMileRanking => 'EV마일\n순위';

  @override
  String earnMile(Object NUMBER) {
    return '$NUMBER\nEV마일\n획득!';
  }

  @override
  String get aboutEVMile =>
      '\n엘리베이터를 많이 탈수록 쌓이는 포인트입니다.\nEV 마일을 모으면 다양한 기능이 해제되고, 메뉴의 설정에서 변경할 수 있습니다.';

  @override
  String get rooftop => '옥상 층에 도착하셨습니다. ';

  @override
  String get vip => 'VIP 층에 도착하셨습니다. ';

  @override
  String get restaurant => '레스토랑 층에 도착하셨습니다. ';

  @override
  String get spa => '온천 층에 도착하셨습니다. ';

  @override
  String get arcade => '게임 센터 층에 도착하셨습니다. ';

  @override
  String get foodCourt => '푸드 코트 층에 도착하셨습니다. ';

  @override
  String get indoorPark => '실내 공원 층에 도착하셨습니다. ';

  @override
  String get supermarket => '슈퍼마켓 층에 도착하셨습니다. ';

  @override
  String get station => '지하철 역 층에 도착하셨습니다. ';

  @override
  String get parking => '주차장 층에 도착하셨습니다. ';

  @override
  String get apparel => '의류 매장 층에 도착하셨습니다. ';

  @override
  String get electronics => '가전제품 매장 층에 도착하셨습니다. ';

  @override
  String get outdoor => '아웃도어 용품점 층에 도착하셨습니다. ';

  @override
  String get bookstore => '서점 층에 도착하셨습니다. ';

  @override
  String get candy => '사탕 가게 층에 도착하셨습니다. ';

  @override
  String get toy => '장난감 가게 층에 도착하셨습니다. ';

  @override
  String get luxury => '고급 부티크 층에 도착하셨습니다. ';

  @override
  String get sports => '스포츠 용품점 층에 도착하셨습니다. ';

  @override
  String get gym => '피트니스 짐 층에 도착하셨습니다. ';

  @override
  String get sweets => '디저트 매장 층에 도착하셨습니다. ';

  @override
  String get furniture => '가구 매장 층에 도착하셨습니다. ';

  @override
  String get cinema => '영화관 층에 도착하셨습니다. ';

  @override
  String get nameRooftop => '옥상';

  @override
  String get nameVip => 'VIP 룸';

  @override
  String get nameRestaurant => '레스토랑';

  @override
  String get nameSpa => '온천';

  @override
  String get nameArcade => '게임 센터';

  @override
  String get nameFoodCourt => '푸드 코트';

  @override
  String get nameIndoorPark => '실내 공원';

  @override
  String get nameSupermarket => '슈퍼마켓';

  @override
  String get nameStation => '지하철 역';

  @override
  String get nameParking => '주차장';

  @override
  String get nameApparel => '의류 매장';

  @override
  String get nameElectronics => '가전제품 매장';

  @override
  String get nameOutdoor => '아웃도어 용품점';

  @override
  String get nameBookstore => '서점';

  @override
  String get nameCandy => '사탕 가게';

  @override
  String get nameToy => '장난감 가게';

  @override
  String get nameLuxury => '고급 부티크';

  @override
  String get nameSports => '스포츠 용품점';

  @override
  String get nameGym => '피트니스 짐';

  @override
  String get nameSweets => '디저트 매장';

  @override
  String get nameFurniture => '가구 매장';

  @override
  String get nameCinema => '영화관';

  @override
  String get movingElevator => '엘리베이터가 운행 중이므로 잠시 기다려 주십시오.';

  @override
  String get photoAccessRequired => '사진 권한이 필요합니다.';

  @override
  String get photoAccessPermission => '사진 권한을 허용해주세요.';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return '광고를 보고\n${NUMBER}EV마일\n얻자!\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return '지정된 시간 동안 광고를 보시면 ${NUMBER}EV마일을 획득할 수 있습니다.';
  }

  @override
  String get notConnectedInternet => '인터넷 연결이 없습니다';

  @override
  String notSignedInGameCenter(Object Platform) {
    return '$Platform에 로그인해주세요';
  }

  @override
  String get aboutLetsElevator => '렛츠 엘리베이터 란';

  @override
  String get termsAndPrivacyPolicy => '이용약관 및 개인정보처리방침';

  @override
  String get terms => '이용약관';

  @override
  String get officialPage => '공식 페이지';

  @override
  String get officialShop => '공식 샵';

  @override
  String get ranking => '랭킹';
}
