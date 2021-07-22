import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/ContentViews/MyProfileTab.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';
import 'package:podsquad/ContentViews/MessagingTab.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  _WelcomeViewState createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  final _tabController = CupertinoTabController();

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_3), label: "People I Met"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bubble_left_bubble_right), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2_square_stack_fill), label: "My Pods"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: "My Profile")
        ]),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (context) {
            switch (_tabController.index) {
              case 0:
                {
                  return MainListDisplayView(viewMode: MainListDisplayViewModes.peopleIMet);
                }
              case 1:
                {
                  return MessagingTab();
                }
              case 2:
                {
                  return MainListDisplayView(viewMode: MainListDisplayViewModes.myPods);
                }
              case 3:
                {
                  return MyProfileTab();
                }
              default:
                {
                  return MyProfileTab();
                }
            }
          });
        });
  }
}
