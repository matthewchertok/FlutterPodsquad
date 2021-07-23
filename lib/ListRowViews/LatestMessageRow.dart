import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

/// Displays a preview of the latest message in a conversation in the Messaging tab.
class LatestMessageRow extends StatelessWidget {
  LatestMessageRow(
      {required this.chatPartnerOrPodName,
      required this.chatPartnerOrPodThumbnailURL,
      required this.content,
      required this.timeStamp,
      this.readBy});

  final String chatPartnerOrPodName;
  final String chatPartnerOrPodThumbnailURL;
  final String content;
  final double timeStamp;
  final List<String>? readBy;

  /// Make text from the time stamp
  Text timeStampText({double fontSize = 10}) {
    // If the year is the same, show month, day, and time. Otherwise, show month, day, and year.
    final timeStampText = TimeAndDateFunctions.timeStampText(timeStamp);

    // make the text bold if I haven't read the  message. Otherwise, make it normal.
    return Text(timeStampText, style: TextStyle(fontSize: fontSize, fontWeight: (this.readBy?.contains
      (myFirebaseUserId) ?? true) ? FontWeight.normal : FontWeight.bold),);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The chat partner or pod profile image
          Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: CupertinoColors.white, width: 3),
                  boxShadow: [BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 3)]),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: chatPartnerOrPodThumbnailURL,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(CupertinoIcons.exclamationmark_triangle_fill),
                    progressIndicatorBuilder: (context, url, progress) => CupertinoActivityIndicator(),
                  ))),

          // The name and message preview
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatPartnerOrPodName,
                    style: TextStyle(fontSize: 18, fontWeight: (this.readBy?.contains
                      (myFirebaseUserId) ?? true) ? FontWeight.normal : FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    content,
                    style: TextStyle(fontSize: 14, fontWeight: (this.readBy?.contains
                      (myFirebaseUserId) ?? true) ? FontWeight.normal : FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),

          // The time stamp
          Container(
            width: 50,
            child: timeStampText(),
          )
        ],
      ),
    );
  }
}
