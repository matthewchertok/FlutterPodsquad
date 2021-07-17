import 'package:flutter/cupertino.dart';

class SearchTextField extends StatefulWidget {
  const SearchTextField({Key? key, required this.controller, this.placeholder = "Search", this.onSubmitted, this.onTextChanged,
    this
      .onClearButtonPressed}) : super
      (key: key);
  final TextEditingController controller;
  final String placeholder;
  final Function(String)? onSubmitted;
  final Function(String)? onTextChanged;
  final Function? onClearButtonPressed;

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState(controller: controller, placeholder: placeholder, onSubmitted:
  onSubmitted, onTextChanged: onTextChanged, onClearButtonPressed: onClearButtonPressed);
}

class _SearchTextFieldState extends State<SearchTextField> {
  _SearchTextFieldState({required this.controller, required this.placeholder, this.onSubmitted, this.onTextChanged, this
      .onClearButtonPressed});
  final TextEditingController controller;
  final String placeholder;
  final Function(String)? onSubmitted;
  final Function(String)? onTextChanged;
  final Function? onClearButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(height: 35, child: ClipRRect(child:
    CupertinoTextField(
      controller: controller,
      decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground),
      padding: EdgeInsets.only(left: 5),
      textCapitalization: TextCapitalization.words,
      placeholder: "Search",
      prefix: Padding(
        padding: EdgeInsets.only(left: 5),
        child: Icon(
          CupertinoIcons.search,
          size: 20,
          color: CupertinoColors.systemGrey,
        ),
      ),
      onSubmitted: onSubmitted, onChanged: onTextChanged,
      suffix: CupertinoButton(
        padding: EdgeInsets.only(left: 10),
        child: Icon(
          CupertinoIcons.xmark_circle_fill,
          color: CupertinoColors.systemGrey,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            controller.clear();
          });
          if (onClearButtonPressed != null) onClearButtonPressed!();
        },
      ),
      suffixMode: OverlayVisibilityMode.editing,
    ), borderRadius: BorderRadius.circular(8),),);
  }
}

