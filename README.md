# ⌚️WatchSync

WatchConnectivity wrapper with typed messages, better error handling, and simplified subscription APIs. It contains learnings from building [Pinnacle Climb Log](https://pinnacleclimb.com/).

## Example

### Send messages

Create a new message type that conforms to the `SyncableMessage` protocol. Uses `Codable` under the hood.

```swift
import WatchSync

struct MyMessage: SyncableMessage {
  let myString: String?
  let myDate: Date?
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

🛫 `WatchSync` will send the message using realtime messaging if the other device is `reachable`, otherwise it will fall back on `transferUserInfo` to ensure it is delivered. If it is sent using realtime messaging you will receive a `delivered` event.

🗒️ The message is compressed to reduce the likelihood of running into a `WCErrorCodePayloadTooLarge` error.

### Subscribe to new messages

Listen for changes from the paired device (iOS or watchOS)

```swift
struct MyView: View {
  var body: some View {
    Text("Hello")
      .onReceive(WatchSync.shared.publisher(for: MyMessage.self)) { message in
        print(message.myString, message.myDate)
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
struct MyView: View {
  var body: some View {
    Text("Hello")
      .onReceive(WatchSync.shared.applicationContextPublisher) { applicationContext in
        print(applicationContext)
      }
  }
}
```

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
