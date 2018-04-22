//
//  WatchSync.swift
//  WatchConnectivityExample
//
//  Created by Nicholas Romano on 3/15/18.
//  Copyright © 2018 Ten Minute Wait. All rights reserved.
//

import Foundation
import WatchConnectivity

public struct CouldNotActivateError: Error {
}

/// Singleton to manage phone and watch communication
open class WatchSync: NSObject {
    public static let shared = WatchSync()

    public let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private var activationCallback: ((Error?) -> Void)?

    /// Loop through these when processing an incoming message
    ///
    /// I would prefer to use a Set here but not sure not sure how
    /// to implement the `Hashable` protocol on metatype `Type`
    private var registeredMessageTypes: [SyncableMessage.Type] = []

    /// Weak references to subscriptions for `SyncableMessage` messages
    private var syncableMessageSubscriptions = NSPointerArray.weakObjects()

    /// Weak references to subscriptions for `[String: Any]` messages
    private var messageSubscriptions = NSPointerArray.weakObjects()

    /// Weak references to subscriptions for applicationContext
    private var applicationContextSubscriptions = NSPointerArray.weakObjects()

    /// Weak references to subscriptions for file transfers
    private var fileTransferSubscriptions = NSPointerArray.weakObjects()

    /// Store callbacks until we receive a response from didFinish userInfoTransfer
    private var userInfoCallbacks: [WCSessionUserInfoTransfer: SendResultCallback?] = [:]

    /// Store callbacks until we receive a response from didFinish fileTransfer
    private var fileTransferCallbacks: [WCSessionFileTransfer: FileTransferCallback?] = [:]

    /// Called when launching the app for the first time to setup Watch Connectivity
    ///
    /// - Parameter activationCallback: Closure called when activation has finished.
    public func activateSession(activationCallback: @escaping (Error?) -> Void) {
        self.activationCallback = activationCallback
        session?.delegate = self
        session?.activate()
    }

    /// Observe messages of Type (Recommended)
    ///
    /// - Parameters:
    ///   - ofType: Message that conforms to `WatchSyncable` protocol
    ///   - queue: Queue to call the callback on.  Defaults to `.main`
    ///   - callback: Closure to be called when receiving a message
    /// - Returns: `SubscriptionToken` store this for as long as you would like to receive messages
    public func subscribeToMessages<T: SyncableMessage>(ofType: T.Type, on queue: DispatchQueue = DispatchQueue.main, callback: @escaping SyncableMessageListener<T>) -> SubscriptionToken {
        let subscription = SyncableMessageSunscription<T>(callback: callback, dispatchQueue: queue)

        let pointer = Unmanaged.passUnretained(subscription).toOpaque()
        syncableMessageSubscriptions.addPointer(pointer)

        if !registeredMessageTypes.contains(where: { watchSyncableType -> Bool in
            if watchSyncableType == T.self {
                return true
            }
            return false
        }) {
            registeredMessageTypes.append(ofType)
        }

        return SubscriptionToken(object: subscription)
    }

    /// Observe messages for all data that is not a `WatchSyncable` message
    ///
    /// - Parameters:
    ///   - queue: Queue to call the callback on.  Defaults to `.main`
    ///   - callback: Closure to be called when receiving a message
    /// - Returns: `SubscriptionToken` store this for as long as you would like to receive messages
    public func subscribeToMessages(on queue: DispatchQueue = DispatchQueue.main, callback: @escaping MessageListener) -> SubscriptionToken {
        let rawSubscription = MessageSubscription(callback: callback, dispatchQueue: queue)

        let pointer = Unmanaged.passUnretained(rawSubscription).toOpaque()
        messageSubscriptions.addPointer(pointer)

        return SubscriptionToken(object: rawSubscription)
    }

