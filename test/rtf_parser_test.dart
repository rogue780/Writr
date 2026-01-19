import 'package:flutter_test/flutter_test.dart';
import 'package:writr/utils/rtf_parser.dart';

void main() {
  test('rtfToPlainText decodes Windows-1252 hex escapes', () {
    const rtf =
        r"{\rtf1\ansi \'93We\'92re playing \'91outside voices\'92,\'94}";

    expect(
      rtfToPlainText(rtf),
      '\u201cWe\u2019re playing \u2018outside voices\u2019,\u201d',
    );
  });

  test('rtfToPlainText ignores font tables and other metadata groups', () {
    const rtf =
        r"{\rtf1\ansi{ \fonttbl{\f0 TimesNewRomanPSMT;}{\f1 ArialMT;}}Hello}";

    expect(rtfToPlainText(rtf), 'Hello');
  });

  test('rtfToPlainText ignores ignorable destination groups', () {
    const rtf = r"{\rtf1\ansi{ \*\generator Riched20 10.0.22621}Hello}";

    expect(rtfToPlainText(rtf), 'Hello');
  });

  test('rtfToPlainText does not leak numeric control word params', () {
    const rtf = r"{\rtf1\ansi\fi-500\li-500 Hello}";

    expect(rtfToPlainText(rtf), 'Hello');
  });
}
