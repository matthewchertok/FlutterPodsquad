import 'package:podsquad/CommonlyUsedClasses/Extensions.dart';

class TimeAndDateFunctions {
  ///Return a user's age given their birthday (as the number of seconds since January 1, 1970).
  ///Birthday values are stored in seconds in the database, so just put that value directly into this function.
  static int getAgeFromBirthday({required double birthday}) {
    birthday = birthday * 1000; // convert to an integer so that DateTime stuff will work.
    //Also multiply by 1000 to convert seconds to milliseconds (value is stored in the database in seconds)
    int birthdayYear = DateTime.fromMillisecondsSinceEpoch(birthday.toInt()).year;
    int birthdayMonth = DateTime.fromMillisecondsSinceEpoch(birthday.toInt()).month;
    int birthdayDay = DateTime.fromMillisecondsSinceEpoch(birthday.toInt()).day;

    //Now let's get the current day, month, and year
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int currentDay = DateTime.now().day;

    int personAge = currentYear -
        birthdayYear; // temporarily assume that the person's age is simply the difference in years since they were born

    // subtract 1 from the above value if the current month hasn't reached their birth month yet
    if (currentMonth < birthdayMonth)
      return personAge - 1;

    // if it is currently the same month as their birthday but it hasn't gotten to their birthday yet, subtract 1 from their age
    else if (currentMonth == birthdayMonth && currentDay < birthdayDay)
      return personAge - 1;

    // if it is past their birthday, then our original value for their age is accurate.
    else
      return personAge;
  }

  /// Make text from the time stamp. Time stamp should come directly from the database and be in SECONDS since the
  /// epoch.
  static String timeStampText(double timeStamp, {bool capitalized = true, bool includeFillerWords = false}) {
    final dateOfEvent = DateTime.fromMillisecondsSinceEpoch((1000*timeStamp).toInt());
    final now = DateTime.now();

    // to determine whether something happened today, yesterday, or before, we need to simplify things by only
    // considering midnight on the day the event occurred.
    final midnightOnReadDay = DateTime(dateOfEvent.year, dateOfEvent.month, dateOfEvent.day);
    final midnightToday = DateTime(now.year, now.month, now.day);

    // Convert 24-hour time to 12-hour time. Hours are 0 to 23, so anything 12 or greater is PM. Also, be
    // careful: we say 12:00 pm, not 0:00 pm. Also, we say 12:00 am, not 0:00 am. Also, if the minute is less than
    // 10, we need to add a 0 before it so it says 12:01 instead of 12:1.
    final hoursMinutes = dateOfEvent.hour >= 12
        ? "${dateOfEvent.hour - 12 == 0 ? 12 : dateOfEvent.hour - 12}:${dateOfEvent.minute < 10 ? "0${dateOfEvent.minute}" : dateOfEvent.minute}"
        " PM"
        : "${dateOfEvent.hour == 0 ? 12 : dateOfEvent.hour}:${dateOfEvent.minute < 10 ? "0${dateOfEvent
        .minute}" : dateOfEvent.minute} AM";

    // if the message was read today
    if (midnightToday.difference(midnightOnReadDay).inDays < 1) {
      return "${capitalized ? "T" : "t"}oday ${includeFillerWords ? "at" : ""} $hoursMinutes";
    }

    // if the message was read yesterday
    else if (midnightToday.difference(midnightOnReadDay).inDays < 2) {
      return "${capitalized ? "Y" : "y"} yesterday ${includeFillerWords ? "at" : ""} $hoursMinutes";
    }

    // if the message was read earlier this year
    else if (now.year == dateOfEvent.year) {
      return "${dateOfEvent.month.toHumanReadableMonth()} ${dateOfEvent.day} ${includeFillerWords ? "at" : ""} "
          "$hoursMinutes";
    }

    // if the message was read more than 2 days ago and not this year
    else {
      return "${dateOfEvent.month.toHumanReadableMonth()} ${dateOfEvent.day} ${dateOfEvent.year}";
    }
  }

  /// Make the "read today at 4:20 pm" or "Read yesterday at 11:59 am" message
  static String readByMessage({required DateTime readAt, bool capitalized = true}){
    final now = DateTime.now();

    // to determine whether something happened today, yesterday, or before, we need to simplify things by only
    // considering midnight on the day the event occurred.
    final midnightOnReadDay = DateTime(readAt.year, readAt.month, readAt.day);
    final midnightToday = DateTime(now.year, now.month, now.day);

    // Convert 24-hour time to 12-hour time. Hours are 0 to 23, so anything 12 or greater is PM. Also, be
    // careful: we say 12:00 pm, not 0:00 pm. Also, we say 12:00 am, not 0:00 am. Also, if the minute is less than
    // 10, we need to add a 0 before it so it says 12:01 instead of 12:1.
    final hoursMinutes = readAt.hour >= 12
        ? "${readAt.hour - 12 == 0 ? 12 : readAt.hour - 12}:${readAt.minute < 10 ? "0${readAt.minute}" : readAt.minute}"
        " PM"
        : "${readAt.hour == 0 ? 12 : readAt.hour}:${readAt.minute < 10 ? "0${readAt
        .minute}" : readAt.minute} AM";

    // if the message was read today
    if (midnightToday.difference(midnightOnReadDay).inDays < 1) {
      return "${capitalized ? "R" : "r"}ead today at $hoursMinutes";
    }

    // if the message was read yesterday
    else if (midnightToday.difference(midnightOnReadDay).inDays < 2) {
      return "${capitalized ? "R" : "r"}ead yesterday at $hoursMinutes";
    }

    // if the message was read earlier this year
    else if (now.year == readAt.year) {
      return "${capitalized ? "R" : "r"}ead ${readAt.month.toHumanReadableMonth()} ${readAt.day} at $hoursMinutes";
    }

    // if the message was read more than 2 days ago and not this year
    else {
      return "${capitalized ? "R" : "r"}ead ${readAt.month.toHumanReadableMonth()} ${readAt.day} ${readAt.year}";
    }
  }
}
