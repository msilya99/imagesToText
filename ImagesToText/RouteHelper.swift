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

    // MARK: - Action methods (currently not used in app, but will be needed in case of navigation)

    func pushVC(_ viewController: UIViewController, animated: Bool = false) {
        navController?.pushViewController(viewController, animated: animated)
    }

    func popVC() {
        navController?.popViewController(animated: false)
    }

    func popTo<T: UIViewController>(controllerType: T.Type, orPush vc: UIViewController) {
        let destinationVC = navController?.viewControllers
            .filter { $0 is T }
            .first

        if let destinationVC = destinationVC {
            popToVC(destinationVC)
        } else {
            pushVC(vc)
        }
    }

    func popToVC(_ vc: UIViewController, animated: Bool = true) {
        guard navController?.viewControllers.contains(vc) == true else {
            navController?.popToRootViewController(animated: animated)
            return
        }
        navController?.popToViewController(vc, animated: animated)
    }

    func presentVC(_ vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        navController?.present(vc, animated: animated, completion: completion)
    }

    func popToRoot(animated: Bool = true) {
        navController?.popToRootViewController(animated: animated)
    }

    func setVC(_ viewController: UIViewController, animated: Bool = false) {
        guard var currentViewControllers = navController?.viewControllers else { return }
        currentViewControllers.removeLast()
        currentViewControllers.append(viewController)
        navController?.setViewControllers(currentViewControllers, animated: animated)
    }

    func dismissVC(animated: Bool = false, completion: (() -> Void)? = nil) {
        navController?.dismiss(animated: animated, completion: { completion?() })
    }
}
