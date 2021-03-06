// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Portions of this work are Copyright 2018 The Noda Time Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

import 'package:time_machine/src/time_machine_internal.dart';

import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:time_machine/src/timezones/time_machine_timezones.dart';

import '../time_machine_testing.dart';

DateTimeZoneProvider Tzdb;

/// Fixture for miscellaneous bug reports and oddities which don't really fit anywhere else.
/// Quite often the cause of a problem is nowhere near the test code; it's still useful
/// to have the original test which showed up the problem, as a small contribution
/// to regression testing.
Future main() async {
  await TimeMachine.initialize();
  await setup();

  await runTests();
}

Future setup() async {
  Tzdb = await DateTimeZoneProviders.tzdb;
}


@Test()
Future Niue() async
{
  DateTimeZone niue = await Tzdb["Pacific/Niue"];
  var offset = niue.getUtcOffset(new ZonedDateTime.atStrictly(new LocalDateTime(2010, 1, 1, 0, 0, 0), niue).toInstant());
  expect(new Offset.hours(-11), offset);
}

@Test()
Future Kiritimati() async
{
  DateTimeZone kiritimati = await Tzdb["Pacific/Kiritimati"];
  var offset = kiritimati.getUtcOffset(new ZonedDateTime.atStrictly(new LocalDateTime(2010, 1, 1, 0, 0, 0), kiritimati).toInstant());
  expect(new Offset.hours(14), offset);
}

@Test()
Future Pyongyang() async
{
  DateTimeZone pyongyang = await Tzdb["Asia/Pyongyang"];
  var offset = pyongyang.getUtcOffset(new ZonedDateTime.atStrictly(new LocalDateTime(2010, 1, 1, 0, 0, 0), pyongyang).toInstant());
  expect(new Offset.hours(9), offset);
}

@Test()
Future Khartoum() async
{
  DateTimeZone khartoum = await Tzdb["Africa/Khartoum"];
  expect(khartoum, isNotNull);
  Instant utc = new Instant.utc(2000, 1, 1, 0, 0, 0);
  ZonedDateTime inKhartoum = new ZonedDateTime(utc, khartoum);
  LocalDateTime expectedLocal = new LocalDateTime(2000, 1, 1, 2, 0, 0);
  expect(expectedLocal, inKhartoum.localDateTime);

  // Khartoum changed from +2 to +3 on January 15th 2000
  utc = new Instant.utc(2000, 1, 16, 0, 0, 0);
  inKhartoum = new ZonedDateTime(utc, khartoum);
  expectedLocal = new LocalDateTime(2000, 1, 16, 3, 0, 0);
  expect(expectedLocal, inKhartoum.localDateTime);
}

/// Tbilisi used daylight saving time for winter 1996/1997 too.
@Test()
Future Tbilisi() async
{
  var zone = await Tzdb["Asia/Tbilisi"];
  Instant summer1996 = new Instant.utc(1996, 6, 1, 0, 0);
  var interval = zone.getZoneInterval(summer1996);
  expect(new LocalDateTime(1996, 3, 31, 1, 0, 0), interval.isoLocalStart);
  expect(new LocalDateTime(1997, 10, 26, 0, 0, 0), interval.isoLocalEnd);
}

