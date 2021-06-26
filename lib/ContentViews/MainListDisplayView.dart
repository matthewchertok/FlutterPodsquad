import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';

class MainListDisplayView extends StatefulWidget {
  const MainListDisplayView(
      {Key? key, required this.viewMode, this.showingSentDataNotReceivedData = true, this.podName = "null"})
      : super(key: key);
  final String viewMode;
  final bool? showingSentDataNotReceivedData;
  final String? podName;

  @override
  _MainListDisplayViewState createState() => _MainListDisplayViewState(
      viewMode: this.viewMode,
      showingSentDataNotReceivedData: this.showingSentDataNotReceivedData,
      podName: this.podName);
}

class _MainListDisplayViewState extends State<MainListDisplayView> {
  final viewMode;
  final showingSentDataNotReceivedData;
  final podName;

  _MainListDisplayViewState(
      {required this.viewMode, required this.showingSentDataNotReceivedData, required this.podName});

  /// Determine which text to show in the navigation bar
  String navBarTitle({required String viewMode}) {
    switch (viewMode) {
      case MainListDisplayViewModes.myPods:
        {
          return "My Pods";
        }
      case MainListDisplayViewModes.peopleIMet:
        {
          return "People I Met";
        }

      case MainListDisplayViewModes.likes:
        {
          return "Likes";
        }
      case MainListDisplayViewModes.friends:
        {
          return "Friends";
        }
      case MainListDisplayViewModes.blocked:
        {
          return "Blocked Users";
        }
      case MainListDisplayViewModes.podMembers:
        {
          return "$podName Members";
        }
      default:
        {
          return "Podsquad";
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(navBarTitle(viewMode: this.viewMode)),
        ),
        child: SafeArea(
          child: Column(
            children: [],
          ),
        ));
  }
}
