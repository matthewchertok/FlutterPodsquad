extension Rounding on double {
  ///Round a double to a specified number of digits after the decimal point. Pass in 1 to round to the nearest tenth,
  /// 2 to round to the nearest hundredth, 3 to round to the nearest thousandth, etc.
  double roundToDecimalPlace(int digitsAfterDecimal) => double.parse(this.toStringAsFixed
    (digitsAfterDecimal));
}

extension StringComparison on String {
  ///Determine if a string comes before another string in the alphabet. Capital letters come before lowercase letters
  /// (i.e. Z comes before a).
  bool operator < (Object otherString) => otherString is String && this.compareTo(otherString) == -1 ? true : false;
  bool operator > (Object otherString) => otherString is String && this.compareTo(otherString) == 1 ? true : false;

  //Comparison returns 1 if the first string (this) is greater than the second (otherString). So as long as we don't
  //get 1, then the first string must be less than or equal to the second.
  bool operator <= (Object otherString) => otherString is String && this.compareTo(otherString) == 1 ? false : true;
  bool operator >= (Object otherString) => otherString is String && this.compareTo(otherString) == -1 ? false : true;

}