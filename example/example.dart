// Portions of this work are Copyright 2018 The Time Machine Authors. All rights reserved.
// Use of this source code is governed by the Apache License 2.0, as found in the LICENSE.txt file.

import 'dart:async';

// todo: consolidate import packages??? this seems a little much...
import 'package:time_machine/time_machine.dart';
import 'package:time_machine/time_machine_for_vm.dart';
import 'package:time_machine/time_machine_globalization.dart';
import 'package:time_machine/time_machine_text.dart';
import 'package:time_machine/time_machine_timezones.dart';

Future main() async {
  // todo: demonstrate a test clock
  // var clockForTesting = new FakeClock();

  try {
    // Sets up timezone and culture information
    await TimeMachine.initialize();
    print('Hello, ${DateTimeZone.local} from the Dart Time Machine!');

    var tzdb = await DateTimeZoneProviders.tzdb;
    var paris = await tzdb["Europe/Paris"];

    var now = SystemClock.instance.getCurrentInstant();

    print('\nBasic');
    print('UTC Time: $now');
    print('Local Time: ${now.inLocalZone()}');
    print('Paris Time: ${now.inZone(paris)}');

    print('\nFormatted');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm')}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm')}');

    print('\nFormatted and French');
    var culture = await Cultures.getCulture('fr-FR');
    print('UTC Time: ${now.toString('dddd yyyy-MM-dd HH:mm', culture)}');
    print('Local Time: ${now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm', culture)}');

    print('\nParse Formatted and Zoned French');
    // without the 'z' parsing will be forced to interpret the timezone as UTC
    var localText = now.inLocalZone().toString('dddd yyyy-MM-dd HH:mm z', culture);

    // todo: show you can create a reusable pattern
    var localClone = ZonedDateTimePattern.createWithCulture('dddd yyyy-MM-dd HH:mm z', culture).parse(localText);
    print(localClone.value);
  }
  catch (error, stack) {
    print(error);
    print(stack);
  }
}