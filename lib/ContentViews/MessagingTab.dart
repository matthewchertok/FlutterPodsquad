import 'package:flutter/cupertino.dart';

class MessagingTab extends StatefulWidget {
  const MessagingTab({Key? key, required this.isPodMode}) : super(key: key);
  final bool isPodMode;

  @override
  _MessagingTabState createState() => _MessagingTabState(isPodMode: this.isPodMode);
}

class _MessagingTabState extends State<MessagingTab> {
  final bool isPodMode;

  _MessagingTabState({required this.isPodMode});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(isPodMode ? "Pod Messages" : "Direct Messages"),
        ),
        child: SafeArea(
          child: Column(
           children: [],
          ),
        ));
  }
}
