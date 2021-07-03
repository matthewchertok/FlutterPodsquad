import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/ProfileDatabasePaths.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';
import 'package:uuid/uuid.dart';

///Contains methods to resize and upload an image to Firebase Storage
class ResizeAndUploadImage {
  static final sharedInstance = ResizeAndUploadImage();

  /// After the thumbnail is uploaded (if the image is a profile photo) and a download URL is ready, assign it to this
  /// property
  String? downloadedThumbnailURL;

  /// After the image is uploaded and a download URL is ready, assign it to this property
  String? downloadedFullImageURL;

  /// Use this to tell MyProfileTab to display a loading spinner if an image is actively uploading
  ValueNotifier<bool> isUploadInProgress = ValueNotifier(false);

  /// Upload my profile thumbnail and full image to Firebase Storage and set the thumbnail and full image URL in
  /// Firestore.
  Future<void> uploadMyProfileImage({required File image, required Function onUploadComplete}) async {
    final thumbnailStoragePath = ProfileDatabasePaths(userID: myFirebaseUserId).profileImageThumbnailRef;
    final fullImageStoragePath = ProfileDatabasePaths(userID: myFirebaseUserId).profileImageFullImageRef;
    this.isUploadInProgress.value = true;

    /// Compress the image before uploading the thumbnail, in order to make it small to save storage space and
    /// improve loading times

    // resize the thumbnail and full image to make them smaller
    var inputImage = decodeImage(image.readAsBytesSync());
    if (inputImage == null) {
      this.isUploadInProgress.value = false;
      return;
    }

    // Get the aspect ratio. For some reason, resizing with aspect ratio using the built-in function doesn't work 
    // (image fails to upload).
    final currentWidth = inputImage.width;
    final currentHeight = inputImage.height;
    double targetToCurrentWidthRatio(targetWidth) => targetWidth/currentWidth;
    double targetToCurrentHeightRatio(targetHeight) => targetHeight/currentHeight;

    // We want to resize by the smaller of smaller of the two target to current ratios in order to make sure the
    // image does not exceed the maximum allowed width or height.
    int resizedImageWidth(targetWidth, targetHeight) => (currentWidth * min(targetToCurrentWidthRatio(targetWidth), 
        targetToCurrentHeightRatio(targetHeight)))
        .toInt();
    int resizedImageHeight(targetWidth, targetHeight) => (currentHeight * min(targetToCurrentWidthRatio(targetWidth), 
        targetToCurrentHeightRatio(targetHeight))).toInt();
    final resizingThumbnail = copyResize(inputImage, width: resizedImageWidth(250, 250), height: resizedImageHeight(250, 250)); // thumbnail is 
    // 125x125
    final resizingFullPhoto = copyResize(inputImage, width: resizedImageWidth(1080, 1080), height: resizedImageHeight(1080, 1080)); // full 
    // photo is 1080x1080

    // Save the thumbnail as a PNG and overwrite the original image
    image.writeAsBytesSync(encodePng(resizingThumbnail));

    // Create an output path for the compressed thumbnail
    final lastIndexThumbnail = image.path.lastIndexOf(RegExp(r'.jp'));
    final splitThumbnailPath = image.path.substring(0, lastIndexThumbnail);
    final thumbnailOutPath = "${splitThumbnailPath}_out${image.path.substring(lastIndexThumbnail)}";
    final thumbnailBytes =
        await FlutterImageCompress.compressAndGetFile(image.absolute.path, thumbnailOutPath, quality: 40).catchError((error){
          print("An error occurred while compressing my thumbnail: $error");
          this.isUploadInProgress.value = false;
        });
    if (thumbnailBytes == null) {
      this.isUploadInProgress.value = false;
      return;
    }

    // upload the thumbnail and get the download URL
    TaskSnapshot thumbnailUploadTask = await thumbnailStoragePath.putFile(thumbnailBytes).catchError((error){
      print("An error occurred while uploading my thumbnail to storage: $error");
      this.isUploadInProgress.value = false;
    });
    final pathToThumbnail = thumbnailUploadTask.ref.fullPath;
    final thumbnailDownloadURL = await thumbnailUploadTask.ref.getDownloadURL().catchError((error){
      print("Error getting my thumbnail download URL: $error");
      this.isUploadInProgress.value = false;
    });

    // Save the full photo as a png and overwrite the thumbnail
    image.writeAsBytesSync(encodePng(resizingFullPhoto));

    // Create an output path for the compressed full photo
    final lastIndexFullPhoto = image.path.lastIndexOf(RegExp(r'.jp'));
    final splitFullPhotoPath = image.path.substring(0, lastIndexFullPhoto);
    final fullPhotoOutPath = "${splitFullPhotoPath}_out${image.path.substring(lastIndexFullPhoto)}";
    final fullPhotoBytes = await FlutterImageCompress.compressAndGetFile(image.absolute.path, fullPhotoOutPath).catchError((error){
      print("Image compression error: $error");
      this.isUploadInProgress.value = false;
    });
    if (fullPhotoBytes == null) {
      this.isUploadInProgress.value = false;
      return;
    }

    // upload the full photo and get the download URL
    TaskSnapshot fullPhotoUploadTask = await fullImageStoragePath.putFile(fullPhotoBytes).catchError((error){
      print("An error occurred while uploading my full profile image to storage: $error");
      this.isUploadInProgress.value = false;
    });
    final pathToFullImage = fullPhotoUploadTask.ref.fullPath;
    final fullImageDownloadURL = await fullPhotoUploadTask.ref.getDownloadURL().catchError((error){
      print("Error getting the download URL: $error");
      this.isUploadInProgress.value = false;
    });

    // set my profile data with the thumbnail and full photo URL and path
    ProfileDatabasePaths(userID: myFirebaseUserId).userDataRef.set({
      "profileData": {
        "photoThumbnailURL": thumbnailDownloadURL,
        "photoThumbnailPath": pathToThumbnail,
        "fullPhotoURL"
            "": fullImageDownloadURL,
        "fullPhotoPath": pathToFullImage
      }
    }, SetOptions(merge: true)).then((value) {
      this.isUploadInProgress.value = false; // hide the loading spinner
      onUploadComplete(); // call the completion handler
    }).catchError((error){
      print("An error occurred while setting my new thumbnail URL: $error");
      this.isUploadInProgress.value = false;
    });
  }

