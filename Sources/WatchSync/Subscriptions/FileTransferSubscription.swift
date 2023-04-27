//
//  FileTransferSubscription.swift
//  WatchSync iOS
//
//  Created by Nick Romano on 3/26/18.
//

import Foundation
import WatchConnectivity

public typealias FileTransferListener = (WCSessionFile) -> Void

class FileTransferSubscription {
  private var callback: FileTransferListener?
  private var dispatchQueue: DispatchQueue

  func callCallback(_ message: WCSessionFile) {
    dispatchQueue.async { [weak self] in
      self?.callback?(message)
    }
  }

  init(callback: FileTransferListener?, dispatchQueue: DispatchQueue) {
    self.callback = callback
    self.dispatchQueue = dispatchQueue
  }
}
