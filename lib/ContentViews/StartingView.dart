import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:podsquad/BackendFunctions/PushNotificationSender.dart';
import 'package:podsquad/BackendDataclasses/NotificationTypes.dart';

class StartingView extends StatefulWidget {
  const StartingView({Key? key}) : super(key: key);

  @override
  _StartingViewState createState() => _StartingViewState();
}

class _StartingViewState extends State<StartingView> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    var brightness = SchedulerBinding.instance?.window.platformBrightness;
    isDarkMode = brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: Center(
            child: Column(children: [
      Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Login successful. This is the starting "
          "view!",
          textAlign: TextAlign.center,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      CupertinoButton(
          child: Text("Vote for Biden"),
          onPressed: () {
            showCupertinoDialog(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                      title: Text("Send Notification"),
                      content: Text("Are you sure you want to send a test notification? You must believe in science to "
                          "continue."),
                      actions: <Widget>[
                        CupertinoButton(child: Text("Yes, I voted for Biden"), onPressed: sendTestPushNotification),
                        CupertinoButton(
                            child: Text("No, I'm anti-vax"),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            })
                      ],
                    ));
          })
    ], mainAxisAlignment: MainAxisAlignment.center)));
  }

  void sendTestPushNotification() {
    PushNotificationSender.shared.sendPushNotification(
        recipientID: "TEST_TOPIC",
        title: "I Believe in Science",
        body: "Which is why I voted for Joe Biden. This is a test notification.",
        notificationType: NotificationTypes.none);
    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert dialog
  }
}
