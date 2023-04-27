//
//  MessageSubscription.swift
//  WatchSync iOS
//
//  Created by Nicholas Romano on 3/15/18.
//

import Foundation

public typealias MessageListener = ([String: Any]) -> Void

class MessageSubscription {
  private var callback: MessageListener?
  private var dispatchQueue: DispatchQueue

  func callCallback(_ message: [String: Any]) {
    dispatchQueue.async { [weak self] in
      self?.callback?(message)
    }
  }

  init(callback: MessageListener?, dispatchQueue: DispatchQueue) {
    self.callback = callback
    self.dispatchQueue = dispatchQueue
  }
}
