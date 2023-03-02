import UIKit
import Flutter
import PushKit
import flutter_callkit_incoming
import CallKit
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        //Setup VOIP
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channelName = "dataFromFlutterChannel"
        methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController as! FlutterBinaryMessenger)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
              _ application: UIApplication,
              didReceiveRemoteNotification userInfo: [AnyHashable : Any],
              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ){

    //        let rootViewController : FlutterViewController = window?.rootViewController as! FlutterViewController
    //        let channelName = "dataFromFlutterChannel"
    //        methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: rootViewController as! FlutterBinaryMessenger)


          print("Recived: \(userInfo)")
          print("Local22")

    }

    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print("DeviceToken :- \(deviceToken)")
        //Save deviceToken to your server

        methodChannel?.invokeMethod("forVoipToken", arguments: deviceToken)

        // SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
      print("didInvalidatePushTokenFor")
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }

    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")

        guard type == .voIP else { return }
        print(payload.dictionaryPayload)

        // Print notification payload data
        print("Push notification received: \(payload.dictionaryPayload)")

        //                let aps = payload.dictionaryPayload[AnyHashable("aps")]! as! NSDictionary
        let custom = payload.dictionaryPayload[AnyHashable("custom")]! as! NSDictionary
        let aps = payload.dictionaryPayload[AnyHashable("aps")]! as! NSDictionary

        ///Code Unlock
        let a = custom["a"]! as! NSDictionary
        let alert = aps["alert"]! as! NSDictionary
        // let notificationType = a["notificationType"] as! String
        let purpose = a["purpose"] as! String
        let callRequestId = a["callRequestId"] as! String
        let title = alert["title"] as! String

        // let callRequestId = a["callRequestId"] as! String
        print("purpose=\(purpose)")
        print("title=\(title)")
        // print("callRequestId=\(callRequestId)")
        // print("notificationType=\(notificationType)")


        let data = flutter_callkit_incoming.Data(id: "44d915e1-5ff4-4bed-bf13-c423048ec97a", nameCaller: "Hien Nguyen", handle: "0123456789", type: 0)

        data.nameCaller = title
        // data.extra = ["callRequestId": callRequestId.description]
        data.extra = ["callRequestId": callRequestId]

        if(purpose=="calling") {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
            methodChannel?.invokeMethod("forCallRequestId", arguments: callRequestId)
        } else if(purpose=="call_accepted") {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        }else if(purpose=="call_terminated") {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        }else if(purpose=="already_accepted") {
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        }
    }
}
