import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Notifications locales affichées aussi quand DocSafe est ouvert
    // (flutter_local_notifications). À vérifier sur iOS.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DocSafePlatform") {
      registerPlatformChannel(messenger: registrar.messenger())
    }
  }

  /// Canal « docusafe/platform » côté iPhone (à vérifier sur iOS) :
  /// - excludeFromBackup : exclut un dossier de la sauvegarde iCloud et de la
  ///   sauvegarde de l'ordinateur (cahier des charges §3.7) ;
  /// - freeBytes : espace libre pour l'écran Stockage.
  private func registerPlatformChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "docusafe/platform", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "excludeFromBackup":
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
          result(FlutterError(code: "bad_request", message: nil, details: nil))
          return
        }
        var url = URL(fileURLWithPath: path, isDirectory: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(true)
        } catch {
          result(FlutterError(code: "exclude_failed", message: nil, details: nil))
        }
      case "freeBytes":
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        if let free = values?.volumeAvailableCapacityForImportantUsage {
          result(NSNumber(value: free))
        } else {
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
