//
//  ApplicationContextSubscription.swift
//  WatchSync iOS
//
//  Created by Nick Romano on 3/21/18.
//

import Foundation

public typealias ApplicationContextListener = ([String: Any]) -> Void

class ApplicationContextSubscription {
    private var callback: ApplicationContextListener?
    private var dispatchQueue: DispatchQueue

    func callCallback(_ message: [String: Any]) {
        dispatchQueue.async { [weak self] in
            self?.callback?(message)
        }
    }

    init(callback: ApplicationContextListener?, dispatchQueue: DispatchQueue) {
        self.callback = callback
        self.dispatchQueue = dispatchQueue
    }
}