  /// Upload one of my (max 5) extra images. The imagePosition parameter indicates which order the image should
  /// appear in (i.e. first, second, third, etc). The function also handles updating my profile with the image URL.
  Future<void> uploadMyExtraImage(
      {required File image, required int imagePosition, Function? onUploadComplete}) async {

    // create a unique ID to identify the image with
    final imageId = Uuid().v1();
    final imageStoragePath = ProfileDatabasePaths(userID: myFirebaseUserId).extraImagesStorageRef.child(imageId);

    /// Compress the image before uploading the thumbnail, in order to make it small to save storage space and
    /// improve loading times

    // resize the thumbnail and full image to make them smaller
    var inputImage = decodeImage(image.readAsBytesSync());
    if (inputImage == null) return;
    final resizedPhoto = inputImage.resizedWithAspectRatio(maxResizedWidth: 1080, maxResizedHeight: 1080); // max
    // allowed width or height for now is 1080 pixels

    // Save the photo as a png and overwrite the original image
    image.writeAsBytesSync(encodePng(resizedPhoto));

    // Create an output path for the compressed full photo
    final lastIndexFullPhoto = image.path.lastIndexOf(RegExp(r'.jp'));
    final splitFullPhotoPath = image.path.substring(0, lastIndexFullPhoto);
    final fullPhotoOutPath = "${splitFullPhotoPath}_out${image.path.substring(lastIndexFullPhoto)}";
    final fullPhotoBytes = await FlutterImageCompress.compressAndGetFile(image.absolute.path, fullPhotoOutPath);
    if (fullPhotoBytes == null) return;

    // upload the photo and get the download URL
    TaskSnapshot fullPhotoUploadTask = await imageStoragePath.putFile(fullPhotoBytes);
    final pathToFullImage = fullPhotoUploadTask.ref.fullPath;
    final fullImageDownloadURL = await fullPhotoUploadTask.ref.getDownloadURL();

    final identifiableImage = IdentifiableImage(id: imageId, imageURL: fullImageDownloadURL, position: imagePosition);
    final imageID = identifiableImage.id;

    /// Contains the information for the image
    final Map<String, dynamic> newImageDataDict = {
      "position": imagePosition,
      "imageURL": fullImageDownloadURL,
      "imagePath": pathToFullImage
    };

    // set my profile data with the thumbnail and full photo URL and path
    ProfileDatabasePaths(userID: myFirebaseUserId).userDataRef.set({
      "extraImages": {imageID: newImageDataDict}
    }, SetOptions(merge: true));

    if (onUploadComplete != null) onUploadComplete(); // call the completion handler
  }
}
