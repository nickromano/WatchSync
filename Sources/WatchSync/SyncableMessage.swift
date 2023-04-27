//
//  WatchMessages.swift
//  WatchConnectivityExample
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation

/**
 Protocol for creating typed Watch/Phone messages

 To reduce the size of each message in transit, the object is JSON encoded.
 This is to help prevent running into the `WCErrorCodePayloadTooLarge` error.

 Unless your message schema will never change, I recommend making all fields
 optional. Otherwise Decodable will throw this error when new fields are
 added: `"No value associated with key"` from old message data.
 */
public protocol SyncableMessage: Codable {}

extension SyncableMessage {
  static var messageKey: String {
    String(describing: self)
  }
}
