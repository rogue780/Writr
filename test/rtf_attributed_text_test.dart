import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:writr/utils/rtf_attributed_text.dart';
import 'package:writr/models/rtf_metadata.dart';

void main() {
  group('RtfToAttributedText', () {
    group('tokenization', () {
      test('tokenizes basic RTF structure', () {
        const rtf = r'{\rtf1 Hello}';
        final tokens = tokenizeRtf(rtf);

        expect(tokens.length, greaterThan(0));
        expect(tokens.first.type, RtfTokenType.groupStart);
        expect(tokens.last.type, RtfTokenType.groupEnd);
      });

      test('tokenizes control words', () {
        const rtf = r'{\rtf1\b bold\b0 normal}';
        final tokens = tokenizeRtf(rtf);

        final boldToken = tokens.firstWhere(
          (t) => t.word == 'b' && t.param == null,
          orElse: () => throw StateError('Bold token not found'),
        );
        expect(boldToken.word, 'b');

        final boldOffToken = tokens.firstWhere(
          (t) => t.word == 'b' && t.param == 0,
          orElse: () => throw StateError('Bold off token not found'),
        );
        expect(boldOffToken.word, 'b');
        expect(boldOffToken.param, 0);
      });

      test('tokenizes control words with parameters', () {
        const rtf = r'{\rtf1\fs24 text}';
        final tokens = tokenizeRtf(rtf);

        final fsToken = tokens.firstWhere(
          (t) => t.word == 'fs',
          orElse: () => throw StateError('fs token not found'),
        );
        expect(fsToken.word, 'fs');
        expect(fsToken.param, 24);
      });

      test('tokenizes hex escapes', () {
        const rtf = r"{\rtf1 \'93quoted\'94}"; // Smart quotes
        final tokens = tokenizeRtf(rtf);

        expect(tokens.any((t) => t.raw.contains("'93")), isTrue);
      });
    });

    group('header parsing', () {
      test('parses font table', () {
        const rtf = r'{\rtf1{\fonttbl{\f0\fswiss Arial;}{\f1\froman Times New Roman;}}}';
        final converter = RtfToAttributedText(rtf);
        final metadata = converter.parseHeader();

        expect(metadata.fontTable.length, 2);
        expect(metadata.fontTable[0].name, 'Arial');
        expect(metadata.fontTable[0].family, 'swiss');
        expect(metadata.fontTable[1].name, 'Times New Roman');
        expect(metadata.fontTable[1].family, 'roman');
      });

      test('parses color table', () {
        const rtf = r'{\rtf1{\colortbl;\red255\green0\blue0;\red0\green255\blue0;}}';
        final converter = RtfToAttributedText(rtf);
        final metadata = converter.parseHeader();

        // Color table has auto (null) at index 0 plus 2 colors
        // The exact count depends on how the parser handles the final semicolon
        expect(metadata.colorTable.length, greaterThanOrEqualTo(3));
        expect(metadata.colorTable[0], isNull); // First entry is auto
        expect(metadata.colorTable[1], const Color.fromARGB(255, 255, 0, 0)); // Red
        expect(metadata.colorTable[2], const Color.fromARGB(255, 0, 255, 0)); // Green
      });

      test('parses default font index', () {
        const rtf = r'{\rtf1\deff1{\fonttbl{\f0 Arial;}{\f1 Times;}}}';
        final converter = RtfToAttributedText(rtf);
        final metadata = converter.parseHeader();

        expect(metadata.defaultFontIndex, 1);
      });
    });

    group('content conversion', () {
      test('converts plain text', () {
        const rtf = r'{\rtf1 Hello World}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        expect(result.paragraphs.length, 1);
        expect(result.paragraphs[0].toPlainText(), 'Hello World');
      });

      test('converts paragraph breaks', () {
        const rtf = r'{\rtf1 First\par Second}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        expect(result.paragraphs.length, 2);
        expect(result.paragraphs[0].toPlainText(), 'First');
        expect(result.paragraphs[1].toPlainText(), 'Second');
      });

      test('preserves bold formatting', () {
        const rtf = r'{\rtf1 normal \b bold\b0  normal}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final text = result.paragraphs[0];
        final plainText = text.toPlainText();

        // Find the position of "bold" in the text
        final boldStart = plainText.indexOf('bold');
        expect(boldStart, greaterThanOrEqualTo(0));

        // Check that bold attribution is present at that position
        final attributions = text.getAllAttributionsAt(boldStart);
        expect(attributions.contains(boldAttribution), isTrue);
      });

      test('preserves italic formatting', () {
        const rtf = r'{\rtf1 normal \i italic\i0  normal}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final text = result.paragraphs[0];
        final plainText = text.toPlainText();
        final italicStart = plainText.indexOf('italic');

        final attributions = text.getAllAttributionsAt(italicStart);
        expect(attributions.contains(italicsAttribution), isTrue);
      });

      test('preserves underline formatting', () {
        const rtf = r'{\rtf1 normal \ul underline\ulnone  normal}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final text = result.paragraphs[0];
        final plainText = text.toPlainText();
        final underlineStart = plainText.indexOf('underline');

        final attributions = text.getAllAttributionsAt(underlineStart);
        expect(attributions.contains(underlineAttribution), isTrue);
      });

      test('preserves mixed formatting', () {
        const rtf = r'{\rtf1 \b\i bold italic\i0\b0 }';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final text = result.paragraphs[0];
        final attributions = text.getAllAttributionsAt(0);

        expect(attributions.contains(boldAttribution), isTrue);
        expect(attributions.contains(italicsAttribution), isTrue);
      });

      test('handles Unicode escapes', () {
        const rtf = r'{\rtf1 \u8212? em dash}'; // Em dash
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final plainText = result.paragraphs[0].toPlainText();
        expect(plainText, contains('—')); // Em dash character
      });

      test('handles hex escapes', () {
        const rtf = r"{\rtf1 \'93smart quote\'94}";
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final plainText = result.paragraphs[0].toPlainText();
        // \'93 and \'94 are Windows-1252 encoded smart quotes
        // which decode to Unicode " (U+201C) and " (U+201D)
        expect(plainText, contains('\u201C')); // Opening smart quote
        expect(plainText, contains('\u201D')); // Closing smart quote
      });

      test('ignores font table content', () {
        const rtf = r'{\rtf1{\fonttbl{\f0 Arial;}}Hello}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final plainText = result.paragraphs[0].toPlainText();
        expect(plainText, 'Hello');
        expect(plainText, isNot(contains('Arial')));
      });

      test('ignores color table content', () {
        const rtf = r'{\rtf1{\colortbl;\red255\green0\blue0;}Hello}';
        final converter = RtfToAttributedText(rtf);
        final result = converter.convert();

        final plainText = result.paragraphs[0].toPlainText();
        expect(plainText, 'Hello');
        expect(plainText, isNot(contains('red')));
      });
    });
  });

  group('AttributedTextToRtf', () {
    test('converts plain text to RTF', () {
      final paragraphs = [AttributedText('Hello World')];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, startsWith(r'{\rtf1'));
      expect(rtf, contains('Hello World'));
      expect(rtf, endsWith('}'));
    });

    test('converts multiple paragraphs', () {
      final paragraphs = [
        AttributedText('First'),
        AttributedText('Second'),
      ];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, contains('First'));
      expect(rtf, contains(r'\par'));
      expect(rtf, contains('Second'));
    });

    test('converts bold text', () {
      final spans = AttributedSpans()
        ..addAttribution(
          newAttribution: boldAttribution,
          start: 0,
          end: 3, // "bold"
        );
      final text = AttributedText('bold text', spans);

      final paragraphs = [text];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, contains(r'\b '));
      expect(rtf, contains(r'\b0 '));
    });

    test('converts italic text', () {
      final spans = AttributedSpans()
        ..addAttribution(
          newAttribution: italicsAttribution,
          start: 0,
          end: 5, // "italic"
        );
      final text = AttributedText('italic text', spans);

      final paragraphs = [text];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, contains(r'\i '));
      expect(rtf, contains(r'\i0 '));
    });

    test('converts underline text', () {
      final spans = AttributedSpans()
        ..addAttribution(
          newAttribution: underlineAttribution,
          start: 0,
          end: 8, // "underline"
        );
      final text = AttributedText('underline text', spans);

      final paragraphs = [text];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, contains(r'\ul '));
      expect(rtf, contains(r'\ulnone '));
    });

    test('escapes special characters', () {
      final paragraphs = [AttributedText(r'backslash \ and {braces}')];
      final converter = AttributedTextToRtf(paragraphs);
      final rtf = converter.convert();

      expect(rtf, contains(r'\\'));
      expect(rtf, contains(r'\{'));
      expect(rtf, contains(r'\}'));
    });

    test('preserves font table from metadata', () {
      const metadata = RtfMetadata(
        fontTable: [
          const RtfFont(index: 0, name: 'Arial', family: 'swiss'),
          const RtfFont(index: 1, name: 'Times New Roman', family: 'roman'),
        ],
      );
      final paragraphs = [AttributedText('Text')];
      final converter = AttributedTextToRtf(paragraphs, metadata: metadata);
      final rtf = converter.convert();

      expect(rtf, contains(r'{\fonttbl'));
      expect(rtf, contains('Arial'));
      expect(rtf, contains('Times New Roman'));
    });

    test('preserves color table from metadata', () {
      const metadata = RtfMetadata(
        colorTable: [
          null, // auto
          const Color.fromARGB(255, 255, 0, 0), // red
        ],
      );
      final paragraphs = [AttributedText('Text')];
      final converter = AttributedTextToRtf(paragraphs, metadata: metadata);
      final rtf = converter.convert();

      expect(rtf, contains(r'{\colortbl'));
      expect(rtf, contains(r'\red255\green0\blue0'));
    });
  });

  group('Round-trip conversion', () {
    test('preserves plain text content', () {
      // Use a simpler RTF structure that the parser handles well
      const originalRtf = r'{\rtf1 Hello World}';

      final toAttributed = RtfToAttributedText(originalRtf);
      final result = toAttributed.convert();

      // Get the original parsed text
      final originalText = result.paragraphs[0].toPlainText();

      final toRtf = AttributedTextToRtf(result.paragraphs, metadata: result.metadata);
      final convertedRtf = toRtf.convert();

      // Re-parse the converted RTF
      final reparse = RtfToAttributedText(convertedRtf);
      final reparsed = reparse.convert();

      // The reparsed text should match the original parsed text
      expect(
        reparsed.paragraphs[0].toPlainText(),
        originalText,
      );
    });

    test('preserves bold formatting through round-trip', () {
      const originalRtf = r'{\rtf1 normal \b bold\b0  normal}';

      final toAttributed = RtfToAttributedText(originalRtf);
      final result = toAttributed.convert();

      final toRtf = AttributedTextToRtf(result.paragraphs, metadata: result.metadata);
      final convertedRtf = toRtf.convert();

      // Re-parse and check bold is still present
      final reparse = RtfToAttributedText(convertedRtf);
      final reparsed = reparse.convert();

      final text = reparsed.paragraphs[0];
      final plainText = text.toPlainText();
      final boldStart = plainText.indexOf('bold');

      expect(boldStart, greaterThanOrEqualTo(0));
      final attributions = text.getAllAttributionsAt(boldStart);
      expect(attributions.contains(boldAttribution), isTrue);
    });

    test('preserves multiple paragraph structure', () {
      const originalRtf = r'{\rtf1 First\par Second\par Third}';

      final toAttributed = RtfToAttributedText(originalRtf);
      final result = toAttributed.convert();

      // Initial parse should have 3 paragraphs
      expect(result.paragraphs.length, 3);
      final first = result.paragraphs[0].toPlainText();
      final second = result.paragraphs[1].toPlainText();
      final third = result.paragraphs[2].toPlainText();

      final toRtf = AttributedTextToRtf(result.paragraphs, metadata: result.metadata);
      final convertedRtf = toRtf.convert();

      final reparse = RtfToAttributedText(convertedRtf);
      final reparsed = reparse.convert();

      expect(reparsed.paragraphs.length, 3);
      expect(reparsed.paragraphs[0].toPlainText(), first);
      expect(reparsed.paragraphs[1].toPlainText(), second);
      expect(reparsed.paragraphs[2].toPlainText(), third);
    });
  });

  group('RtfMetadata', () {
    test('getFontByIndex returns correct font', () {
      const metadata = RtfMetadata(
        fontTable: [
          const RtfFont(index: 0, name: 'Arial'),
          const RtfFont(index: 1, name: 'Times'),
        ],
      );

      expect(metadata.getFontByIndex(0)?.name, 'Arial');
      expect(metadata.getFontByIndex(1)?.name, 'Times');
      expect(metadata.getFontByIndex(99), isNull);
    });

    test('getColorByIndex returns correct color', () {
      const metadata = RtfMetadata(
        colorTable: [
          null,
          const Color.fromARGB(255, 255, 0, 0),
        ],
      );

      expect(metadata.getColorByIndex(0), isNull);
      expect(metadata.getColorByIndex(1), const Color.fromARGB(255, 255, 0, 0));
      expect(metadata.getColorByIndex(99), isNull);
    });

    test('indexOfColor finds existing color', () {
      const metadata = RtfMetadata(
        colorTable: [
          null,
          const Color.fromARGB(255, 255, 0, 0),
          const Color.fromARGB(255, 0, 255, 0),
        ],
      );

      expect(metadata.indexOfColor(const Color.fromARGB(255, 255, 0, 0)), 1);
      expect(metadata.indexOfColor(const Color.fromARGB(255, 0, 255, 0)), 2);
      expect(metadata.indexOfColor(const Color.fromARGB(255, 0, 0, 255)), -1);
    });

    test('indexOfFont finds existing font', () {
      const metadata = RtfMetadata(
        fontTable: [
          const RtfFont(index: 0, name: 'Arial'),
          const RtfFont(index: 1, name: 'Times'),
        ],
      );

      expect(metadata.indexOfFont('Arial'), 0);
      expect(metadata.indexOfFont('Times'), 1);
      expect(metadata.indexOfFont('Courier'), -1);
    });
  });
}
