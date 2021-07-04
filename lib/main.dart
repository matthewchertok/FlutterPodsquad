import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:podsquad/ContentViews/LoginView.dart';
import 'package:podsquad/OtherSpecialViews/LoadingView.dart';
import 'package:podsquad/TabLayoutViews/WelcomeView.dart';
import 'package:podsquad/UIBackendClasses/MessagesDictionary.dart';
import 'package:podsquad/UIBackendClasses/MessagingTabFunctions.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';

import 'BackendDataHolders/UserAuth.dart';

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

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) _messaging.requestPermission();
    _messaging.subscribeToTopic("TEST_TOPIC");
    respondToPushNotification();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
        home: ValueListenableBuilder(
            valueListenable: UserAuth.shared.isLoggedIn,
            builder: (BuildContext context, bool isLoggedIn, Widget? child) {
              if (isLoggedIn) {
                LatestPodMessagesDictionary.shared.getListOfIDsForPodsImIn();
                LatestDirectMessagesDictionary.shared.loadLatestMessageForAllDirectMessageConversations();
                MessagesDictionary.shared.preLoadAllDirectMessageConversations();
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
                MyProfileTabBackendFunctions.shared.reset();
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
