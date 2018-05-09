//
//  ViewController.swift
//  WatchSync Example
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import UIKit
import WatchSync

class ViewController: UIViewController {

    var subscriptionToken: SubscriptionToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        subscriptionToken = WatchSync.shared.subscribeToMessages(ofType: MyMessage.self) { myMessage in
            print(String(describing: myMessage.myString), String(describing: myMessage.myDate))
        }
    }

    @IBAction func sendMessageButtonPressed(_ sender: Any) {
        let myMessage = MyMessage(myString: "Test", myDate: Date())

        WatchSync.shared.sendMessage(myMessage) { result in
            switch result {
            case .failure(let failure):
                switch failure {
                case .sessionNotActivated:
                    break
                case .watchConnectivityNotAvailable:
                    break
                case .unableToSerializeMessageAsJSON(let error), .unableToCompressMessage(let error):
                    break
                case .watchAppNotPaired:
                    break
                case .watchAppNotInstalled:
                    break
                case .unhandledError(let error):
                    break
                case .badPayloadError(let error):
                    break
                case .failedToDeliver(let error):
                    let alertController = UIAlertController(title: "✅", message: "Failed to Deliver \(error.localizedDescription)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            case .sent:
                let alertController = UIAlertController(title: "✅", message: "Sent!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            case .delivered:
                let alertController = UIAlertController(title: "✅", message: "Delivery Confirmed", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
