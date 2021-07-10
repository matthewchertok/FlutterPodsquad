import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final messageTimeStamp = DateTime.fromMillisecondsSinceEpoch((timeStamp * 1000).toInt()); // must multiply by 1000
    // since
    // database
    // stores time stamp in seconds since epoch
    final currentYear = DateTime.now().year;

    // Convert 24-hour time to 12-hour time. Hours are 0 to 23, so anything 12 or greater is PM. Also, be
    // careful: we say 12:00 pm, not 0:00 pm. Also, we say 12:00 am, not 0:00 am. Also, if the minute is less than
    // 10, we need to add a 0 before it so it says 12:01 instead of 12:1.
    final hoursMinutes = messageTimeStamp.hour >= 12
        ? "${messageTimeStamp.hour - 12 == 0 ? 12 : messageTimeStamp.hour - 12}:${messageTimeStamp.minute < 10 ? "0${messageTimeStamp.minute}" : messageTimeStamp.minute} PM"
        : "${messageTimeStamp.hour == 0 ? 12 : messageTimeStamp.hour}:${messageTimeStamp.minute < 10 ? "0${messageTimeStamp.minute}" : messageTimeStamp.minute}"
            "AM";

    // If the year is the same, show month, day, and time. Otherwise, show month, day, and year.
    final timeStampText = messageTimeStamp.year == currentYear
        ? "${messageTimeStamp.month.toHumanReadableMonth()} "
            "${messageTimeStamp.day} "
            "$hoursMinutes"
        : "${messageTimeStamp.month.toHumanReadableMonth()} ${messageTimeStamp.day} ${messageTimeStamp.year}";
    return Text(timeStampText, style: TextStyle(fontSize: fontSize),);
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
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    content,
                    style: TextStyle(fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ),

          // The time stamp
          Container(
            width: 40,
            child: timeStampText(),
          )
        ],
      ),
    );
  }
}
