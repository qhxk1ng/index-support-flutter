import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    // Grab the shared FlutterEngine that AppDelegate started and registered plugins on.
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let flutterViewController = FlutterViewController(
      engine: appDelegate.flutterEngine,
      nibName: nil,
      bundle: nil
    )

    // Create and display the window with Flutter as the root view.
    let newWindow = UIWindow(windowScene: windowScene)
    newWindow.rootViewController = flutterViewController
    self.window = newWindow
    newWindow.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {}
  func sceneDidBecomeActive(_ scene: UIScene) {}
  func sceneWillResignActive(_ scene: UIScene) {}
  func sceneWillEnterForeground(_ scene: UIScene) {}
  func sceneDidEnterBackground(_ scene: UIScene) {}
}