    /// Observer application context, also called immediately with the most recently received context
    ///
    /// - Parameters:
    ///   - queue: Queue to call the callback on.  Defaults to `.main`
    ///   - callback: Closure to be called when receiving an application context
    /// - Returns: `SubscriptionToken` store this for as long as you would like to application contexts
    public func subscribeToApplicationContext(on queue: DispatchQueue = DispatchQueue.main, callback: @escaping ApplicationContextListener) -> SubscriptionToken {
        let rawSubscription = ApplicationContextSubscription(callback: callback, dispatchQueue: queue)

        let pointer = Unmanaged.passUnretained(rawSubscription).toOpaque()
        applicationContextSubscriptions.addPointer(pointer)

        // Call immediately on the most recently received app context
        if let session = session {
            callback(session.receivedApplicationContext)
        }

        return SubscriptionToken(object: rawSubscription)
    }

    public func subscribeToFileTransfers(on queue: DispatchQueue = DispatchQueue.main, callback: @escaping FileTransferListener) -> SubscriptionToken {
        let rawSubscription = FileTransferSubscription(callback: callback, dispatchQueue: queue)

        let pointer = Unmanaged.passUnretained(rawSubscription).toOpaque()
        fileTransferSubscriptions.addPointer(pointer)

        return SubscriptionToken(object: rawSubscription)
    }

    /// Send a `WatchSyncable` message to the paired device (Recommended)
    ///
    /// The data is JSON serialized to reduce the size of the payload.
    /// If the device is reachable it will send it in realtime.
    /// If the device is not reachable, it will store it in a queue to be received later.
    ///
    /// ```
    /// WatchSync.shared.sendMessage(myMessage) { result in
    ///     // switch on result
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - message: object that conforms to `WatchSyncable`
    ///   - completion: Closure that provides a `SendResult` describing the status of the message
    public func sendMessage(_ message: SyncableMessage, completion: SendResultCallback?) {
        // Package message for sending
        let messageJSON: String
        do {
            messageJSON = try message.toJSONString()
        } catch let error {
            completion?(.failure(.unableToSerializeMessageAsJSON(error)))
            return
        }
        let data: [String: String] = [
            type(of: message).messageKey: messageJSON
        ]
        sendMessage(data, completion: completion)
    }

    private func transferUserInfo(_ message: [String: Any], in session: WCSession, completion: SendResultCallback?) {
        let transfer = session.transferUserInfo(message)
        userInfoCallbacks[transfer] = completion
        completion?(.sent)
    }

    /// Send a dictionary message to the paired device
    ///
    /// If the device is reachable it will send it in realtime.
    /// If the device is not reachable, it will store it in a queue to be received later.
    ///
    /// ```
    /// WatchSync.shared.sendMessage(["test": "hello"]) { result in
    ///     // switch on result
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - message: object that conforms to `WatchSyncable`
    ///   - completion: Closure that provides a `SendResult` describing the status of the message
    public func sendMessage(_ message: [String: Any], completion: SendResultCallback?) {
        guard let session = session else {
            logMessage("Watch connectivity not available")
            completion?(.failure(.watchConnectivityNotAvailable))
            return
        }
        guard session.activationState == .activated else {
            logMessage("Session not activated")
            completion?(.failure(.sessionNotActivated))
            return
        }

        #if os(iOS)
            guard session.isPaired else {
                logMessage("Watch app not paired")
                completion?(.failure(.watchAppNotPaired))
                return
            }
            guard session.isWatchAppInstalled else {
                logMessage("Watch app not installed")
                completion?(.failure(.watchAppNotInstalled))
                return
            }
        #endif

        guard session.isReachable else {
            logMessage("Watch app not reachable, transfer user info")

            transferUserInfo(message, in: session, completion: completion)
            return
        }

        logMessage("Reachable, trying to send message")
        session.sendMessage(message, replyHandler: { _ in
            self.logMessage("Delivered realtime message successfully")
            completion?(.delivered)
        }) { error in
            guard let watchError = error as? WCError else {
                completion?(.failure(.unhandledError(error)))
                return
            }

            switch watchError.code {
            case .sessionNotSupported, .sessionMissingDelegate, .sessionNotActivated,
                 .sessionInactive, .deviceNotPaired, .watchAppNotInstalled, .notReachable:
                // Shouldn't reach this state since we handle these above
                completion?(.failure(.unhandledError(watchError)))

            case .fileAccessDenied, .insufficientSpace:
                // Only relevant for file transfers
                completion?(.failure(.unhandledError(watchError)))

            case .genericError:
                // Not sure what can throw these
                completion?(.failure(.unhandledError(watchError)))

            case .invalidParameter, .payloadTooLarge, .payloadUnsupportedTypes:
                // Should be handled before sending again.
                completion?(.failure(.badPayloadError(watchError)))

            case .deliveryFailed, .transferTimedOut, .messageReplyTimedOut, .messageReplyFailed:
                // Retry sending in the background
                self.logMessage("Error sending message: \(error.localizedDescription), transfering user info")
                self.transferUserInfo(message, in: session, completion: completion)
            }
        }
    }

