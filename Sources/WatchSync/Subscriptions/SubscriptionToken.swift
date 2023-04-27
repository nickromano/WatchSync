//
//  SubscriptionToken.swift
//  WatchSync iOS
//
//  Created by Nicholas Romano on 3/15/18.
//

import Foundation

/// Keep a strong reference to this when you want to continue receiving messages
public class SubscriptionToken {
  private var object: Any?
  init(object: Any) {
    self.object = object
  }
}
