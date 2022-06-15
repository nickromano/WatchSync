//
//  SyncableMessageSubscription.swift
//  WatchSync iOS
//
//  Created by Nicholas Romano on 3/15/18.
//

import Foundation

public typealias SyncableMessageListener<T: SyncableMessage> = (T) -> Void

protocol SubscriptionCallable: AnyObject {
    func callCallback(_ message: SyncableMessage)
}

class SyncableMessageSunscription<T: SyncableMessage>: SubscriptionCallable {
    private var callback: SyncableMessageListener<T>?
    private var dispatchQueue: DispatchQueue

    func callCallback(_ message: SyncableMessage) {
        guard let message = message as? T else {
            // Drop message of other types
            return
        }
        dispatchQueue.async { [weak self] in
            self?.callback?(message)
        }
    }

    init(callback: SyncableMessageListener<T>?, dispatchQueue: DispatchQueue) {
        self.callback = callback
        self.dispatchQueue = dispatchQueue
    }
}
