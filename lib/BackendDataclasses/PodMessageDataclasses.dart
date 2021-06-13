import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';

class PodMessage {
  String id;
  String content;
  String senderID;
  String senderName;
  double timeStamp;
  String? imageURL;
  String? audioURL;
  String? imagePath;
  String? audioPath;
  List<String>? readBy;

  PodMessage(
      {required this.id,
      required this.content,
      required this.senderID,
      required this.senderName,
      required this.timeStamp,
      this.imageURL,
      this.audioURL,
      this.imagePath,
      this.audioPath,
      this.readBy});

  // Declare that two PodMessage objects are the same if and only if they have the same ID.
  @override
  bool operator ==(Object otherInstance) =>
      otherInstance is PodMessage && id == otherInstance.id;

  @override
  int get hashCode => id.hashCode;
}

//No need for a DownloadedPodMessage class, because I can simply use the CachedNetworkImage widget to download, render, and cache
// an image given its URL. Sure, it might be slightly wasteful that images download every time a view is rendered, but
// at 3kb per thumbnail, it would take over 333 thumbnails to use a single megabyte of data. So the additional cost is
// negligible compared to the simplicity gains involved with not having to pass Image objects around
// since I can simply render them in place using the CachedNetworkImage widget.
