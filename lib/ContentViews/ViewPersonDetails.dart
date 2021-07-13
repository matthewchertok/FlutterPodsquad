import 'package:flutter/cupertino.dart';

class ViewPersonDetails extends StatefulWidget {
  const ViewPersonDetails({Key? key, required this.personID}) : super(key: key);
  final String personID;

  @override
  _ViewPersonDetailsState createState() => _ViewPersonDetailsState(personID: this.personID);
}

class _ViewPersonDetailsState extends State<ViewPersonDetails> {
  _ViewPersonDetailsState({required this.personID});

  final String personID;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
