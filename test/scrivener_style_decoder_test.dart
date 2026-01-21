import 'package:flutter_test/flutter_test.dart';
import 'package:writr/utils/scrivener_style_decoder.dart';

void main() {
  group('ScrivenerStyleDecoder', () {
    group('parseTags', () {
      test('parses paragraph style start tag', () {
        final tags = ScrivenerStyleDecoder.parseTags('<\$Scr_Ps::0>Hello');

        expect(tags.length, 1);
        expect(tags[0].type, ScrivenerTagType.paragraphStyle);
        expect(tags[0].styleIndex, 0);
        expect(tags[0].isEnd, false);
        expect(tags[0].rawTag, '<\$Scr_Ps::0>');
      });

      test('parses paragraph style end tag', () {
        final tags = ScrivenerStyleDecoder.parseTags('<!\$Scr_Ps::3>');

        expect(tags.length, 1);
        expect(tags[0].type, ScrivenerTagType.paragraphStyle);
        expect(tags[0].styleIndex, 3);
        expect(tags[0].isEnd, true);
      });

      test('parses character style tags', () {
        final tags = ScrivenerStyleDecoder.parseTags(
            '<\$Scr_Cs::2>bold text<!\$Scr_Cs::2>');

        expect(tags.length, 2);
        expect(tags[0].type, ScrivenerTagType.characterStyle);
        expect(tags[0].styleIndex, 2);
        expect(tags[0].isEnd, false);

        expect(tags[1].type, ScrivenerTagType.characterStyle);
        expect(tags[1].styleIndex, 2);
        expect(tags[1].isEnd, true);
      });

      test('parses mixed tags', () {
        final text =
            '<\$Scr_Ps::0>NOVEL FORMAT<!\$Scr_Ps::0><\$Scr_Ps::1>About This Template<!\$Scr_Ps::1>';
        final tags = ScrivenerStyleDecoder.parseTags(text);

        expect(tags.length, 4);
        expect(tags[0].styleIndex, 0);
        expect(tags[1].styleIndex, 0);
        expect(tags[2].styleIndex, 1);
        expect(tags[3].styleIndex, 1);
      });
    });

    group('decode', () {
      test('removes tags and returns clean text', () {
        final result =
            ScrivenerStyleDecoder.decode('<\$Scr_Ps::0>Hello World<!\$Scr_Ps::0>');

        expect(result.cleanText, 'Hello World');
        expect(result.hasTags, true);
        expect(result.tags.length, 2);
      });

      test('preserves text without tags', () {
        final result = ScrivenerStyleDecoder.decode('Plain text without tags');

        expect(result.cleanText, 'Plain text without tags');
        expect(result.hasTags, false);
      });

      test('handles multiple tags correctly', () {
        final result = ScrivenerStyleDecoder.decode(
            '<\$Scr_Ps::0>Title<!\$Scr_Ps::0> Some <\$Scr_Cs::2>bold<!\$Scr_Cs::2> text');

        expect(result.cleanText, 'Title Some bold text');
        expect(result.tags.length, 4);
      });

      test('records tag positions in clean text', () {
        final result =
            ScrivenerStyleDecoder.decode('<\$Scr_Cs::2>bold<!\$Scr_Cs::2>');

        expect(result.cleanText, 'bold');
        // Start tag at position 0 in clean text
        expect(result.tagPositions[0], isNotNull);
        expect(result.tagPositions[0]!.first.isEnd, false);
        // End tag at position 4 in clean text (after "bold")
        expect(result.tagPositions[4], isNotNull);
        expect(result.tagPositions[4]!.first.isEnd, true);
      });
    });

    group('encode (round-trip)', () {
      test('reconstructs original text with tags', () {
        const original = '<\$Scr_Ps::0>Hello World<!\$Scr_Ps::0>';
        final decoded = ScrivenerStyleDecoder.decode(original);
        final encoded = ScrivenerStyleDecoder.encode(decoded);

        expect(encoded, original);
      });

      test('handles complex nested tags', () {
        const original =
            '<\$Scr_Ps::0>Title<!\$Scr_Ps::0>\n<\$Scr_Ps::3>Body with <\$Scr_Cs::2>bold<!\$Scr_Cs::2> text<!\$Scr_Ps::3>';
        final decoded = ScrivenerStyleDecoder.decode(original);
        final encoded = ScrivenerStyleDecoder.encode(decoded);

        expect(encoded, original);
      });
    });

    group('style mappings', () {
      test('paragraph style 0 is Title (bold, heading)', () {
        final style = ScrivenerStyleMappings.getParagraphStyle(0);

        expect(style, isNotNull);
        expect(style!.name, 'Title');
        expect(style.isBold, true);
        expect(style.isHeading, true);
      });

      test('character style 2 is Strong (bold)', () {
        final style = ScrivenerStyleMappings.getCharacterStyle(2);

        expect(style, isNotNull);
        expect(style!.name, 'Strong');
        expect(style.isBold, true);
      });

      test('character style 1 is Emphasis (italic)', () {
        final style = ScrivenerStyleMappings.getCharacterStyle(1);

        expect(style, isNotNull);
        expect(style!.name, 'Emphasis');
        expect(style.isItalic, true);
      });
    });

    group('String extension', () {
      test('hasScrivenerTags returns true for text with tags', () {
        expect('<\$Scr_Ps::0>test'.hasScrivenerTags, true);
        expect('<\$Scr_Cs::2>test'.hasScrivenerTags, true);
      });

      test('hasScrivenerTags returns false for plain text', () {
        expect('plain text'.hasScrivenerTags, false);
        expect('<not a tag>'.hasScrivenerTags, false);
      });

      test('decodeScrivenerTags extension works', () {
        final decoded = '<\$Scr_Cs::2>bold<!\$Scr_Cs::2>'.decodeScrivenerTags();

        expect(decoded.cleanText, 'bold');
        expect(decoded.hasTags, true);
      });
    });
  });
}
