# ⌚️WatchSync

[![CocoaPods](https://img.shields.io/cocoapods/v/WatchSync.svg)](http://cocoadocs.org/docsets/WatchSync/)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

WatchConnectivity wrapper with typed messages, better error handling, and simplified subscription APIs.

## Example

### Send messages

Create a new message type that conforms to the `SyncableMessage` protocol. Uses `Codable` under the hood.

```swift
import WatchSync

struct MyMessage: SyncableMessage {
    var myString: String?
    var myDate: Date?
}
```

Send the message from anywhere in the iOS or watchOS app.

```swift
let myMessage = MyMessage(myString: "Test", myDate: Date())

WatchSync.shared.sendMessage(myMessage) { result in
}
```

You can also send a simple dictionary as well.

```swift
WatchSync.shared.sendMessage(["test": "message"]) { result in
}
```

### Subscribe to new messages

Listen for changes from the paired device (iOS or watchOS)

```swift
class ViewController: UIViewController {
    var subscriptionToken: SubscriptionToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        subscriptionToken = WatchSync.shared.subscribeToMessages(ofType: MyMessage.self) { myMessage in
            print(String(describing: myMessage.myString), String(describing: myMessage.myDate))
        }
    }
}
```

### Update application context

```swift
WatchSync.shared.update(applicationContext: ["test": "context"]) { result in
}
```

### Subscribe to application context updates

```swift
appDelegateObserver = 

class ViewController: UIViewController {
    var subscriptionToken: SubscriptionToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        subscriptionToken = WatchSync.shared.subscribeToApplicationContext { applicationContext in
            print(applicationContext)
        }
    }
}
```

## How it works

* If the paired device is reachable, `WatchSync` will try to send using an interactive message with `session.sendMessage()`.
* If the paired device is unreachable, it will fall back to using `sendUserInfo()` instead.
* All messages conforming to `SyncableMessage` will be JSON serialized to reduce the size of the payload. This is to reduce the likelyhood of running into a `WCErrorCodePayloadTooLarge` error.
* For interactive messages it uses the `replyHandler` for delivery acknowledgments.

## Installation & Setup

In your `AppDelegate` (iOS) and `ExtensionDelegate` (watchOS) under `applicationDidFinishLaunching` you will need to activate the Watch Connectivity session.

```swift
WatchSync.shared.activateSession { error in
    if let error = error {
        print("Error activating session \(error.localizedDescription)")
        return
    }
    print("Activated")
}
```

## Error handling

The `sendMessage` method returns a closure with a result to switch on that reduces the number of possible states and [errors](https://developer.apple.com/documentation/watchconnectivity/wcerror) your app can end up in.

```swift
WatchSync.shared.sendMessage(myMessage) { result in
    switch result {
    case .failure(let failure):
        switch failure {
        case .sessionNotActivated:
            break
        case .watchConnectivityNotAvailable:
            break
        case .unableToSerializeMessageAsJSON(let error):
            break
        case .watchAppNotPaired:
            break
        case .watchAppNotInstalled:
            break
        case .unhandledError(let error):
            break
        case .badPayloadError(let error):
            break
        case failedToDeliver(let error):
            break
        }
    case .sent:
        break
    case .delivered:
        break
    }
}
```
