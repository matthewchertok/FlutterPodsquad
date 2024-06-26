import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///Show an iOS-style progress spinner
class LoadingView extends StatelessWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: Center(child: Column(children: [CupertinoActivityIndicator(), Text("Loading...")
    ], mainAxisAlignment: MainAxisAlignment.center)));
  }
}
