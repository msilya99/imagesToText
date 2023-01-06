import UIKit

/// Main app router for pushing, presenting, poping, dismissing
final class RouteHelper: NSObject {

    // MARK: - variables

    static let sh = RouteHelper()
    private(set) var navController: UINavigationController?

    // MARK: - init.

    private override init() {}

    // MARK: - setup app main vc.
    func setup(window: UIWindow) {
        UIApplication.shared.isIdleTimerDisabled = true
        let navigationController = UINavigationController()
        navigationController.interactivePopGestureRecognizer?.isEnabled = false
        navigationController.navigationBar.isHidden = true
        navController = navigationController
        let startVC = ViewController()

        navigationController.viewControllers = [startVC]
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
