import 'package:meta/meta.dart';

import 'package:time_machine/src/utility/preconditions.dart';

import 'package:time_machine/time_machine_calendars.dart';
import 'package:time_machine/time_machine.dart';

// https://github.com/nodatime/nodatime/blob/master/src/NodaTime/Calendars/GregorianYearMonthDayCalculator.cs
// fe70212  on Apr 26, 2017

@internal
class GregorianYearMonthDayCalculator extends GJYearMonthDayCalculator {
  @internal static const int minGregorianYear = -9998;
  @internal static const int maxGregorianYear = 9999;

  // We precompute useful values for each month between these years, as we anticipate most
  // dates will be in this range.
  static const int _firstOptimizedYear = 1900;
  static const int _lastOptimizedYear = 2100;
  static const int _firstOptimizedDay = -25567;
  static const int _lastOptimizedDay = 47846;

  // The 0-based days-since-unix-epoch for the start of each month
  static final List<int> _monthStartDays = new List<int>((_lastOptimizedYear + 1 - _firstOptimizedYear) * 12 + 1);

  // The 1-based days-since-unix-epoch for the start of each year
  static final List<int> _yearStartDays = new List<int>(_lastOptimizedYear + 1 - _firstOptimizedYear);

  static const int _daysFrom0000To1970 = 719527;
  static const int _averageDaysPer10Years = 3652; // Ideally 365.2425 per year...

  // this was a static constructor
  static bool _gregorianYearMonthDayCalculator_Initialized = false;
  static void _gregorianYearMonthDayCalculator_Init() {
    if (_gregorianYearMonthDayCalculator_Initialized) return;
    _gregorianYearMonthDayCalculator_Initialized = true;

    // It's generally a really bad idea to create an instance before the static initializer
    // has completed, but we know its safe because we're only using a very restricted set of methods.
    // ^^^ We're using a flag to prevent a recursive tragedy
    var instance = new GregorianYearMonthDayCalculator();
    for (int year = _firstOptimizedYear; year <= _lastOptimizedYear; year++) {
      int yearStart = instance.calculateStartOfYearDays(year);
      _yearStartDays[year - _firstOptimizedYear] = yearStart;

      int monthStartDay = yearStart - 1; // See field description
      int yearMonthIndex = (year - _firstOptimizedYear) * 12;

      for (int month = 1; month <= 12; month++) {
        yearMonthIndex++;
        int monthLength = instance.getDaysInMonth(year, month);
        _monthStartDays[yearMonthIndex] = monthStartDay;
        monthStartDay += monthLength;
      }
    }
  }

  /// Specifically Gregorian-optimized conversion from "days since epoch" to year/month/day.
  static YearMonthDayCalendar getGregorianYearMonthDayCalendarFromDaysSinceEpoch(int daysSinceEpoch) {
    // unchecked
    {
      if (daysSinceEpoch < _firstOptimizedDay || daysSinceEpoch > _lastOptimizedDay) {
        return /*CalendarSystem.Iso.*/GetYearMonthDayCalendarFromDaysSinceEpoch(daysSinceEpoch);
      }

      // Divide by more than we need to, in order to guarantee that we only need to move forward.
      // We can still only be out by 1 year.
      int yearIndex = (daysSinceEpoch - _firstOptimizedDay) ~/ 366;
      int indexValue = _yearStartDays[yearIndex];
      // Zero-based day of year
      int d = daysSinceEpoch - indexValue;
      int year = yearIndex + _firstOptimizedYear;
      bool isLeap = _isGregorianLeapYear(year);
      int daysInYear = isLeap ? 366 : 365;
      if (d >= daysInYear) {
        year++;
        d -= daysInYear;
        isLeap = _isGregorianLeapYear(year);
      }

      // The remaining code is copied from GJYearMonthDayCalculator (and tweaked)

      int startOfMonth;
      // Perform a hard-coded binary search to get the month.
      if (isLeap) {
        startOfMonth = ((d < 182)
            ? ((d < 91) ? ((d < 31) ? -1 : (d < 60) ? 30 : 59) : ((d < 121) ? 90 : (d < 152) ? 120 : 151))
            : ((d < 274)
            ? ((d < 213) ? 181 : (d < 244) ? 212 : 243)
            : ((d < 305) ? 273 : (d < 335) ? 304 : 334)));
      }
      else {
        startOfMonth = ((d < 181)
            ? ((d < 90) ? ((d < 31) ? -1 : (d < 59) ? 30 : 58) : ((d < 120) ? 89 : (d < 151) ? 119 : 150))
            : ((d < 273)
            ? ((d < 212) ? 180 : (d < 243) ? 211 : 242)
            : ((d < 304) ? 272 : (d < 334) ? 303 : 333)));
      }
      int month = startOfMonth ~/ 29 + 1;
      int dayOfMonth = d - startOfMonth;
      return new YearMonthDayCalendar(year, month, dayOfMonth, CalendarOrdinal.Iso);
    }
  }

