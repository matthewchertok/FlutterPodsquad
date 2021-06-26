import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataHolders/UserAuth.dart';

class MyProfileTab extends StatefulWidget {
  const MyProfileTab({Key? key}) : super(key: key);

  @override
  _MyProfileTabState createState() => _MyProfileTabState();
}

class _MyProfileTabState extends State<MyProfileTab> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("My Profile Tab!"),
      ),
      child: SafeArea(
          child: Column(
            children: [
              Center(child:
              CupertinoButton(
                  child: Text("Sign Out"),
                  onPressed: () {
                    UserAuth.shared.logOut();
                  })
              )
            ],
          )
      ),
    );
  }
}
