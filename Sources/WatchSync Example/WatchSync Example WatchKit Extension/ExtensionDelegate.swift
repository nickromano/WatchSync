//
//  ExtensionDelegate.swift
//  WatchSync Example WatchKit Extension
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import WatchKit
import WatchSync

class ExtensionDelegate: NSObject, WKExtensionDelegate {
  var subscriptionToken: SubscriptionToken?

  func applicationDidFinishLaunching() {
    WatchSync.shared.activateSession { error in
      if let error = error {
        print("Error activating session \(error.localizedDescription)")
        return
      }
      print("Activated")
    }

    subscriptionToken = WatchSync.shared.subscribeToMessages(ofType: MyMessage.self) { myMessage in
      print(myMessage)
    }
  }
}
