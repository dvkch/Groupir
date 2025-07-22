//
//  SceneDelegate.swift
//  Groupir
//
//  Created by Stanislas Chevallier on 21/10/2021.
//

import UIKit
import SYKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let viewController = MainViewController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.tintColor = .systemPurple
        window?.rootViewController = UINavigationController(rootViewController: viewController)
        window?.rootViewController?.restorationIdentifier = "NC"
        window?.makeKeyAndVisible()
        (UIApplication.shared.delegate as! AppDelegate).window = window

        if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            viewController.continueFrom(activity: activity)
        }
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        viewController.updateUserActivity()
        return scene.userActivity
    }
    
    static var defaultActivityType: String {
        return (Bundle.main.infoDictionary?["NSUserActivityTypes"] as? [String])![0]
    }
}

