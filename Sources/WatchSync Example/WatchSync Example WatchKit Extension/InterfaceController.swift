//
//  InterfaceController.swift
//  WatchSync Example WatchKit Extension
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import WatchKit
import Foundation

import WatchSync

class InterfaceController: WKInterfaceController {

    var subscriptionToken: SubscriptionToken?

    @IBOutlet var receivedLabel: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        receivedLabel.setHidden(true)

        subscriptionToken = WatchSync.shared.subscribeToMessages(ofType: MyMessage.self) { [weak self] myMessage in
            self?.receivedLabel.setHidden(false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: {
                self?.receivedLabel.setHidden(true)
            })

            print(String(describing: myMessage.myString), String(describing: myMessage.myDate))
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
}
