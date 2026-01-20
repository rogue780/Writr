import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:writr/utils/super_editor_markdown.dart';

void main() {
  group('SuperEditor markdown conversion', () {
    test('parses bold/italic/strike/underline', () {
      final text = parseMarkdownInline(
        'The **quick** *brown* ~~fox~~ <u>jumps</u>.',
      );

      expect(text.toPlainText(), 'The quick brown fox jumps.');

      // quick (bold)
      for (var i = 4; i <= 8; i++) {
        expect(text.getAllAttributionsAt(i).contains(boldAttribution), isTrue);
      }

      // brown (italic)
      for (var i = 10; i <= 14; i++) {
        expect(
          text.getAllAttributionsAt(i).contains(italicsAttribution),
          isTrue,
        );
      }

      // fox (strike)
      for (var i = 16; i <= 18; i++) {
        expect(
          text.getAllAttributionsAt(i).contains(strikethroughAttribution),
          isTrue,
        );
      }

      // jumps (underline)
      for (var i = 20; i <= 24; i++) {
        expect(
          text.getAllAttributionsAt(i).contains(underlineAttribution),
          isTrue,
        );
      }
    });

    test('serializes inline attributions to markdown', () {
      final spans = AttributedSpans()
        ..addAttribution(newAttribution: boldAttribution, start: 4, end: 8)
        ..addAttribution(newAttribution: italicsAttribution, start: 10, end: 14)
        ..addAttribution(
          newAttribution: strikethroughAttribution,
          start: 16,
          end: 18,
        )
        ..addAttribution(
            newAttribution: underlineAttribution, start: 20, end: 24);

      final text = AttributedText('The quick brown fox jumps.', spans);
      expect(
        serializeAttributedTextToMarkdown(text),
        'The **quick** *brown* ~~fox~~ <u>jumps</u>.',
      );
    });

    test('escapes literal marker characters', () {
      final text = parseMarkdownInline(r'Use \* and \~ and \\ literally.');
      expect(text.toPlainText(), r'Use * and ~ and \ literally.');

      final roundTrip = serializeAttributedTextToMarkdown(text);
      expect(roundTrip, r'Use \* and \~ and \\ literally.');
    });

    test('round-trips full documents', () {
      const markdown = 'Line 1\nThe **quick** *brown* ~~fox~~ <u>jumps</u>.';
      final doc = createDocumentFromMarkdown(markdown);
      expect(markdownFromDocument(doc), markdown);
    });
  });
}
