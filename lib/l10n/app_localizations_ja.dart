// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get letsElevator => 'レッツ・エレベーター・ネオ';

  @override
  String get thisApp => 'このアプリはすごくリアルなエレベーターシミュレーターです。';

  @override
  String get menu => 'メニュー';

  @override
  String get settings => '各種設定';

  @override
  String get glass => 'ガラス窓';

  @override
  String get start => 'スタート';

  @override
  String get back => '戻る';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get edit => '変更';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER階です。　';
  }

  @override
  String get ground => '地上階です。　';

  @override
  String get openDoor => 'ドアがひらきます。　';

  @override
  String get closeDoor => 'ドアがしまります。　';

  @override
  String get pushNumber => '行き先階ボタンを押してください。　';

  @override
  String get upFloor => 'うえにまいります。　';

  @override
  String get downFloor => 'したにまいります。　';

  @override
  String get notStop => 'ただいま押されたかいにはとまりません。　';

  @override
  String get emergency => 'エレベーターの状態を確認するため、緊急停止します。 ';

  @override
  String get return1st => '確認が完了しました。一階に戻ります。 ';

  @override
  String get bypass => '制限階';

  @override
  String get stop => '停止階';

  @override
  String get changeNumber => '行き先階数の変更';

  @override
  String get changeBasementNumber => '地下階数の変更';

  @override
  String get changeImage => 'フロア画像の変更';

  @override
  String get selectPhoto => 'アルバムから画像選択';

  @override
  String get cropPhoto => '写真の切り取り';

  @override
  String get eVMile => 'EVマイル';

  @override
  String get eVMileRanking => 'EVマイル\nランキング';

  @override
  String earnMile(Object NUMBER) {
    return '$NUMBER\nEVマイル\nゲット!';
  }

  @override
  String get aboutEVMile =>
      '\nエレベーターの乗れば乗るほどたまるポイントです。\nEVマイルをためると、様々な機能が解放され、メニューの各種設定で変更できます。';

  @override
  String get rooftop => '屋上階です。　';

  @override
  String get vip => 'VIPルーム階です。　';

  @override
  String get restaurant => 'レストラン階です。 ';

  @override
  String get spa => '温泉階です。　';

  @override
  String get arcade => 'ゲームセンター階です。　';

  @override
  String get foodCourt => 'フードコート階です。　';

  @override
  String get indoorPark => '屋内あそび場階です。　';

  @override
  String get supermarket => 'スーパー階です。　';

  @override
  String get station => '駅改札階です。　';

  @override
  String get parking => '駐車場階です。　';

  @override
  String get apparel => '洋服階です。　';

  @override
  String get electronics => 'デジタル家電階です。　';

  @override
  String get outdoor => 'アウトドア用品階です。　';

  @override
  String get bookstore => '本屋階です。　';

  @override
  String get candy => '駄菓子屋階です。　';

  @override
  String get toy => 'おもちゃ階です。　';

  @override
  String get luxury => '高級ブティック階です。　';

  @override
  String get sports => 'スポーツ用品階です。　';

  @override
  String get gym => 'ジム階です。　';

  @override
  String get sweets => 'パティスリー階です。　';

  @override
  String get furniture => '家具階です。　';

  @override
  String get cinema => '映画館階です。　';

  @override
  String get nameRooftop => '屋上階';

  @override
  String get nameVip => 'VIPルーム';

  @override
  String get nameRestaurant => 'レストラン';

  @override
  String get nameSpa => '温泉';

  @override
  String get nameArcade => 'ゲームセンター';

  @override
  String get nameFoodCourt => 'フードコート';

  @override
  String get nameIndoorPark => '屋内あそび場';

  @override
  String get nameSupermarket => 'スーパー';

  @override
  String get nameStation => '駅改札';

  @override
  String get nameParking => '駐車場';

  @override
  String get nameApparel => '洋服';

  @override
  String get nameElectronics => 'デジタル家電';

  @override
  String get nameOutdoor => 'アウトドア用品';

  @override
  String get nameBookstore => '本屋';

  @override
  String get nameCandy => '駄菓子屋';

  @override
  String get nameToy => 'おもちゃ';

  @override
  String get nameLuxury => '高級ブティック';

  @override
  String get nameSports => 'スポーツ用品';

  @override
  String get nameGym => 'ジム';

  @override
  String get nameSweets => 'パティスリー';

  @override
  String get nameFurniture => '家具';

  @override
  String get nameCinema => '映画館';

  @override
  String get movingElevator => 'エレベーターが動作中のため少々お待ちください';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return '広告を見て\n${NUMBER}EVマイル\nゲット!\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return '広告を指定の時間ご覧いただくと、${NUMBER}EVマイルが獲得できます。';
  }

  @override
  String get notConnectedInternet => 'インターネット接続がありません';

  @override
  String get rewardAdUnavailable => '動画を再生できません。広告の同意設定を確認するか、しばらくしてからお試しください';

  @override
  String notSignedInGameCenter(Object Platform) {
    return '$Platformにサインインが必要です';
  }

  @override
  String get aboutLetsElevator => 'レッツ・エレベーターとは';

  @override
  String get termsAndPrivacyPolicy => '利用規約・プライバシーポリシー';

  @override
  String get terms => '利用規約';

  @override
  String get officialPage => '公式ページ';

  @override
  String get officialShop => '公式ショップ';

  @override
  String get ranking => 'ランキング';

  @override
  String get premiumTitle => 'プレミアムパック';

  @override
  String get premiumNoAds => '広告表示がなくなります';

  @override
  String get premiumUnlockAll => '全てのデザインと機能が\n今すぐ使えます\nEVマイルを貯める必要はありません';

  @override
  String get premiumOneTime => '1回だけの購入です';

  @override
  String premiumPrice(Object PRICE) {
    return '$PRICEで購入する';
  }

  @override
  String get premiumBuy => '購入する';

  @override
  String get premiumRestore => '購入を復元';

  @override
  String get premiumThanks => 'ありがとうございます！すべて解放されました。';

  @override
  String get premiumFailed => '購入を完了できませんでした。';

  @override
  String get premiumRestoreFailed => '復元できる購入が見つかりませんでした。';

  @override
  String get premiumUnavailable => 'いま購入手続きを開始できません。\n時間をおいてもう一度お試しください。';

  @override
  String get nameAppliance => '生活家電';

  @override
  String get appliance => '生活家電階です。　';
}
