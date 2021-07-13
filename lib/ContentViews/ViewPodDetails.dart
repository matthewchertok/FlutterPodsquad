import 'package:flutter/cupertino.dart';

class ViewPodDetails extends StatefulWidget {
  const ViewPodDetails({Key? key, required this.podID}) : super(key: key);
  final String podID;

  @override
  _ViewPodDetailsState createState() => _ViewPodDetailsState(podID: this.podID);
}

class _ViewPodDetailsState extends State<ViewPodDetails> {
  _ViewPodDetailsState({required this.podID});
  final String podID;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
