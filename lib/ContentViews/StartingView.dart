import 'package:flutter/cupertino.dart';

class StartingView extends StatefulWidget {
  const StartingView({Key? key}) : super(key: key);

  @override
  _StartingViewState createState() => _StartingViewState();
}

class _StartingViewState extends State<StartingView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("Login successful. This is the starting view!"),
    );
  }
}
