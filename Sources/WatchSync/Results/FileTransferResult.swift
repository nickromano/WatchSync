//
//  FileTransferResult.swift
//  WatchSync iOS
//
//  Created by Nick Romano on 3/26/18.
//

import Foundation

public typealias FileTransferCallback = (FileTransferResult) -> Void

public enum FileTransferFailure {
    /// `WatchSync.shared.activateSession()` must finish before transfering files
    case sessionNotActivated
    case watchConnectivityNotAvailable

    #if os(iOS)
    case watchAppNotPaired
    case watchAppNotInstalled
    #endif

    case failedToSend(Error)
}

public enum FileTransferResult {
    case failure(FileTransferFailure)
    case sent
    case delivered
}
