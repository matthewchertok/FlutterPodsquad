import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StartingView extends StatefulWidget {
  const StartingView({Key? key}) : super(key: key);

  @override
  _StartingViewState createState() => _StartingViewState();
}

class _StartingViewState extends State<StartingView> {
  ThemeMode _themeMode = ThemeMode.system;

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
        style: TextStyle(color: _themeMode == ThemeMode.dark ? Colors.white : Colors.black),
      ),
    )));
  }
}
