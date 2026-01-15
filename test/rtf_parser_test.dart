import 'package:flutter_test/flutter_test.dart';
import 'package:writr/utils/rtf_parser.dart';

void main() {
  test('rtfToPlainText decodes Windows-1252 hex escapes', () {
    const rtf =
        r"{\rtf1\ansi \'93We\'92re playing \'91outside voices\'92,\'94}";

    expect(rtfToPlainText(rtf), '“We’re playing ‘outside voices’,”');
  });
}
