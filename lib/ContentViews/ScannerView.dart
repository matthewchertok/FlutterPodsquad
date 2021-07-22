import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner.dart';
import 'package:podsquad/BackendFunctions/ShowLikesFriendsBlocksActionSheet.dart';
import 'package:podsquad/OtherSpecialViews/PodModeButton.dart';

/// This widget is actually not currently used. I had to create an equivalent of this on iOS because on iOS, running
/// Google Nearby significantly slowed down internet speeds to the point where I had to have a dedicated screen for
/// scanning with Bluetooth and I had to turn off Bluetooth whenever the user left that screen to maintain app
/// performance. Since slow internet with Nearby on isn't an issue in Flutter, I can simply take out the Discover
/// Nearby screen and move My Pods to the main tab layout.
class ScannerView extends StatefulWidget {
  const ScannerView({Key? key}) : super(key: key);

  @override
  _ScannerViewState createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  @override
  void initState() {
    super.initState();
  //  NearbyScanner.shared.publishAndSubscribe(); // start listening for people nearby over Bluetooth
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(padding: EdgeInsetsDirectional.all(5),
                  largeTitle: Text("Discover Nearby"), stretch: true,
                  leading: CupertinoButton(
                    child: Icon(CupertinoIcons.line_horizontal_3),
                    onPressed: () {
                      showLikesFriendsBlocksActionSheet(context: context);
                    },
                    padding: EdgeInsets.zero,
                  ),
                )
              ];
            },
            body: Center(child: Image.asset("assets/podsquad_logo_improved_2.png"))));
  }
}
