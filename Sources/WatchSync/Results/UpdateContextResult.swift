//
//  UpdateContextResult.swift
//  WatchSync iOS
//
//  Created by Nick Romano on 3/21/18.
//

import Foundation

public typealias UpdateContextCallback = (UpdateContextResult) -> Void

public enum UpdateContextFailure {
    /// `WatchSync.shared.activateSession()` must finish before updating application context
    case sessionNotActivated
    case watchConnectivityNotAvailable

    #if os(iOS)
    case watchAppNotPaired
    case watchAppNotInstalled
    #endif

    case unhandledError(Error)
    case badPayloadError(Error)
}

public enum UpdateContextResult {
    case failure(UpdateContextFailure)
    case success
}