  @internal
  GregorianYearMonthDayCalculator() : super(minGregorianYear, maxGregorianYear, _averageDaysPer10Years, -719162) {
    _gregorianYearMonthDayCalculator_Init();
  }

  @internal @override
  int getStartOfYearInDays(int year) {
// 2014-06-28: Tried removing this entirely (optimized: 5ns => 8ns; unoptimized: 11ns => 8ns)
// Decided to leave it in, as the optimized case is so much more common.
    if (year < _firstOptimizedYear || year > _lastOptimizedYear) {
      return super.getStartOfYearInDays(year);
    }
    return _yearStartDays[year - _firstOptimizedYear];
  }

  @internal @override
  int getDaysSinceEpoch(YearMonthDay yearMonthDay) {
    // 2014-06-28: Tried removing this entirely (optimized: 8ns => 13ns; unoptimized: 23ns => 19ns)
    // Also tried computing everything lazily - it's a wash.
    // Removed validation, however - we assume that the parameter is already valid by now.
    int year = yearMonthDay.year;
    int monthOfYear = yearMonthDay.month;
    int dayOfMonth = yearMonthDay.day;
    int yearMonthIndex = (year - _firstOptimizedYear) * 12 + monthOfYear;
    if (year < _firstOptimizedYear || year > _lastOptimizedYear - 1) {
      return super.getDaysSinceEpoch(yearMonthDay);
    }
    return _monthStartDays[yearMonthIndex] + dayOfMonth;
  }

  @internal @override
  void validateYearMonthDay(int year, int month, int day) => validateGregorianYearMonthDay(year, month, day);

  @internal
  static void validateGregorianYearMonthDay(int year, int month, int day) {
    // Perform quick validation without calling Preconditions, then do it properly if we're going to throw
    // an exception. Avoiding the method call is pretty extreme, but it does help.
    if (year < minGregorianYear || year > maxGregorianYear || month < 1 || month > 12) {
      Preconditions.checkArgumentRange('year', year, minGregorianYear, maxGregorianYear);
      Preconditions.checkArgumentRange('month', month, 1, 12);
    }

    // If we've been asked for day 1-28, we're definitely okay regardless of month.
    if (day >= 1 && day <= 28) {
      return;
    }
    int daysInMonth = month == 2 && _isGregorianLeapYear(year) ? GJYearMonthDayCalculator.maxDaysPerMonth[month - 1] : GJYearMonthDayCalculator.minDaysPerMonth[month - 1];
    if (day < 1 || day > daysInMonth) {
      Preconditions.checkArgumentRange('day', day, 1, daysInMonth);
    }
  }

  @override @protected
  int calculateStartOfYearDays(int year) {
    // Initial value is just temporary.
    int leapYears = year ~/ 100;
    if (year < 0) {
      // Add 3 before shifting right since /4 and >>2 behave differently
      // on negative numbers. When the expression is written as
      // (year / 4) - (year / 100) + (year / 400),
      // it works for both positive and negative values, except this optimization
      // eliminates two divisions.
      leapYears = ((year + 3) >> 2) - leapYears + ((leapYears + 3) >> 2) - 1;
    }
    else {
      leapYears = (year >> 2) - leapYears + (leapYears >> 2);
      if (IsLeapYear(year)) {
        leapYears--;
      }
    }

    return year * 365 + (leapYears - _daysFrom0000To1970);
  }

  // Override GetDaysInYear so we can avoid a pointless virtual method call.
  @internal @override
  int getDaysInYear(int year) => _isGregorianLeapYear(year) ? 366 : 365;

  @internal @override
  bool IsLeapYear(int year) => _isGregorianLeapYear(year);

  static bool _isGregorianLeapYear(int year) => ((year & 3) == 0) && ((year % 100) != 0 || (year % 400) == 0);
}