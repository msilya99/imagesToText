import UIKit

final class WindowSetupHelper: NSObject {

    // MARK: - variables

    static let sh = WindowSetupHelper()
    private(set) var navController: UINavigationController?

    // MARK: - init.

    private override init() {}

    // MARK: - setup app main vc.
    func setup(window: UIWindow) {
        let navigationController = UINavigationController()
        navigationController.navigationBar.isHidden = true
        navController = navigationController
        let startVC = ViewController()

        navigationController.viewControllers = [startVC]
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
