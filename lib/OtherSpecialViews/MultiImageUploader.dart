import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';
import 'package:podsquad/BackendFunctions/ResizeAndUploadImage.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/ContentViews/ViewFullImage.dart';
import 'package:podsquad/UIBackendClasses/MyProfileTabBackendFunctions.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

///Allow a user to upload 5 extra images to their profile
class MultiImageUploader extends StatefulWidget {
  const MultiImageUploader({Key? key}) : super(key: key);

  @override
  _MultiImageUploaderState createState() => _MultiImageUploaderState();
}

class _MultiImageUploaderState extends State<MultiImageUploader> {
  final _imagePicker = ImagePicker();

  /// The file that gets picked from the photo library
  File? _imageFile;

  /// Call this to reorder my extra images
  void _switchImagePosition({required String imageID, required int toNewPosition}) {
    final newPosition = toNewPosition;
    final imagesList = MyProfileTabBackendFunctions.shared.mySortedExtraImagesList.value;
    final originalImagePosition = imagesList.indexWhere((image) => image.id == imageID);

    // make sure the indices are not out of range
    if (newPosition < imagesList.length && originalImagePosition < imagesList.length) {
      var imageToMove = imagesList[originalImagePosition]; // this is the image that we want to move
      var imageToSwap = imagesList[newPosition]; // save the image that will be swapped with the image that we want to
      // move
      final imageWeJustMovedIDString = imageToMove.id;
      final imageWeJustSwappedIDString = imageToSwap.id;

      // update the database with the new image positions
      firestoreDatabase.collection("users").doc(myFirebaseUserId).update({
        "extraImages.$imageWeJustMovedIDString.position": newPosition,
        "extraImages.$imageWeJustSwappedIDString.position": originalImagePosition
      });
    }
  }

  /// Delete one of my extra images from Storage and Firestore
  void _deleteImage({required String imageID, Function? onCompletion}) {
    final imageToBeDeletedIDString = imageID;
    final myDocumentRef = firestoreDatabase.collection("users").doc(myFirebaseUserId);
    myDocumentRef.get().then((docSnapshot) {
      final myExtraImagesData = docSnapshot["extraImages"];
      final imageData = myExtraImagesData[imageToBeDeletedIDString];

      // first, delete the image from storage after getting its URL
      final imageURLString = imageData["imageURL"] as String;
      final deletedImagePosition = imageData["position"] as int;

      firebaseStorage.refFromURL(imageURLString).delete().then((value) {
        // for each of the images that weren't deleted, update their position
        myExtraImagesData.forEach((key, value) {
          final imageNotTOBeDeletedID = key;
          final imagePosition = value["position"] as int;

          // if the position was greater than the image I just deleted, decrease the position by 1 to reflect that an
          // image was removed
          if (imagePosition > deletedImagePosition) {
            final newPosition = imagePosition - 1;
            myDocumentRef.update({"extraImages.$imageNotTOBeDeletedID.position": newPosition});
          }
        });

        // now delete the image
        myDocumentRef.update({"extraImages.$imageToBeDeletedIDString": FieldValue.delete()}).then((value) {
          if (onCompletion != null) onCompletion(); // call the completion handler if there is one
        });
      });
    });
  }

  /// Pick an image and upload it
  /// Pick an image from the gallery
  void _pickImage({required ImageSource source}) async {
    final pickedImage = await _imagePicker.getImage(source: source);
    if (pickedImage == null) return;
    await _cropImage(sourcePath: pickedImage.path);
    final imagePosition =
        MyProfileTabBackendFunctions.shared.mySortedExtraImagesList.value.length; // the image position should be
    // the last index in the list when the image is picked, which should be one greater than the current last index
    // since the image is getting added
    if (this._imageFile != null)
      ResizeAndUploadImage.sharedInstance.uploadMyExtraImage(image: this._imageFile!, imagePosition: imagePosition);
  }

