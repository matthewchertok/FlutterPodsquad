import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
            child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        "Login successful. This is the starting "
        "view!",
        textAlign: TextAlign.center,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    )));
  }
}
