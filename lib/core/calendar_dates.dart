class CalendarDates {
  static DateTime day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Inclusive calendar dates, represented as a half-open interval. Calendar
  /// arithmetic keeps midnight boundaries correct through DST transitions.
  static bool contains(int timestamp, DateTime from, DateTime through) {
    final value = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return !value.isBefore(day(from)) && value.isBefore(addDays(through, 1));
  }
}
