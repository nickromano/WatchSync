//
//  SendResult.swift
//  WatchSync
//
//  Created by Nicholas Romano on 3/15/18.
//

import Foundation

public typealias SendResultCallback = (SendResult) -> Void

public enum SendResultFailure {
    /// `WatchSync.shared.activateSession()` must finish before sending messages
    case sessionNotActivated
    case watchConnectivityNotAvailable
    /// The `WatchSyncable` message could not be encoded as JSON
    case unableToSerializeMessageAsJSON(Error)
    case unableToCompressMessage(Error)

    #if os(iOS)
    case watchAppNotPaired
    case watchAppNotInstalled
    #endif

    /// Can be timeouts or general connectivity failures, could retry
    case failedToDeliver(Error)

    case unhandledError(Error)
    case badPayloadError(Error)
}

/// Return codes for sending a message
public enum SendResult {
    case failure(SendResultFailure)
    case sent
    case delivered
}
