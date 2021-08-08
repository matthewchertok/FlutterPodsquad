import 'package:flutter/cupertino.dart';
import 'package:podsquad/BackendFunctions/TimeAndDateFunctions.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:podsquad/OtherSpecialViews/DecoratedImage.dart';

class PersonOrPodListRow extends StatelessWidget {
  const PersonOrPodListRow(
      {Key? key,
      required this.personOrPodID,
      required this.personOrPodName,
      required this.personOrPodThumbnailURL, this.personBirthday = -1,
      required this.personOrPodBio,
      this.timeIMetThePerson})
      : super(key: key);
  final String personOrPodID;
  final String personOrPodName;
  final String personOrPodThumbnailURL;
  final double personBirthday;
  final String personOrPodBio;
  final double? timeIMetThePerson;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The chat partner or pod profile image
          DecoratedImage(imageURL: this.personOrPodThumbnailURL, width: 80, height: 80),

          // The name, age (if a person), and bio (if not empty)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    this.personOrPodName,
                    style: TextStyle(fontSize: 18, color: isDarkMode ?
                    CupertinoColors.white : CupertinoColors.black),
                  ),
                  SizedBox(height: 10),
                  if (this.personBirthday > 0)
                    Text(TimeAndDateFunctions.getAgeFromBirthday(birthday: this.personBirthday).toString(), style:
                    TextStyle(fontSize: 16, color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),),
                  SizedBox(height: 10,),
                  if (this.personOrPodBio.isNotEmpty)
                    ClipRRect(child: Container(
                      padding: EdgeInsets.all(4),
                      color: accentColor.withOpacity(0.9),
                      child: Text(
                        this.personOrPodBio,
                        style: TextStyle(fontSize: 14, color: CupertinoColors.white),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ), borderRadius: BorderRadius.circular(5),)
                ],
              ),
            ),
          ),

          // The time stamp
          if (timeIMetThePerson != null)
            Container(
              width: 50,
              child: Text(TimeAndDateFunctions.timeStampText(timeIMetThePerson!), style: TextStyle(fontSize: 10, color: isDarkMode ?
              CupertinoColors.white : CupertinoColors.black),),
            )
        ],
      ),
    );
  }
}
