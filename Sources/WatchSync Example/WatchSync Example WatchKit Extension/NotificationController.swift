//
//  NotificationController.swift
//  WatchSync Example WatchKit Extension
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation
import UserNotifications
import WatchKit

class NotificationController: WKUserNotificationInterfaceController {
  override func willActivate() {
    // This method is called when watch view controller is about to be visible to user
    super.willActivate()
  }

  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }

  /*
   override func didReceive(_ notification: UNNotification, withCompletion completionHandler: @escaping (WKUserNotificationInterfaceType) -> Swift.Void) {
       // This method is called when a notification needs to be presented.
       // Implement it if you use a dynamic notification interface.
       // Populate your dynamic notification interface as quickly as possible.
       //
       // After populating your dynamic notification interface call the completion block.
       completionHandler(.custom)
   }
   */
}
