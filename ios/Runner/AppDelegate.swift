import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Store promo: the App Store sheet shown while the Dart side waits for it.
  private var storePromoChannel: FlutterMethodChannel?
  private var storeSession: StoreSession?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StorePromo") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "nakajimamasao.appstudio/store_promo",
      binaryMessenger: registrar.messenger()
    )
    storePromoChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "openAppStore":
        self?.openAppStore(arguments: call.arguments as? [String: Any] ?? [:], result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // The state of one openAppStore call: the sheet and whether the user closed it during the load.
  private final class StoreSession {
    let store: SKStoreProductViewController
    var awaitingLoad = true
    var closedWhileLoading = false

    init(store: SKStoreProductViewController) {
      self.store = store
    }
  }

  // Shows the store sheet at once, then loads the product.
  private func openAppStore(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let appId = arguments["appId"] as? String,
          let itemId = Int(appId),
          let presenter = topViewController() else {
      result(false)
      return
    }

    let store = SKStoreProductViewController()
    store.delegate = self
    let session = StoreSession(store: store)
    storeSession = session
    presenter.present(store, animated: true)

    var parameters: [String: Any] = [
      SKStoreProductParameterITunesItemIdentifier: itemId
    ]
    if let ct = arguments["ct"] as? String, !ct.isEmpty {
      parameters[SKStoreProductParameterCampaignToken] = ct
    }
    if let pt = arguments["pt"] as? String, !pt.isEmpty {
      parameters[SKStoreProductParameterProviderToken] = pt
    }
    store.loadProduct(withParameters: parameters) { [weak self] loaded, _ in
      DispatchQueue.main.async {
        session.awaitingLoad = false
        if session.closedWhileLoading {
          // The user already closed the sheet: Dart must start watching before it hears storeClosed.
          result(true)
          self?.storePromoChannel?.invokeMethod("storeClosed", arguments: nil)
          return
        }
        if !loaded {
          store.dismiss(animated: true)
          if self?.storeSession === session { self?.storeSession = nil }
        }
        result(loaded)
      }
    }
  }

  // Returns the front-most view controller of the key window.
  private func topViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
    var top = windows.first { $0.isKeyWindow }?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

extension AppDelegate: SKStoreProductViewControllerDelegate {
  // Closes the store sheet when the user dismisses it, then tells Dart (after the load result if still loading).
  func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
    viewController.dismiss(animated: true)
    guard let session = storeSession, session.store === viewController else { return }
    storeSession = nil
    if session.awaitingLoad {
      session.closedWhileLoading = true
      return
    }
    storePromoChannel?.invokeMethod("storeClosed", arguments: nil)
  }
}
