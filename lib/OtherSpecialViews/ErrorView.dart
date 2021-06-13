import 'package:flutter/cupertino.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: Center(
            child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
          "An error occurred. Check your internet connection and try again.",
          textAlign: TextAlign.center),
    )));
  }
}
