import Flutter
import UIKit
import flutter_foreground_task

@main
@objc class AppDelegate: FlutterAppDelegate {

  /// Shared engine that SceneDelegate will attach its FlutterViewController to.
  lazy var flutterEngine = FlutterEngine(name: "main", project: nil)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the engine and register plugins BEFORE scenes are created.
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: UISceneSession Lifecycle
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  override func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {}
}

