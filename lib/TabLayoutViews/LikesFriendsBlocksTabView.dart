import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';

/// Display people I liked/friended/blocked on the left and people who liked/friended/blocked me on the right. Pass
/// in a static member of MainListDisplayViewModes for the viewMode parameter.
class LikesFriendsBlocksTabView extends StatefulWidget {
  const LikesFriendsBlocksTabView({Key? key, required this.viewMode, this.showingSentDataNotReceivedData = true}) :
        super
      (key: key);
  final String viewMode;
  final bool showingSentDataNotReceivedData;

  @override
  _LikesFriendsBlocksTabViewState createState() => _LikesFriendsBlocksTabViewState(viewMode: viewMode,
      showingSentDataNotReceivedData: showingSentDataNotReceivedData);
}

class _LikesFriendsBlocksTabViewState extends State<LikesFriendsBlocksTabView> {
  _LikesFriendsBlocksTabViewState({required this.viewMode, required this.showingSentDataNotReceivedData});

  final String viewMode;
  final bool showingSentDataNotReceivedData;
  final _tabController = CupertinoTabController();

  /// Create the left tab navigation bar icon, depending on the view mode
  Icon leftTabNavigationBarIcon(){
    if (viewMode == MainListDisplayViewModes.likes) return Icon(CupertinoIcons.heart_fill);
    else if (viewMode == MainListDisplayViewModes.friends) return Icon(CupertinoIcons.hand_thumbsup_fill);
    else if (viewMode == MainListDisplayViewModes.blocked) return Icon(CupertinoIcons
        .person_crop_circle_fill_badge_xmark);
    else return Icon(CupertinoIcons.exclamationmark_triangle_fill);
  }

  /// Create the left tab navigation bar label
  String leftTabNavigationBarLabel(){
    if (viewMode == MainListDisplayViewModes.likes) return "People I Like";
    else if (viewMode == MainListDisplayViewModes.friends) return "People I Friended";
    else if (viewMode == MainListDisplayViewModes.blocked) return "People I Blocked";
    else return "Error";
  }

  /// Create the right tab navigation bar icon, depending on the view mode
  Icon rightTabNavigationBarIcon(){
    if (viewMode == MainListDisplayViewModes.likes) return Icon(CupertinoIcons.heart);
    else if (viewMode == MainListDisplayViewModes.friends) return Icon(CupertinoIcons.hand_thumbsup);
    else if (viewMode == MainListDisplayViewModes.blocked) return Icon(CupertinoIcons
        .person_crop_circle_badge_xmark);
    else return Icon(CupertinoIcons.exclamationmark_triangle);
  }

  /// Create the right tab navigation bar label
  String rightTabNavigationBarLabel(){
    if (viewMode == MainListDisplayViewModes.likes) return "People Who Like Me";
    else if (viewMode == MainListDisplayViewModes.friends) return "People Who Friended Me";
    else if (viewMode == MainListDisplayViewModes.blocked) return "People Who Blocked Me";
    else return "Error";
  }

  @override
  void initState() {
    super.initState();

    // start on the left tab by default, but if otherwise specified, start on the right tab (i.e. if opening from a
    // push notification saying someone friended me)
    this._tabController.index = showingSentDataNotReceivedData ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: leftTabNavigationBarIcon(), label: leftTabNavigationBarLabel()),
          BottomNavigationBarItem(icon: rightTabNavigationBarIcon(), label: rightTabNavigationBarLabel()),
        ]),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (context) {
            switch (_tabController.index) {
              case 0:
                {
                  return MainListDisplayView(viewMode: viewMode, showingSentDataNotReceivedData: true);
                }
              case 1:
                {
                  return MainListDisplayView(viewMode: viewMode, showingSentDataNotReceivedData: false);
                }

              default:
                {
                  return Center(
                    child: Text("An error occurred. Please try again."),
                  );
                }
            }
          });
        });
  }
}
