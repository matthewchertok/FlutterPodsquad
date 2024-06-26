import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';
import 'package:podsquad/BackendFunctions/ReportedPeopleBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/LoginView.dart';
import 'package:podsquad/ContentViews/MessagingView.dart';
import 'package:podsquad/ContentViews/ViewPersonDetails.dart';
import 'package:podsquad/ContentViews/ViewPodDetails.dart';
import 'package:podsquad/TabLayoutViews/LikesFriendsBlocksTabView.dart';
import 'package:podsquad/TabLayoutViews/WelcomeView.dart';
import 'package:podsquad/UIBackendClasses/MainListDisplayBackend.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/UIBackendClasses/MessagingTabFunctions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:wakelock/wakelock.dart';

import 'BackendDataHolders/UserAuth.dart';
import 'BackendFunctions/NearbyScanner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(CupertinoApp(home: MyApp(),));

}

///Required for Firebase to work with Flutter
class MyApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<MyApp> {
  ///This function can read push notification payload data and open a specified view.
  void respondToPushNotification() async {
    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //handle navigation when the app is in the background and a push notification is tapped to open it
      this._pushRoute(message: message);
    });

    //Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    //handle navigation when the app is launched from a push notification
    if (initialMessage != null) this._pushRoute(message: initialMessage);
  }

  /// A function to push the correct route when a notification is received
  void _pushRoute({required RemoteMessage message}) {
    print("RECEIVED MESSAGE WITH DATA ${message.data}.\n\n\nThe message type is ${message.data["notificationType"]}");
    // navigate to view Likes
    if (message.data["notificationType"] == NotificationTypes.like) {
      Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes.likes, showingSentDataNotReceivedData: false,)));
    }

    // navigate to view Friends
    else if (message.data["notificationType"] == NotificationTypes.friend) {
      Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(builder: (context) => LikesFriendsBlocksTabView(viewMode: MainListDisplayViewModes
              .friends, showingSentDataNotReceivedData: false,)));
    }

    // navigate to Messaging if a DM is received
    else if (message.data["notificationType"] == NotificationTypes.message) {
      final chatPartnerOrPodID = message.data["senderID"];
      final chatPartnerOrPodName = message.data["senderName"];
      final isPodMode = false;
      Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
          builder: (context) => MessagingView(
              chatPartnerOrPodID: chatPartnerOrPodID,
              chatPartnerOrPodName: chatPartnerOrPodName,
              isPodMode: isPodMode)));
    }

    // navigate to Messaging if a pod message is received
    else if (message.data["notificationType"] == NotificationTypes.podMessage) {
      final chatPartnerOrPodID = message.data["podID"];
      final chatPartnerOrPodName = message.data["podName"];
      final isPodMode = true;
      Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
              builder: (context) => MessagingView(
                  chatPartnerOrPodID: chatPartnerOrPodID,
                  chatPartnerOrPodName: chatPartnerOrPodName,
                  isPodMode: isPodMode)));
    }

    // navigate to view person details if I meet someone
    else if (message.data["notificationType"] == NotificationTypes.personDetails) {
      final personID = message.data["senderID"];
      Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) =>
          ViewPersonDetails(personID:
      personID)));
    }

    // navigate to view pod details in some cases
    else if (message.data["notificationType"] == NotificationTypes.podDetails) {
      final podID = message.data["podID"];
      Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => ViewPodDetails(podID: podID, showChatButton: true)));
    }
  }

  /// Save the Firebase Messaging token when a users signs in, then upload it to Firestore to allow us to directly
  /// message a user. Users
  /// can be signed in on multiple devices, so we can use an array in the user's document to store all their tokens.
  Future _saveDeviceToken() async {
    final userID = firebaseAuth.currentUser?.uid;
    final fcmToken = await firebaseMessaging.getToken();
    if (userID != null && fcmToken != null) {
      await firestoreDatabase.collection("users").doc(userID).set({
        // remember, this must be an array because a user can be
        // signed in (and therefore receive notifications) on multiple devices
        "fcmTokens": FieldValue.arrayUnion([fcmToken])
      }, SetOptions(merge: true));
    }
    return;
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) firebaseMessaging.requestPermission();
    FlutterAppBadger.removeBadge(); // clear the notification badge (if there is one)
    respondToPushNotification();
  }

  @override
  Widget build(BuildContext context) {
    // Only allow portrait mode (app looks weird in landscape)
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Enable the wakelock to stop the screen from going to sleep (enables Discover Nearby to scan as long as the app
    // is open)
    Wakelock.enable();

    // using a FocusDetector so that I can clear the notification badge every time the app goes to the foreground.
    // This is important in case the user minimizes the app without terminating it, then receives a notification and
    // opens the app. Without the focus detector, the badge would only clear if the app was terminated, then opened.
    return FocusDetector(child: ValueListenableBuilder(
        valueListenable: UserAuth.shared.isLoggedIn,
        builder: (BuildContext context, bool isLoggedIn, Widget? child) {
          if (isLoggedIn) {
            LatestPodMessagesDictionary.shared.getListOfIDsForPodsImIn();
            LatestDirectMessagesDictionary.shared.loadLatestMessageForAllDirectMessageConversations();
            MessagesDictionary.shared.preLoadAllDirectMessageConversations();
            MessagesDictionary.shared.preLoadAllPodMessageConversations();
            MessagesDictionary.shared.preLoadListOfDMsImInactiveFrom();
            MessagesDictionary.shared.preLoadListOfPodsImInactiveFrom();
            SentBlocksBackendFunctions.shared.addDataToListView();
            ReceivedBlocksBackendFunctions.shared.addDataToListView();
            SentLikesBackendFunctions.shared.addDataToListView();
            ReceivedLikesBackendFunctions.shared.addDataToListView();
            SentFriendsBackendFunctions.shared.addDataToListView();
            ReceivedFriendsBackendFunctions.shared.addDataToListView();
            ReportedPeopleBackendFunctions.shared.observeReportedPeople();
            ShowMyPodsBackendFunctions.shared.addDataToListView();
            PeopleIMetBackendFunctions.shared.addDataToListView();
            _saveDeviceToken(); // upload my messaging token to Firestore for more secure device-to-device messaging

            // Must wait until profile data is ready; otherwise we'll run into the issue of profile data not
            // loading. The reason I can't just put snapshots on profile data is that Flutter can behave weirdly,
            // such that opening a text field can cause the widget to think it disappeared, which causes the view
            // to reset and causes listeners to fire, erasing my changes and resetting my profile data to how it
            // was. Using a FutureBuilder guarantees that my profile data will be available when the app opens.
            return FutureBuilder(
                future: MyProfileTabBackendFunctions.shared.getMyProfileData(),
                builder: (context, snapshot) {
                  return WelcomeView();
                });
          } else {
            NearbyScanner.shared.stopPublishAndSubscribe();
            MyProfileTabBackendFunctions.shared.reset();
            LatestPodMessagesDictionary.shared.reset();
            LatestDirectMessagesDictionary.shared.reset();
            MessagesDictionary.shared.reset();
            MessagesDictionary.shared.reset();
            MessagesDictionary.shared.reset();
            MessagesDictionary.shared.reset();
            SentBlocksBackendFunctions.shared.reset();
            ReceivedBlocksBackendFunctions.shared.reset();
            SentLikesBackendFunctions.shared.reset();
            ReceivedLikesBackendFunctions.shared.reset();
            SentFriendsBackendFunctions.shared.reset();
            ReceivedFriendsBackendFunctions.shared.reset();
            ReportedPeopleBackendFunctions.shared.reset();
            ShowMyPodsBackendFunctions.shared.reset();
            PeopleIMetBackendFunctions.shared.reset();
            return LoginView(); // stop listening to my profile data and reset if I sign
            // out
          }
        }), onForegroundGained: (){
      FlutterAppBadger.removeBadge();
    });
  }
}

/*
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
 */
