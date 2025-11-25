import UIKit

/// Отвечает за создание UI-окна и навигацию.
/// Запускает стартовый экран приложения.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Создание UI-окна и установка rootViewController.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        // Стартовый экран — FeedViewController в UINavigationController.
        let feedVC = FeedViewController()
        let nav = UINavigationController(rootViewController: feedVC)

        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Сцена была деактивирована системой.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Приложение стало активным — можно возобновить задачи.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Приложение уходит в неактивное состояние (звонок, блокировка экрана).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Переход приложения из background → foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Переход из foreground → background.
        // Здесь сохраняем данные.
        CoreDataStack.shared.saveContext()
    }
}
