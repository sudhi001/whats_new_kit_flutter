import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const TextStyle _base = TextStyle(fontSize: 15);

String _plainOf(List<InlineSpan> spans) =>
    TextSpan(children: spans).toPlainText();

void main() {
  group('parseInlineMarkdown', () {
    test('passes plain text through unchanged', () {
      final List<InlineSpan> spans = parseInlineMarkdown('Hello there', _base);
      expect(_plainOf(spans), 'Hello there');
    });

    test('bolds a **span**', () {
      final List<InlineSpan> spans =
          parseInlineMarkdown('a **bold** word', _base);
      expect(_plainOf(spans), 'a bold word');
      final TextSpan bold = spans
          .whereType<TextSpan>()
          .firstWhere((TextSpan span) => span.text == 'bold');
      expect(bold.style?.fontWeight, FontWeight.w700);
    });

    test('italicises an *span*', () {
      final List<InlineSpan> spans = parseInlineMarkdown('an *idea*', _base);
      final TextSpan italic = spans
          .whereType<TextSpan>()
          .firstWhere((TextSpan span) => span.text == 'idea');
      expect(italic.style?.fontStyle, FontStyle.italic);
    });

    test('renders `code` in a monospace face', () {
      final List<InlineSpan> spans =
          parseInlineMarkdown('call `.whatsNewSheet()` here', _base);
      final TextSpan code = spans
          .whereType<TextSpan>()
          .firstWhere((TextSpan span) => span.text == '.whatsNewSheet()');
      expect(code.style?.fontFamily, 'monospace');
    });

    test('links [label](url) and attaches a tap recognizer', () {
      Uri? tapped;
      final List<InlineSpan> spans = parseInlineMarkdown(
        'see [the docs](https://example.com)',
        _base,
        onLinkTap: (Uri url) => tapped = url,
      );
      final TextSpan link = spans
          .whereType<TextSpan>()
          .firstWhere((TextSpan span) => span.text == 'the docs');
      expect(link.recognizer, isNotNull);
      (link.recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, Uri.parse('https://example.com'));
      addTearDown(link.recognizer!.dispose);
    });

    test('emits unmatched delimiters literally', () {
      expect(_plainOf(parseInlineMarkdown('2 * 3 * 4 = 24', _base)),
          '2 * 3 * 4 = 24');
      expect(_plainOf(parseInlineMarkdown('a lone ` tick', _base)),
          'a lone ` tick');
      expect(
          _plainOf(parseInlineMarkdown('[not a link]', _base)), '[not a link]');
    });

    test('honours backslash escapes', () {
      expect(_plainOf(parseInlineMarkdown(r'literal \*stars\*', _base)),
          'literal *stars*');
    });

    test('nests emphasis inside emphasis', () {
      final List<InlineSpan> spans =
          parseInlineMarkdown('**bold with *both***', _base);
      expect(_plainOf(spans), 'bold with both');
    });
  });

  group('stripInlineMarkdown', () {
    test('leaves readable text for screen readers', () {
      expect(
        stripInlineMarkdown('use `code`, read [docs](https://x.dev), **now**'),
        'use code, read docs, now',
      );
    });
  });

  group('WhatsNewText', () {
    testWidgets('markdown text reports stripped plain text',
        (WidgetTester tester) async {
      const WhatsNewText text = WhatsNewText.markdown('a **bold** claim');
      expect(text.plainText, 'a bold claim');
    });

    testWidgets('rich text can carry its own semantics label',
        (WidgetTester tester) async {
      const WhatsNewText text = WhatsNewText.rich(
        TextSpan(text: 'Translate'),
        semanticsLabel: "What's New in Translate",
      );
      expect(text.plainText, "What's New in Translate");
    });
  });
}
