import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';

/// If canWriteCaption is false, then imageID can be set to an empty string (or anything, really) - imageID is only
/// important if I'm trying to caption an image.
class ViewFullImage extends StatefulWidget {
  const ViewFullImage(
      {Key? key,
      required this.urlForImageToView,
      required this.imageID,
      required this.navigationBarTitle,
      required this.canWriteCaption,
      this.savedCaption})
      : super(key: key);
  final String urlForImageToView;
  final String imageID;
  final String navigationBarTitle;
  final bool canWriteCaption;
  final String? savedCaption;

  @override
  _ViewFullImageState createState() => _ViewFullImageState(
      urlForImageToView: urlForImageToView,
      imageID: imageID,
      navigationBarTitle: navigationBarTitle,
      canWriteCaption: canWriteCaption,
      savedCaption: savedCaption);
}

class _ViewFullImageState extends State<ViewFullImage> {
  _ViewFullImageState(
      {required this.urlForImageToView,
      required this.imageID,
      required this.navigationBarTitle,
      required this.canWriteCaption,
      this.savedCaption});

  final String urlForImageToView;
  final String imageID;
  final String navigationBarTitle;
  final bool canWriteCaption;

  /// Save the caption so that it can be reset if the user wants to
  String? savedCaption;

  final _captionTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If there is a saved caption, use it.
    _captionTextController.text = savedCaption ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(navigationBarTitle),
        ),
        child: SafeArea(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // the image to display. Put a progress indicator behind it, which will be covered up once the image loads
            Container(child: Expanded(child: Stack(children: [
              Center(child: CupertinoActivityIndicator()),
              PhotoView(imageProvider: NetworkImage(urlForImageToView), minScale: 0.25, maxScale: 2.0,),

            ],),),),


            // write and delete image captions
            if (canWriteCaption)
              // caption editing controls
              Container(color: isDarkMode ? CupertinoColors.black : CupertinoColors.white, child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CupertinoTextField(
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    controller: _captionTextController,
                    placeholder: "Caption this image...", minLines: 1,
                  ),

                  // Delete caption, clear text, reload text, and save caption buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // delete caption button
                      CupertinoButton(
                          child: Icon(CupertinoIcons.trash),
                          onPressed: () {
                            final alert = CupertinoAlertDialog(
                              title: Text("Delete Caption"),
                              content: Text("Are you sure "
                                  "you want to delete this caption? You cannot undo this action"),
                              actions: [
                                // cancel button
                                CupertinoButton(
                                    child: Text("No"),
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).pop();
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode()); // stop the text field from popping
                                      // back up
                                    }),

                                // delete button
                                CupertinoButton(
                                    child: Text(
                                      "Yes",
                                      style: TextStyle(color: CupertinoColors.destructiveRed),
                                    ),
                                    onPressed: () {
                                      ProfileDatabasePaths(userID: myFirebaseUserId)
                                          .userDataRef
                                          .update({"extraImages.$imageID.caption": FieldValue.delete()}).then((value) {
                                        _captionTextController.clear();
                                        savedCaption = null;
                                      });
                                      Navigator.of(context, rootNavigator: true).pop();
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode()); // stop the text field from popping
                                      // back up
                                    })
                              ],
                            );

                            // Only bother to delete the caption if there is one
                            if (savedCaption != null)
                              showCupertinoDialog(context: context, builder: (context) => alert);
                          }),

                      // erase text button
                      CupertinoButton(
                          child: Icon(CupertinoIcons.clear),
                          onPressed: () {
                            _captionTextController.clear();
                          }),

                      // refresh text button
                      CupertinoButton(
                          child: Icon(CupertinoIcons.arrow_clockwise),
                          onPressed: () {
                            _captionTextController.text = savedCaption ?? "";
                          }),

                      // save caption button
                      CupertinoButton(
                          child: Icon(CupertinoIcons.check_mark),
                          onPressed: () {
                            final alert = CupertinoAlertDialog(
                              title: Text("Submit Caption"),
                              content: Text("Would you "
                                  "like to caption this image?"),
                              actions: [
                                // cancel button
                                CupertinoButton(
                                    child: Text("No"),
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).pop();
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode()); // stop the text field from popping
                                      // back up
                                    }),

                                // caption button
                                CupertinoButton(
                                    child: Text("Yes"),
                                    onPressed: () {
                                      savedCaption =
                                          _captionTextController.text; // update the saved caption to the one we just
                                      // saved (regardless of whether it successfully updates in the database; if the user
                                      // intends to submit it, then their submission should become the new saved caption)
                                      ProfileDatabasePaths(userID: myFirebaseUserId).userDataRef.update(
                                          {"extraImages.$imageID.caption": _captionTextController.text}).then((value) {
                                        // show a success dialog
                                        final captionSuccess = CupertinoAlertDialog(
                                          title: Text("Caption Saved!"),
                                          actions: [
                                            CupertinoButton(
                                                child: Text("OK"),
                                                onPressed: () {
                                                  Navigator.of(context, rootNavigator: true).pop();
                                                })
                                          ],
                                        );
                                        showCupertinoDialog(context: context, builder: (context) => captionSuccess);
                                      }).catchError((error) {
                                        print("Caption failed to save: $error");
                                      });
                                      Navigator.of(context, rootNavigator: true).pop();
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode()); // stop the text field from popping
                                      // back up
                                    })
                              ],
                            );

                            // Only submit a caption if it isn't empty of blank, and if it's different from the saved
                            // caption.
                            if (_captionTextController.text.trim().isNotEmpty &&
                                _captionTextController.text.trim() != savedCaption)
                              showCupertinoDialog(context: context, builder: (context) => alert);
                          })
                    ],
                  )
                ],
              ),)
          ],
        )));
  }
}
