import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await GetStorage.init();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var storage = GetStorage();

  if (kDebugMode) {
    print("background message");
    print("background message: ${message.toMap()}");
    print("background message notification: ${message.notification}");
    print("background message data: ${message.data}");
  }
}

Future<void> _firebaseMessagingForegroundHandler(RemoteMessage message) async {
  var storage = GetStorage();

  AndroidNotificationDetails androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    "20",
    'consultation_channel',
    channelDescription: 'consultation_channel',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    ticker: 'ticker',
    visibility: NotificationVisibility.public,
    channelShowBadge: true,
    colorized: true,
    color: Colors.amber,
  );
  const IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);

  if (message.data['purpose'] == 'consultation_update') {
    if (kDebugMode) {
      print("Handling a foreground message: ${message.toMap()}");
      print("Handling a foreground message: ${message.notification}");
      print("Handling a foreground message: ${message.data}");
    }
    await flutterLocalNotificationsPlugin.show(
      0,
      message.data['title'],
      message.data['body'],
      platformChannelSpecifics,
      payload: 'for_consultation',
    );
  }

  if (message.data['purpose'] == 'topic') {
    AndroidNotificationDetails androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      "10",
      'topic_channel',
      channelDescription: 'topic_channel',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
      visibility: NotificationVisibility.public,
      channelShowBadge: true,
      colorized: true,
      color: Colors.amber,
    );
    const IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        0, message.notification!.title, message.notification!.body, platformChannelSpecifics,
        payload: 'for_topic');
  }
}

void main() {
  runApp(const MyApp());
}

Future<void> showCallkitIncoming(String uuid, String? title, String? message, String? callRequestId) async {
  var params = CallKitParams(
      id: uuid,
      nameCaller: title,
      //TITLE
      appName: 'Callkit',
      avatar: null,
      handle: message,
      //MESSAGE
      type: 1,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      textMissedCall: 'Missed call',
      textCallback: 'Call back',
      extra: <String, dynamic>{'callRequestId': callRequestId},
      headers: <String, dynamic>{'apiKey': 'abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          isShowCallback: false,
          isShowMissedCallNotification: false,
          ringtonePath: 'resource://raw/notification_tone',
          backgroundColor: '#59EBAF',
          backgroundUrl: null,
          actionColor: '#4CAF50'),
      ios: IOSParams(
          iconName: 'CallKitLogo',
          handleType: '',
          supportsVideo: true,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: true,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'notification_tone'));
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final channelName = 'dataFromFlutterChannel';

  var methodChannel;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    methodChannel = MethodChannel(channelName);
    methodChannel.setMethodCallHandler(_handleMethod);
    initOneSignal();
    initFirebase();
    initLocalNotification();
    initAwesome();
    listenerEvent(onEvent);
    super.initState();
  }

  @pragma('vm:entry-point')
  Future<void> _handleMethod(MethodCall call) async {
    final String utterance = call.arguments;
    if (kDebugMode) {
      print('Fluttet _handleMethod called !!!!!!!!!!!!!!!!!!!!!');
    }
    switch (call.method) {
      case "forVoipToken":
        break;
      case "forCallRequestId":
        if (kDebugMode) {
          print('forCallRequestId called --------------');
          print('forCallRequestId $utterance');
        }
        break;
      case "forAndroidNative":
        if (kDebugMode) {
          print('forAndroidNative called --------------');
        }
        break;
    }
  }

  initOneSignal() async {
    //Remove this method to stop OneSignal Debugging
    OneSignal.shared.setLogLevel(OSLogLevel.none, OSLogLevel.none);

    OneSignal.shared.setAppId("5364bd8a-6832-410c-9f14-d10bccb5c0c9");

    final status = await OneSignal.shared.getDeviceState();
    final String? osUserID = status?.userId;
    final String? osUserIDs = status?.pushToken;
    const externalUserId = '512'; // You will supply the external user id to the OneSignal SDK

    if (kDebugMode) {
      print("One User ID ==> $osUserID");
      print("One User ID ==> $osUserIDs");
    }

    // We will update this once he logged in and goes to dashboard.
    ////updateUserProfile(osUserID);
    // Store it into shared prefs, So that later we can use it.
    // Preferences.setOnesignalUserId(osUserID);

    // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
    OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
      if (kDebugMode) {
        print("Accepted permission: ");
        print('promptUserForPushNotificationPermission');
      }
    });

    OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
      // Will be called whenever a notification is received in foreground
      // Display Notification, pass null param for not displaying the notification

      if (kDebugMode) {
        print('setNotificationWillShowInForegroundHandler');
      }
      // event.complete(event.notification);
    });

    OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      // Will be called whenever a notification is opened/button pressed.
    });

    OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
      // Will be called whenever the permission changes
      // (ie. user taps Allow on the permission prompt in iOS)
    });

    OneSignal.shared.setSubscriptionObserver((OSSubscriptionStateChanges changes) {
      // Will be called whenever the subscription changes
      // (ie. user gets registered with OneSignal and gets a user ID)
    });

    OneSignal.shared.setEmailSubscriptionObserver((OSEmailSubscriptionStateChanges emailChanges) {
      // Will be called whenever then user's email subscription changes
      // (ie. OneSignal.setEmail(email) is called and the user gets registered
    });

