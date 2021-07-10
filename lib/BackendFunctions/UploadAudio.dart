import 'dart:io';

/// Upload audio to Storage and return the path and URL so that it can be included with the message in Firestore
class UploadAudio {
  static final shared = UploadAudio();

  /// Upload a recording to Storage to send with a message. Returns a list like this: {downloadURL, path}, so
  /// that the correct data can be uploaded to Firestore.
  Future<List<String>?> uploadRecordingToDatabase(
      {required File recordingFile, required String chatPartnerOrPodID, required bool isPodMessage}) async {

  }
}
