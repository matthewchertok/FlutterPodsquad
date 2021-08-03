import 'dart:io';

import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/DatabasePaths/MessagingDatabasePaths.dart';
import 'package:uuid/uuid.dart';

/// Upload audio to Storage and return the path and URL so that it can be included with the message in Firestore
class UploadAudio {
  static final shared = UploadAudio();

  /// Upload a recording to Storage to send with a message. Returns a list like this: [downloadURL, path], so
  /// that the correct data can be uploaded to Firestore.
  Future<List<String>?> uploadRecordingToDatabase(
      {required File recordingFile, required String chatPartnerOrPodID, required bool isPodMessage}) async {
    var filePath = recordingFile.path;
    if (Platform.isIOS) filePath = filePath.substring(8, filePath.length);
    final recordingFileAdjusted = File(filePath);

    // create a random identifier for the audio recording
    final uniqueIdentifier = Uuid().v1();

    final audioRecPath = isPodMessage
        ? MessagingDatabasePaths(userID: chatPartnerOrPodID).podMessageAudioRecordingPath.child(uniqueIdentifier)
        : MessagingDatabasePaths(userID: myFirebaseUserId, interactingWithUserWithID: chatPartnerOrPodID)
            .messageAudioRecordingPath
            .child(uniqueIdentifier);

    // upload to Storage
    final audioUploadTask = await audioRecPath.putFile(recordingFileAdjusted);
    final pathToAudio = audioUploadTask.ref.fullPath;
    final audioDownloadURL = await audioUploadTask.ref.getDownloadURL();

    return [audioDownloadURL, pathToAudio];
  }
}
