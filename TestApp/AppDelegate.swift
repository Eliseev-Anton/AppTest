import UIKit

/// Точка входа приложения.
/// Отвечает за базовую конфигурацию и управление жизненным циклом.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Вызывается при запуске приложения.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }

    /// Создание новой сцены (актуально для мультиоконности iPadOS).
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    /// Сцена была удалена системой.
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {}
}