  /// Allow the user to select a square crop from their image
  Future _cropImage({required String sourcePath}) async {
    File? croppedImage = await ImageCropper.cropImage(
        maxHeight: 1080,
        maxWidth: 1080,
        sourcePath: sourcePath,
        aspectRatioPresets: [CropAspectRatioPreset.original],
        androidUiSettings: AndroidUiSettings(
            toolbarTitle: "Select Image", initAspectRatio: CropAspectRatioPreset.square, lockAspectRatio: true),
        iosUiSettings: IOSUiSettings(title: "Select Image", aspectRatioLockEnabled: true));
    setState(() {
      this._imageFile = croppedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: MyProfileTabBackendFunctions.shared.mySortedExtraImagesList,
        builder: (context, List<IdentifiableImage> imagesList, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var identifiableImage in imagesList)
                  Column(
                    children: [
                      // The delete image button, which should be above the image and to the right
                      Container(
                        width: 140, height: 25,
                        child: Row(
                          children: [
                            Spacer(),
                            CupertinoButton(
                                child: Icon(CupertinoIcons.xmark_circle_fill),
                                onPressed: () {
                                  final alert = CupertinoAlertDialog(
                                    title: Text("Remove Image"),
                                    content: Text("Are you sure "
                                        "you want to delete this image? You cannot undo this action."),
                                    actions: [
                                      // cancel button
                                      CupertinoButton(
                                          child: Text("No"),
                                          onPressed: () {
                                            Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                                          }),

                                      // confirm delete button
                                      CupertinoButton(
                                          child: Text(
                                            "Yes",
                                            style: TextStyle(color: CupertinoColors.destructiveRed),
                                          ),
                                          onPressed: () {
                                            _deleteImage(imageID: identifiableImage.id);
                                            Navigator.of(context, rootNavigator: true).pop();
                                          })
                                    ],
                                  );
                                  showCupertinoDialog(context: context, builder: (context) => alert);
                                })
                          ],
                        ),
                      ),
                      // The image and swap arrow
                      Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 20, 10),
                          child: Center(
                            child: Column(
                              children: [
                                // navigate to view the image
                                CupertinoButton(
                                    child: Container(
                                      width: 80,
                                      height: null,
                                      child: CachedNetworkImage(
                                        imageUrl: identifiableImage.imageURL,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                              builder: (context) => ViewFullImage(
                                                  urlForImageToView: identifiableImage.imageURL,
                                                  imageID: identifiableImage.id,
                                                  navigationBarTitle: "Caption Image",
                                                  canWriteCaption: true)));
                                    }),

                                // "swap position" buttons, if there's more than 1 image
                                if (imagesList.length > 1)
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                      child: Container(
                                        width: 112,
                                        child: Row(
                                          children: [
                                            // move the image to the left if it isn't already in the leftmost position
                                            if (imagesList.indexWhere((element) => element.id == identifiableImage.id) >
                                                0)
                                              CupertinoButton(
                                                  child: Icon(CupertinoIcons.arrow_left),
                                                  onPressed: () {
                                                    final currentPosition = imagesList
                                                        .indexWhere((element) => element.id == identifiableImage.id);
                                                    final newPosition = currentPosition - 1;
                                                    this._switchImagePosition(
                                                        imageID: identifiableImage.id, toNewPosition: newPosition);
                                                  }),

                                            Spacer(),

                                            // move the image to the right if it isn't already in the rightmost position
                                            if (imagesList.indexWhere((element) => element.id == identifiableImage.id) <
                                                imagesList.length - 1)
                                              CupertinoButton(
                                                  child: Icon(CupertinoIcons.arrow_right),
                                                  onPressed: () {
                                                    final currentPosition = imagesList
                                                        .indexWhere((element) => element.id == identifiableImage.id);
                                                    final newPosition = currentPosition + 1;
                                                    this._switchImagePosition(
                                                        imageID: identifiableImage.id, toNewPosition: newPosition);
                                                  })
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Center(child: Opacity(opacity: 0, child: Container(width: 112, child: Icon(CupertinoIcons.arrow_right))))
                              ],
                            ),
                          )),
                    ],
                  ),

                // If I have fewer than 5 images, include a button that gives the option to add another image
                if (MyProfileTabBackendFunctions.shared.mySortedExtraImagesList.value.length < 5)
                  Center(
                    child: CupertinoButton(
                        onPressed: () {
                          final sheet = CupertinoActionSheet(
                            actions: [
                              // take photo with camera
                              CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the action sheet
                                    _pickImage(source: ImageSource.camera);
                                  },
                                  child: Text("Take Photo")),

                              // choose from gallery
                              CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the action sheet
                                    _pickImage(source: ImageSource.gallery);
                                  },
                                  child: Text("Choose Photo"))
                            ],
                          );
                          showCupertinoModalPopup(context: context, builder: (context) => sheet);
                        },
                        child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(width: 2, color: CupertinoColors.systemBlue)),
                            child: Icon(CupertinoIcons.plus))),
                  )

              ],
            ),
          );
        });

    //TODO: Implement the logic for picking an image and deleting an image
  }
}
