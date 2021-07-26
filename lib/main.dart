import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:podsquad/BackendFunctions/ReportedPeopleBackendFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/LoginView.dart';
import 'package:podsquad/OtherSpecialViews/LoadingView.dart';
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
  runApp(MyApp());
}

///Required for Firebase to work with Flutter
class MyApp extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<MyApp> {
  /// The future is part of the state of our widget. We should not call `initializeApp`
  /// directly inside [build].
  FirebaseMessaging _messaging = FirebaseMessaging.instance;

  ///This function can read push notification payload data and open a specified view.
  void respondToPushNotification() async {
    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //handle navigation when the app is in the background and a push notification is tapped to open it
      if (message.notification?.title == "Test Notification")
        Navigator.push(context, CupertinoPageRoute(builder: (context) => LoadingView()));
    });

    //Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    //handle navigation when the app is launched from a push notification
    if (initialMessage?.notification?.title == "Test Notification")
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LoadingView()));
  }

  /// Save the Firebase Messaging token when a users signs in, then upload it to Firestore to allow us to directly
  /// message a user. Users
  /// can be signed in on multiple devices, so we can use an array in the user's document to store all their tokens.
  Future _saveDeviceToken() async {
    final userID = firebaseAuth.currentUser?.uid;
    final fcmToken = await _messaging.getToken();
    if (userID != null && fcmToken != null){
      await firestoreDatabase.collection("users").doc(userID).set({
        // remember, this must be an array because a user can be
        // signed in (and therefore receive notifications) on multiple devices
        "fcmTokens": FieldValue.arrayUnion([fcmToken])
      }, SetOptions(merge: true));
    }
    return;
  }

  /// Delete a messaging token from the database when a user signs out, so that they don't receive notifications on
  /// devices where they aren't signed in
  Future _removeDeviceToken() async {
    final userID = firebaseAuth.currentUser?.uid;
    final fcmToken = await _messaging.getToken();
    if (userID != null && fcmToken != null){
      await firestoreDatabase.collection("users").doc(userID).set({
        // remember, this must be an array because a user can be
        // signed in (and therefore receive notifications) on multiple devices
        "fcmTokens": FieldValue.arrayRemove([fcmToken])
      }, SetOptions(merge: true));
    }
    return;
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) _messaging.requestPermission();
    Permission.bluetooth.request();
    respondToPushNotification();
  }

  @override
  Widget build(BuildContext context) {

    // Only allow portrait mode (app looks weird in landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);

    // Enable the wakelock to stop the screen from going to sleep (enables Discover Nearby to scan as long as the app
    // is open)
    Wakelock.enable();

    return CupertinoApp(
        home: ValueListenableBuilder(
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
                return FutureBuilder(future: MyProfileTabBackendFunctions.shared.getMyProfileData(), builder:
                    (context, snapshot){
                      return WelcomeView();
                });
              }
              else {
                NearbyScanner.shared.stopPublishAndSubscribe();
                _removeDeviceToken();
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
                return LoginView();// stop listening to my profile data and reset if I sign
                // out
              }
            }));
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
