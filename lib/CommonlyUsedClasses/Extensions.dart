import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:podsquad/BackendDataclasses/PodMessageDataclasses.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

extension Rounding on double {
  ///Round a double to a specified number of digits after the decimal point. Pass in 1 to round to the nearest tenth,
  /// 2 to round to the nearest hundredth, 3 to round to the nearest thousandth, etc.
  double roundToDecimalPlace(int digitsAfterDecimal) => double.parse(this.toStringAsFixed(digitsAfterDecimal));
}

extension StringComparison on String {
  ///Determine if a string comes before another string in the alphabet. Capital letters come before lowercase letters
  /// (i.e. Z comes before a).
  bool operator <(Object otherString) => otherString is String && this.compareTo(otherString) == -1 ? true : false;

  bool operator >(Object otherString) => otherString is String && this.compareTo(otherString) == 1 ? true : false;

  //Comparison returns 1 if the first string (this) is greater than the second (otherString). So as long as we don't
  //get 1, then the first string must be less than or equal to the second.
  bool operator <=(Object otherString) => otherString is String && this.compareTo(otherString) == 1 ? false : true;

  bool operator >=(Object otherString) => otherString is String && this.compareTo(otherString) == -1 ? false : true;
}

extension ProfileDataListExtensions on List<ProfileData> {
  ///Extracts the user IDs from a list of ProfileData objects.
  List<String> memberIDs() => this.map((element) => element.userID).toList();

  ///Removes a specified person from an array
  void removePersonFromList({required String personUserID}) {
    this.removeWhere((element) => element.userID == personUserID);
  }
}

extension ListDifference on List {
  ///Return the difference between two lists (removes all elements that are the same in both)
  List difference({required List betweenOtherList}) {
    final firstList = this;
    final secondList = betweenOtherList; // renaming the external named parameter for clarity
    final difference = firstList.toSet().difference(secondList.toSet()).toList();
    return difference;
  }
}

extension PodMessageListExtensions on List<PodMessage> {
  ///Change the sender name and/or thumbnail URL on a particular pod message. Useful when listening for member name
  ///changes in a pod conversation.
  void changeSenderNameAndOrThumbnailURL(
      {required String forMessageWithID, String? toNewName, String? toNewThumbnailURL}) {
    final messageID = forMessageWithID;
    final newName = toNewName;
    final newThumbnailURL = toNewThumbnailURL;

    // find the message with the matching ID, then change it (also checking to make sure the index isn't out of range
    // just to be super safe)
    var indexOfMatchingMessage = this.indexWhere((message) => message.id == messageID);
    if (newName != null && this.length > indexOfMatchingMessage) this[indexOfMatchingMessage].senderName = newName;
    if (newThumbnailURL != null && this.length > indexOfMatchingMessage)
      this[indexOfMatchingMessage].senderThumbnailURL = newThumbnailURL;
  }
}

extension ScaledForScreenSize on num {
  /// Use this to automatically adjust widget dimensions based on screen size
  double scaledForScreenSize({required BuildContext context}) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final double iphoneSEScreenWidth = 320;
    return this * screenWidth / iphoneSEScreenWidth;
  }
}

extension DateToHumanReadable on int {
  /// Convert a month's number into a human-readable month
  String toHumanReadableMonth() {
    switch (this) {
      case 1:
        {
          return "Jan";
        }
      case 2:
        {
          return "Feb";
        }
      case 3:
        {
          return "Mar";
        }
      case 4:
        {
          return "Apr";
        }
      case 5:
        {
          return "May";
        }
      case 6:
        {
          return "Jun";
        }
      case 7:
        {
          return "Jul";
        }
      case 8:
        {
          return "Aug";
        }
      case 9:
        {
          return "Sep";
        }
      case 10:
        {
          return "Oct";
        }
      case 11:
        {
          return "Nov";
        }
      case 12:
        {
          return "Dec";
        }
      default:
        {
          return "Error - month out of range";
        }
    }
  }
}

///Very specific extension, but basically, change "friends" to "Looking for friends" in the preferred section of my
///profile.
extension PreferredPronounsConvertForDisplay on String {
  ///Use this to convert "friends" to "looking for friends" and "girlfriend" to "looking for a girlfriend", etc. on
  ///MyProfileTab or ViewPersonDetails.
  String formattedPronounForDisplay() {
    switch (this.trim()) {
      case UsefulValues.lookingForFriends:
        {
          return "Looking for friends";
        }
      case UsefulValues.lookingForGirlfriend:
        {
          return "Looking for a girlfriend";
        }
      case UsefulValues.lookingForBoyfriend:
        {
          return "Looking for a boyfriend";
        }
      case UsefulValues.lookingForAnyGenderDate:
        {
          return "Looking for a date";
        }
      default:
        {
          return this;
        }
    }
  }

}


extension ResizedImage on img.Image {
  ///Return an image that is resized to a specified target size while preserving the aspect ratio
  img.Image resizedWithAspectRatio({required int maxResizedWidth, required int maxResizedHeight}){
    final targetWidth = maxResizedWidth;
    final targetHeight = maxResizedHeight;
    final currentWidth = this.width;
    final currentHeight = this.height;
    final targetToCurrentWidthRatio = targetWidth/currentWidth;
    final targetToCurrentHeightRatio = targetHeight/currentHeight;

    // We want to resize by the smaller of smaller of the two target to current ratios in order to make sure the
    // image does not exceed the maximum allowed width or height.
    final int resizedImageWidth = currentWidth * min(targetToCurrentWidthRatio, targetToCurrentHeightRatio).toInt();
    final int resizedImageHeight = currentHeight * min(targetToCurrentWidthRatio, targetToCurrentHeightRatio).toInt();

    return img.copyResize(this, width: resizedImageWidth, height: resizedImageHeight);
  }
}