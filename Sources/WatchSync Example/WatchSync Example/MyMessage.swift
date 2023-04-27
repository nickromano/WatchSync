//
//  MyMessage.swift
//  WatchSync Example
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation
import WatchSync

/**
 Example message
 */
struct MyMessage: SyncableMessage {
  var myString: String?
  var myDate: Date?
}
