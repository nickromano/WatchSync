//
//  AppDelegate.swift
//  WatchSync Example
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import UIKit
import WatchSync

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        WatchSync.shared.activateSession { error in
            if let error = error {
                print("Error activating session \(error.localizedDescription)")
                return
            }
            print("Activated")
        }

        return true
    }
}
