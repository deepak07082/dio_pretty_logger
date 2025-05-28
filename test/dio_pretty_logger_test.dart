import 'package:flutter_test/flutter_test.dart';

import 'package:dio_pretty_logger/dio_pretty_logger.dart';

void main() {
  test('print map', () {
    DioPrettyLogger.printPrettyMap({
      for (var i = 0; i < 10; i++) 'key$i': 'value$i',
    });
  });
}
