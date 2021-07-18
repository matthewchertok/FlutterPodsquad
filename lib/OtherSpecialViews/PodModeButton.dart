import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/MainListDisplayViewModes.dart';
import 'package:podsquad/ContentViews/MainListDisplayView.dart';

/// Tap the button to navigate to view my pods
CupertinoButton podModeButton({required BuildContext context}) => CupertinoButton(child: Icon(CupertinoIcons
    .person_2_square_stack_fill), onPressed: (){
  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => MainListDisplayView(viewMode: MainListDisplayViewModes.myPods)));
}, padding: EdgeInsets.zero);