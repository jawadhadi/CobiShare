//
//  AppDelegate.swift
//  CobiShare
//
//  Created by Hadi on 20/11/2018.
//  Copyright © 2018 Hadi. All rights reserved.
//

import UIKit
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        GMSServices.provideAPIKey("AIzaSyCoJePX2BjZIJLCjQHsY_RQTRlH-4h_ByM")
        
        return true
    }

}

