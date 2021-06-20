import 'package:podsquad/BackendDataclasses/PodMessageDataclasses.dart';
import 'package:podsquad/BackendDataclasses/ProfileData.dart';

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
  void changeSenderNameAndOrThumbnailURL({required String forMessageWithID, String? toNewName, String?
  toNewThumbnailURL}) {
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
