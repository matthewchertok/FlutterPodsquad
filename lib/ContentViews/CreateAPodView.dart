import 'package:flutter/cupertino.dart';

/// Create a new pod (set isCreatingNewPod to true) or edit an existing pod (set isCreatingNewPod to false and pass
/// in the podID).
class CreateAPodView extends StatefulWidget {
  const CreateAPodView({Key? key, required this.isCreatingNewPod, this.podID}) : super(key: key);
  final bool isCreatingNewPod;

  /// Only required if isCreatingNewPod is false.
  final String? podID;

  @override
  _CreateAPodViewState createState() => _CreateAPodViewState(isCreatingNewPod: isCreatingNewPod, podID: podID);
}

class _CreateAPodViewState extends State<CreateAPodView> {
  _CreateAPodViewState({required this.isCreatingNewPod, this.podID});
  final bool isCreatingNewPod;
  final String? podID;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: CustomScrollView(slivers: [
      CupertinoSliverNavigationBar(largeTitle: Text(isCreatingNewPod ? "Create Pod" : "Edit Pod"),),
      
    ],));
  }
}
