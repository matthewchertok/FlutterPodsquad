import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendFunctions/NearbyScanner.dart';

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
      navigationBar: CupertinoNavigationBar(middle: Text("Discover Nearby"),),
        child: SafeArea(
      child: Column(
        children: [],
      ),
    ));
  }
}
