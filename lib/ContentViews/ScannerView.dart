import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner.dart';
import 'package:podsquad/BackendFunctions/ShowLikesFriendsBlocksActionSheet.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({Key? key}) : super(key: key);

  @override
  _ScannerViewState createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  @override
  void initState() {
    super.initState();
    NearbyScanner.shared.publishAndSubscribe(); // start listening for people nearby over Bluetooth
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(padding: EdgeInsetsDirectional.all(5),
                  largeTitle: Text("Discover Nearby"),
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