// Setting External User Id with Callback Available in SDK Version 3.9.3+
//     OneSignal.shared.setExternalUserId(externalUserId).then((results) {
    OneSignal.shared.setExternalUserId(externalUserId).then((results) {
      if (kDebugMode) {
        print(results.toString());
      }
    }).catchError((error) {
      if (kDebugMode) {
        print(error.toString());
      }
    });
  }

  initFirebase() async {
    await Firebase.initializeApp();
    var firebaseMessaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print(
            'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
        print('Foreground Message ${message.toMap()}');
      }
      _firebaseMessagingForegroundHandler(message);
    });

    await firebaseMessaging.getToken().then((token) {
      if (kDebugMode) {
        print('Device Token FCM: $token');
      }
    });
    await firebaseMessaging.getAPNSToken().then((token) {
      if (kDebugMode) {
        print('Device Token APNS: $token');
      }
    });
  }

  void initLocalNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    const IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    InitializationSettings initializationSettings = const InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    var details = flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (kDebugMode) {
      print("getNotificationAppLaunchDetails$details");
    }

    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: (payload) {
      if (payload == 'for_consultation') {
      } else if (payload == 'for_topic') {
      } else if (payload == 'for_reminder') {
      } else {}
    });
  }

  void initAwesome() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'android_calling_key',
          channelName: 'Calling Channel',
          channelDescription: 'Calling channel for app calling',
          importance: NotificationImportance.Max,
          defaultPrivacy: NotificationPrivacy.Public,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
        )
      ],
    );

    await AwesomeNotifications().requestPermissionToSendNotifications(
      channelKey: 'android_calling_key',
      permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Vibration,
      ],
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
    );
  }

  Future<void> listenerEvent(Function? callback) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var storage = GetStorage();

    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        if (kDebugMode) {
          print('HOME: $event');
        }
        switch (event!.event) {
          case Event.ACTION_CALL_INCOMING:
            // TODO: received an incoming call
            break;
          case Event.ACTION_CALL_START:
            // TODO: started an outgoing call
            // TODO: show screen calling in Flutter
            break;
          case Event.ACTION_CALL_ACCEPT:
            // TODO: accepted an incoming call
            // TODO: show screen calling in Flutter
            if (kDebugMode) {
              print('<<<=======CALL ACCEPTED=======>>>');
            }

            break;
          case Event.ACTION_CALL_DECLINE:
            // TODO: declined an incoming call

            if (kDebugMode) {
              print('<<<=======CALL DECLINE=======>>>');
            }

            break;
          case Event.ACTION_CALL_ENDED:
            // TODO: ended an incoming/outgoing call
            break;
          case Event.ACTION_CALL_TIMEOUT:
            // TODO: missed an incoming call
            break;
          case Event.ACTION_CALL_CALLBACK:
            // TODO: only Android - click action `Call back` from missed call notification
            break;
          case Event.ACTION_CALL_TOGGLE_HOLD:
            // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_MUTE:
            // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_DMTF:
            // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_GROUP:
            // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_AUDIO_SESSION:
            // TODO: only iOS
            break;
          case Event.ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP:
            // TODO: only iOS
            break;
        }
        if (callback != null) {
          callback(event.toString());
        }
      });
    } on Exception {
      if (kDebugMode) {
        print('!!!!========Exception========!!!!');
      }
    }
  }

  onEvent(event) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NotificationController {
  static var storage = GetStorage();

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    await GetStorage.init().whenComplete(() {
      GetStorage().write("BACKGROUND_CALL_ACTIVE", true);
    });

    if (kDebugMode) {
      print('onActionReceivedMethod ');
      print('onActionReceivedMethod isBackgroundCallActive - ${GetStorage().read("BACKGROUND_CALL_ACTIVE")}');
      print('onActionReceivedMethod buttonKeyPressed ${receivedAction.buttonKeyPressed}');
      print('onActionReceivedMethod buttonKeyInput ${receivedAction.buttonKeyInput}');
      print('onActionReceivedMethod actionType ${receivedAction.actionType}');
      print('onActionReceivedMethod payload ${receivedAction.payload}');
    }

    if (receivedAction.actionType == ActionType.Default) {
      if (receivedAction.buttonKeyPressed == "acceptKey") {
      } else {}
    } else if (receivedAction.actionType == ActionType.SilentBackgroundAction) {}
  }
}