    /// Update the application context on the paired device.
    ///
    /// The paired device doesn't need to be reachable but the session must be activated
    ///
    /// - Parameters:
    ///   - applicationContext: Dictionary for the paired device
    ///   - completion: Closure that provides a `UpdateContextResult` describing the status of the update
    public func update(applicationContext: [String: Any], completion: UpdateContextCallback?) {
        guard let session = session else {
            logMessage("Watch connectivity not available")
            completion?(.failure(.watchConnectivityNotAvailable))
            return
        }
        guard session.activationState == .activated else {
            logMessage("Session not activated")
            completion?(.failure(.sessionNotActivated))
            return
        }

        #if os(iOS)
            guard session.isPaired else {
                logMessage("Watch app not paired")
                completion?(.failure(.watchAppNotPaired))
                return
            }
            guard session.isWatchAppInstalled else {
                logMessage("Watch app not installed")
                completion?(.failure(.watchAppNotInstalled))
                return
            }
        #endif

        do {
            try session.updateApplicationContext(applicationContext)
        } catch let error {
            guard let watchError = error as? WCError else {
                completion?(.failure(.unhandledError(error)))
                return
            }

            switch watchError.code {
            case .sessionNotSupported, .sessionMissingDelegate, .sessionNotActivated,
                 .sessionInactive, .deviceNotPaired, .watchAppNotInstalled, .notReachable:
                // Shouldn't reach this state since we handle these above
                completion?(.failure(.unhandledError(watchError)))

            case .fileAccessDenied, .insufficientSpace:
                // Only relevant for file transfers
                completion?(.failure(.unhandledError(watchError)))

            case .deliveryFailed, .transferTimedOut, .messageReplyTimedOut, .messageReplyFailed:
                // Only relevant for messages and transfers
                completion?(.failure(.unhandledError(watchError)))

            case .genericError:
                // Not sure what can throw these
                completion?(.failure(.unhandledError(watchError)))

            case .invalidParameter, .payloadTooLarge, .payloadUnsupportedTypes:
                // Should be handled before sending again.
                completion?(.failure(.badPayloadError(watchError)))
            }
        }
    }

    public func transferFile(file: URL, metadata: [String: Any]?, completion: FileTransferCallback?) {
        guard let session = session else {
            logMessage("Watch connectivity not available")
            completion?(.failure(.watchConnectivityNotAvailable))
            return
        }
        guard session.activationState == .activated else {
            logMessage("Session not activated")
            completion?(.failure(.sessionNotActivated))
            return
        }
        let transfer = session.transferFile(file, metadata: metadata)
        fileTransferCallbacks[transfer] = completion
        completion?(.sent)
    }

