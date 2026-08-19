import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:url_launcher/url_launcher.dart';

/// Called when the reader taps a link produced by [parseInlineMarkdown].
typedef InlineMarkdownLinkTapHandler = void Function(Uri url);

/// How inline Markdown is styled.
///
/// Every field is optional; anything left unset is derived from the base text
/// style the span is built with.
@immutable
class InlineMarkdownStyle {
  /// Creates a Markdown style.
  const InlineMarkdownStyle({
    this.boldWeight = FontWeight.w700,
    this.codeStyle,
    this.codeFontFamily = 'monospace',
    this.codeFontFamilyFallback = const <String>['Menlo', 'Courier'],
    this.codeFontSizeFactor = 0.92,
    this.codeBackgroundColor,
    this.linkColor,
    this.linkDecoration,
  });

  /// The weight applied to `**bold**` runs.
  final FontWeight boldWeight;

  /// Replaces the derived style for `` `code` `` runs outright.
  final TextStyle? codeStyle;

  /// The family used for `` `code` `` runs when [codeStyle] is unset.
  final String codeFontFamily;

  /// Fallback families for `` `code` `` runs.
  final List<String> codeFontFamilyFallback;

  /// How much to scale the base size for `` `code` `` runs.
  final double codeFontSizeFactor;

  /// The fill drawn behind `` `code` `` runs.
  final Color? codeBackgroundColor;

  /// The colour of `[label](url)` runs.
  final Color? linkColor;

  /// The decoration applied to `[label](url)` runs.
  final TextDecoration? linkDecoration;

  /// Resolves the style for a `` `code` `` run against [base].
  TextStyle resolveCodeStyle(TextStyle base) {
    return codeStyle ??
        base.copyWith(
          fontFamily: codeFontFamily,
          fontFamilyFallback: codeFontFamilyFallback,
          fontSize: (base.fontSize ?? 14) * codeFontSizeFactor,
          backgroundColor: codeBackgroundColor,
        );
  }

  /// Resolves the style for a `[label](url)` run against [base].
  TextStyle resolveLinkStyle(TextStyle base) =>
      base.copyWith(color: linkColor, decoration: linkDecoration);
}

/// Parses a single paragraph of inline Markdown into spans.
///
/// Supports `**bold**`, `*italic*`, `` `code` `` and `[label](url)`. Block-level
/// syntax is deliberately unsupported: WhatsNewKit's attributed strings are
/// inline-only, and skipping block layout keeps this dependency-free.
///
/// Unmatched delimiters are emitted literally rather than swallowed, so a
/// subtitle mentioning `2 * 3 * 4` still reads correctly.
List<InlineSpan> parseInlineMarkdown(
  String source,
  TextStyle baseStyle, {
  InlineMarkdownStyle style = const InlineMarkdownStyle(),
  InlineMarkdownLinkTapHandler? onLinkTap,
}) {
  final List<InlineSpan> spans = <InlineSpan>[];
  final StringBuffer literal = StringBuffer();
  int index = 0;

  void flushLiteral() {
    if (literal.isNotEmpty) {
      spans.add(TextSpan(text: literal.toString(), style: baseStyle));
      literal.clear();
    }
  }

  bool isSpace(int at) =>
      at < 0 || at >= source.length || source[at].trim().isEmpty;

  /// Returns the content between [open] and its matching [close], advancing
  /// past both. Returns null when the delimiters do not pair up, so the caller
  /// can emit them literally.
  ///
  /// [tightFlanking] enforces the CommonMark rule that emphasis may not be
  /// padded with spaces, which is what keeps `2 * 3 * 4` from turning italic.
  String? readDelimited(
    String open,
    String close, {
    bool tightFlanking = false,
    bool absorbDelimiterRun = false,
  }) {
    if (!source.startsWith(open, index)) {
      return null;
    }
    final int contentStart = index + open.length;
    if (tightFlanking && isSpace(contentStart)) {
      return null;
    }
    int contentEnd = source.indexOf(close, contentStart);
    if (contentEnd == -1 || contentEnd == contentStart) {
      return null;
    }
    if (absorbDelimiterRun) {
      // `**bold *and* italic***` closes on the LAST two stars of the run, so
      // the inner emphasis stays inside the outer one.
      final String marker = close[0];
      int runEnd = contentEnd;
      while (runEnd < source.length && source[runEnd] == marker) {
        runEnd += 1;
      }
      final int adjusted = runEnd - close.length;
      if (adjusted > contentStart) {
        contentEnd = adjusted;
      }
    }
    if (tightFlanking && isSpace(contentEnd - 1)) {
      return null;
    }
    index = contentEnd + close.length;
    return source.substring(contentStart, contentEnd);
  }

  while (index < source.length) {
    final String character = source[index];

    if (character == r'\' && index + 1 < source.length) {
      literal.write(source[index + 1]);
      index += 2;
      continue;
    }

    if (character == '*' || character == '`' || character == '[') {
      final String? bold = readDelimited('**', '**',
          tightFlanking: true, absorbDelimiterRun: true);
      if (bold != null) {
        flushLiteral();
        spans.addAll(parseInlineMarkdown(
          bold,
          baseStyle.copyWith(fontWeight: style.boldWeight),
          style: style,
          onLinkTap: onLinkTap,
        ));
        continue;
      }

      final String? italic = readDelimited('*', '*', tightFlanking: true);
      if (italic != null) {
        flushLiteral();
        spans.addAll(parseInlineMarkdown(
          italic,
          baseStyle.copyWith(fontStyle: FontStyle.italic),
          style: style,
          onLinkTap: onLinkTap,
        ));
        continue;
      }

      final String? code = readDelimited('`', '`');
      if (code != null) {
        flushLiteral();
        spans.add(TextSpan(
          text: code,
          style: style.resolveCodeStyle(baseStyle),
        ));
        continue;
      }

      final String? label = readDelimited('[', ']');
      if (label != null) {
        final String? target = readDelimited('(', ')');
        if (target == null) {
          // Not a link after all — emit what we consumed literally.
          literal.write('[$label]');
          continue;
        }
        flushLiteral();
        final Uri? url = Uri.tryParse(target);
        spans.add(TextSpan(
          text: label,
          style: style.resolveLinkStyle(baseStyle),
          recognizer: (url != null && onLinkTap != null)
              ? (TapGestureRecognizer()..onTap = () => onLinkTap(url))
              : null,
        ));
        continue;
      }
    }

    literal.write(character);
    index += 1;
  }

  flushLiteral();
  return spans;
}

/// Strips inline Markdown syntax from [source], leaving readable plain text.
///
/// Used for accessibility labels, where the delimiters would otherwise be
/// spoken aloud.
String stripInlineMarkdown(String source) {
  return source
      .replaceAllMapped(
          RegExp(r'\[([^\]]*)\]\([^)]*\)'), (Match m) => m.group(1) ?? '')
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAll('*', '');
}

/// Opens [url] in the platform browser.
///
/// The default handler for Markdown links. Replace it through
/// `WhatsNewTheme.onMarkdownLinkTap` to route links somewhere else — an
/// in-app browser, or your own router.
Future<void> launchMarkdownLink(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  }
}
