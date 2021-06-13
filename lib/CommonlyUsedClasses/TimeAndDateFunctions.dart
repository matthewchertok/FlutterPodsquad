class TimeAndDateFunctions {
  ///Return a user's age given their birthday (as the number of seconds since January 1, 1970).
  ///Birthday values are stored in seconds in the database, so just put that value directly into this function.
  static int getAgeFromBirthday({required double birthday}) {
    birthday = birthday *
        1000; // convert to an integer so that DateTime stuff will work.
    //Also multiply by 1000 to convert seconds to milliseconds (value is stored in the database in seconds)
    int birthdayYear =
        DateTime.fromMillisecondsSinceEpoch(birthday.toInt()).year;
    int birthdayMonth =
        DateTime.fromMillisecondsSinceEpoch(birthday.toInt()).month;
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
}