    /// Entrypoint for all received messages from the paired device.
    ///
    /// - Parameter message: Paired device message
    private func receivedMessage(_ message: [String: Any]) {
        var foundMessage = false
        // Call all observers based on message types
        for messageType in registeredMessageTypes {
            guard let messageJSONString = message[messageType.messageKey] as? String else {
                continue
            }

            let watchSyncableMessage: SyncableMessage
            do {
                watchSyncableMessage = try messageType.fromJSONString(messageJSONString)
                foundMessage = true
            } catch let error {
                logMessage("Unable to parse JSON \(error.localizedDescription)")
                continue
            }

            // Cleanup the subscriptions from time to time
            syncableMessageSubscriptions.compact()

            syncableMessageSubscriptions.allObjects.forEach { subscription in
                guard let subscription = subscription as? SubscriptionCallable else {
                    return
                }
                subscription.callCallback(watchSyncableMessage)
            }
        }
        // If there are no message types found, just give the raw payload back
        if !foundMessage {
            messageSubscriptions.compact()
            messageSubscriptions.allObjects.forEach { subscription in
                guard let subscription = subscription as? MessageSubscription else {
                    return
                }
                subscription.callCallback(message)
            }
        }
    }

    /// Override this function to log messages using your own tooling
    open func logMessage(_ message: String) {
        print(message)
    }
}

extension WatchSync: WCSessionDelegate {
    // MARK: Watch Activation, multiple devices can be paired and swapped with the phone
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logMessage("Session completed activation: \(activationState)")
        var error = error
        if error == nil && activationState != .activated {
            // We should hopefully never end up in this state, if activationState
            // isn't activated there should be an error with reason from Apple
            error = CouldNotActivateError()
        }
        activationCallback?(error)
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        logMessage("Session became inactive")
    }

    // Apple recommends trying to reactivate if the session has switched between devices
    public func sessionDidDeactivate(_ session: WCSession) {
        logMessage("Session deactivated, trying to setup for new device")
        session.activate()
    }
    #endif

    // MARK: Reachability
    public func sessionReachabilityDidChange(_ session: WCSession) {
        logMessage("Reachability changed: \(session.isReachable)")
    }

    // MARK: Realtime messaging (must be reachable)
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // All session delegate methods are called on a background thread.
        receivedMessage(message)
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        // All session delegate methods are called on a background thread.
        receivedMessage(message)
        // Reply handler is always called so the other device get's a confirmation the message was delivered in realtime
        replyHandler([:])
    }

    // MARK: FIFO messaging (queue's with delivery guarantees)
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        // All session delegate methods are called on a background thread.
        receivedMessage(userInfo)
    }

    public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        if let completion = userInfoCallbacks[userInfoTransfer] {
            if let error = error {
                guard let watchError = error as? WCError else {
                    completion?(.failure(.unhandledError(error)))
                    return
                }

                switch watchError.code {
                case .sessionNotSupported, .sessionMissingDelegate, .sessionNotActivated,
                     .sessionInactive, .deviceNotPaired, .watchAppNotInstalled, .notReachable,
                     .messageReplyTimedOut, .messageReplyFailed, .fileAccessDenied, .insufficientSpace:
                    // Not applicable for transfers
                    completion?(.failure(.unhandledError(watchError)))

                case .deliveryFailed, .transferTimedOut:
                    completion?(.failure(.failedToDeliver(watchError)))

                case .genericError:
                    // Not sure what can throw these
                    completion?(.failure(.unhandledError(watchError)))

                case .invalidParameter, .payloadTooLarge, .payloadUnsupportedTypes:
                    // Should be handled before sending again.
                    completion?(.failure(.badPayloadError(watchError)))
                }
            } else {
                completion?(.delivered)
            }
        }
    }

    /// Entrypoint for application contexts, use `subscribeToApplicationContext` to receive this data
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applicationContextSubscriptions.compact()
        applicationContextSubscriptions.allObjects.forEach { subscription in
            guard let subscription = subscription as? ApplicationContextSubscription else {
                return
            }
            subscription.callCallback(applicationContext)
        }
    }

    /// Entrypoint for received file transfers, use `subscribeToFileTransfer` to receive these
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        fileTransferSubscriptions.compact()
        fileTransferSubscriptions.allObjects.forEach { subscription in
            guard let subscription = subscription as? FileTransferSubscription else {
                return
            }
            subscription.callCallback(file)
        }
    }

    public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let callback = fileTransferCallbacks[fileTransfer] {
            if let error = error {
                callback?(.failure(.failedToSend(error)))
            } else {
                callback?(.delivered)
            }
        }
    }
}
