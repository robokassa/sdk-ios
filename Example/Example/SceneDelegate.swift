import UIKit
import RobokassaSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let controller = ViewController()
        let navController = UINavigationController(rootViewController: controller)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("📤📤📤 Приложение стало активным в \(Date())")
        if let hasShownSuccessPayment = Storage().hasShownSuccessPayment {

            if !hasShownSuccessPayment {
                ServiceCheckPaymentStatus.shared.checkPaymentStatus()
                ServiceCheckPaymentStatus.shared.onSuccessHandler = { [weak self] info in
                    self?.presentResult(title: "Успешная оплата", message: "Оплата успешно завершена!\(info ?? "N/A")")
                    Storage().hasShownSuccessPayment = true
                }
                ServiceCheckPaymentStatus.shared.onFailureHandler = { [weak self] errorMessage in
                    self?.presentResult(title: "Уведомление", message: errorMessage)
                }
            } else {
                print("🔥 Уведомление об успехе уже показано 🔥")
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("📤 Приложение ушло в фоновый режим в \(Date())")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    private func presentResult(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let navController = window?.rootViewController as? UINavigationController,
           let topController = navController.topViewController {
            topController.present(alert, animated: true)
        } else if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(alert, animated: true)
        }
    }

}

