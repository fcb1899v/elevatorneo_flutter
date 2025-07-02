// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get letsElevator => '操作乐趣电梯新锐';

  @override
  String get thisApp => '这款应用程序是一个非常逼真的电梯模拟器。';

  @override
  String get menu => '菜单';

  @override
  String get settings => '设置';

  @override
  String get glass => '观察窗';

  @override
  String get aboutLetsElevator => '关于操作乐趣电梯';

  @override
  String get termsAndPrivacyPolicy => '使用条款和隐私政策';

  @override
  String get terms => '使用条款';

  @override
  String get officialPage => '官方页面';

  @override
  String get officialShop => '官方商店';

  @override
  String get ranking => '排名';

  @override
  String get start => '开始';

  @override
  String get back => '返回';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get edit => '编辑';

  @override
  String get bypass => '通過层';

  @override
  String get stop => '停靠层';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER层。';
  }

  @override
  String get ground => '地面层。';

  @override
  String get openDoor => '开门。';

  @override
  String get closeDoor => '关门。';

  @override
  String get pushNumber => '选择楼层。';

  @override
  String get upFloor => '上行。';

  @override
  String get downFloor => '下行。';

  @override
  String get notStop => '本层不停。';

  @override
  String get emergency => '为了检查电梯状态，将进行紧急停车。';

  @override
  String get return1st => '检查完成。返回一层。';

  @override
  String get changeNumber => '更改楼层';

  @override
  String get changeBasementNumber => '更改地下楼层';

  @override
  String get changeImage => '更改楼层图片';

  @override
  String get selectPhoto => '从相册选择图片';

  @override
  String get cropPhoto => '裁剪图片';

  @override
  String get eVMile => '电梯里程';

  @override
  String get eVMileRanking => '电梯里程\n排行';

  @override
  String earnMile(Object NUMBER) {
    return '获得\n$NUMBER\n电梯里程!';
  }

  @override
  String get aboutEVMile =>
      '\n这是乘坐电梯越多越能积累的积分。\n积累电梯里程后，可解锁各种功能，并可在菜单的设置中进行更改。';

  @override
  String get rooftop => '屋顶层。';

  @override
  String get vip => 'VIP室层。';

  @override
  String get restaurant => '餐厅层。';

  @override
  String get spa => '温泉层。';

  @override
  String get arcade => '游戏中心层。';

  @override
  String get foodCourt => '美食广场层。';

  @override
  String get indoorPark => '室内公园层。';

  @override
  String get supermarket => '超市层。';

  @override
  String get station => '地铁站层。';

  @override
  String get parking => '停车场层。';

  @override
  String get apparel => '服装店层。';

  @override
  String get electronics => '电器店层。';

  @override
  String get outdoor => '户外用品店层。';

  @override
  String get bookstore => '书店层。';

  @override
  String get candy => '糖果店。';

  @override
  String get toy => '玩具店层。';

  @override
  String get luxury => '奢侈品店层。';

  @override
  String get sports => '体育用品店层。';

  @override
  String get gym => '健身房层。';

  @override
  String get sweets => '甜品店层。';

  @override
  String get furniture => '家具店层。';

  @override
  String get cinema => '电影院层。';

  @override
  String get nameRooftop => '屋顶';

  @override
  String get nameVip => 'VIP室';

  @override
  String get nameRestaurant => '餐厅';

  @override
  String get nameSpa => '温泉';

  @override
  String get nameArcade => '游戏中心';

  @override
  String get nameFoodCourt => '美食广场';

  @override
  String get nameIndoorPark => '室内公园';

  @override
  String get nameSupermarket => '超市';

  @override
  String get nameStation => '地铁站';

  @override
  String get nameParking => '停车场';

  @override
  String get nameApparel => '服装店';

  @override
  String get nameElectronics => '电器店';

  @override
  String get nameOutdoor => '户外用品店';

  @override
  String get nameBookstore => '书店';

  @override
  String get nameCandy => '糖果店';

  @override
  String get nameToy => '玩具店';

  @override
  String get nameLuxury => '奢侈品店';

  @override
  String get nameSports => '体育用品店';

  @override
  String get nameGym => '健身房';

  @override
  String get nameSweets => '甜品店';

  @override
  String get nameFurniture => '家具店';

  @override
  String get nameCinema => '电影院';

  @override
  String get movingElevator => '电梯运行中，请稍候';

  @override
  String get photoAccessRequired => '需要照片访问权限\n';

  @override
  String get photoAccessPermission => '请在设置中允许完全访问照片。';

  @override
  String earnMilesAfterAdTitle(Object NUMBER) {
    return '看广告赚取$NUMBER电梯里程!\n';
  }

  @override
  String earnMilesAfterAdDesc(Object NUMBER) {
    return '如果您在指定的时间内观看广告，您可以获得$NUMBER电梯里程。';
  }

  @override
  String get notConnectedInternet => '当前没有网络连接';

  @override
  String notSignedInGameCenter(Object Platform) {
    return '请登录 $Platform';
  }
}
