//
//  SceneDelegate.swift
//  BluetoothChat
//
//  Created by Tim Oliver on 14/5/20.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit

extension AppDelegate {

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: scene)
        window.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window = window

        window.makeKeyAndVisible()
    }
}
