import 'package:flutter/cupertino.dart';

/// Show a single-button CupertinoAlertDialog
void showSingleButtonAlert(
    {required BuildContext context,
    required String title,
    String? content,
    required String dismissButtonLabel,
    Function? onAlertDismissed}) {
  final alert = CupertinoAlertDialog(title: Text(title), content: content == null ? null : Text(content), actions: [
    CupertinoButton(
        child: Text(dismissButtonLabel),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert dialog
          if (onAlertDismissed != null) onAlertDismissed();
        })
  ]);
  showCupertinoDialog(context: context, builder: (context) => alert);
}

/// Show a two-button CupertinoAlertDialog
void showTwoButtonAlert(
    {required BuildContext context,
    required String title,
    String? content,
    required String cancelButtonLabel,
    required String actionButtonLabel,
    Color actionButtonColor = CupertinoColors.systemBlue,
    Function? onCancelButtonPressed,
    Function? onActionButtonPressed}) {
  final alert = CupertinoAlertDialog(title: Text(title), content: content == null ? null : Text(content), actions: [
    CupertinoButton(
        child: Text(cancelButtonLabel),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert dialog
          if (onCancelButtonPressed != null) onCancelButtonPressed();
        }),
    CupertinoButton(
        child: Text(actionButtonLabel, style: TextStyle(color: actionButtonColor)),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert dialog
          if (onActionButtonPressed != null) onActionButtonPressed();
        })
  ]);
  showCupertinoDialog(context: context, builder: (context) => alert);
}
