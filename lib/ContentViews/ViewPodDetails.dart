import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/PodData.dart';

class ViewPodDetails extends StatefulWidget {
  const ViewPodDetails({Key? key, required this.podID}) : super(key: key);
  final String podID;

  @override
  _ViewPodDetailsState createState() => _ViewPodDetailsState(podID: this.podID);
}

class _ViewPodDetailsState extends State<ViewPodDetails> {
  _ViewPodDetailsState({required this.podID});

  final String podID;

  PodData podData = PodData(
      name: "Name N/A",
      dateCreated: 0,
      description: "Description N/A",
      anyoneCanJoin: false,
      podID: "podID",
      podCreatorID: "podCreatorID",
      thumbnailURL: "thumbnailURL",
      fullPhotoURL: "fullPhotoURL",
      podScore: 0);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(podData.name),
        ),
        child: Center(
          child: Text("View "
              "Pod "
              "Details!"),
        ));
  }
}
