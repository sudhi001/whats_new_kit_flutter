import 'package:flutter/widgets.dart';

import '../text/inline_markdown.dart';
import '../theme/whats_new_theme.dart';

/// A piece of text shown on a What's New surface.
///
/// This replaces WhatsNewKit's `NSAttributedString`-backed `WhatsNew.Text`.
/// Most callers use the default constructor and pass a plain [String]; the
/// other variants exist for the cases the Swift package covers with attributed
/// strings — a two-tone title, or a subtitle containing inline code.
@immutable
sealed class WhatsNewText {
  const WhatsNewText._();

  /// Plain, unstyled text.
  const factory WhatsNewText(String value) = PlainWhatsNewText;

  /// Text built from an explicit [InlineSpan], for full control over styling.
  const factory WhatsNewText.rich(InlineSpan span, {String? semanticsLabel}) =
      RichWhatsNewText;

  /// Text containing inline Markdown: `**bold**`, `*italic*`, `` `code` ``
  /// and `[label](url)`.
  const factory WhatsNewText.markdown(String markdown) = MarkdownWhatsNewText;

  /// Text assembled at build time, when styling depends on the surrounding
  /// [BuildContext].
  const factory WhatsNewText.builder(WhatsNewTextSpanBuilder builder,
      {String? semanticsLabel}) = BuilderWhatsNewText;

  /// Converts this text into a span, styled from [base].
  InlineSpan toSpan(BuildContext context, TextStyle base);

  /// The text with all styling removed, for accessibility and equality.
  String get plainText;
}

/// Builds a span for a [WhatsNewText.builder].
typedef WhatsNewTextSpanBuilder = InlineSpan Function(
  BuildContext context,
  TextStyle base,
);

/// Plain text. See [WhatsNewText.new].
class PlainWhatsNewText extends WhatsNewText {
  /// Creates plain text.
  const PlainWhatsNewText(this.value) : super._();

  /// The text itself.
  final String value;

  @override
  InlineSpan toSpan(BuildContext context, TextStyle base) =>
      TextSpan(text: value, style: base);

  @override
  String get plainText => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlainWhatsNewText && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Explicitly styled text. See [WhatsNewText.rich].
class RichWhatsNewText extends WhatsNewText {
  /// Creates rich text from [span].
  const RichWhatsNewText(this.span, {this.semanticsLabel}) : super._();

  /// The span to render.
  final InlineSpan span;

  /// What screen readers should announce instead of the span's raw text.
  final String? semanticsLabel;

  @override
  InlineSpan toSpan(BuildContext context, TextStyle base) =>
      TextSpan(style: base, children: <InlineSpan>[span]);

  @override
  String get plainText => semanticsLabel ?? span.toPlainText();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RichWhatsNewText &&
          other.span == span &&
          other.semanticsLabel == semanticsLabel;

  @override
  int get hashCode => Object.hash(span, semanticsLabel);
}

/// Inline-Markdown text. See [WhatsNewText.markdown].
class MarkdownWhatsNewText extends WhatsNewText {
  /// Creates Markdown text.
  const MarkdownWhatsNewText(this.markdown) : super._();

  /// The Markdown source.
  final String markdown;

  @override
  InlineSpan toSpan(BuildContext context, TextStyle base) {
    final WhatsNewResolvedTheme theme = WhatsNewTheme.resolve(context);
    return TextSpan(
      style: base,
      children: parseInlineMarkdown(
        markdown,
        base,
        style: theme.markdownStyle,
        onLinkTap: theme.onMarkdownLinkTap,
      ),
    );
  }

  @override
  String get plainText => stripInlineMarkdown(markdown);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkdownWhatsNewText && other.markdown == markdown;

  @override
  int get hashCode => markdown.hashCode;
}

/// Context-dependent text. See [WhatsNewText.builder].
class BuilderWhatsNewText extends WhatsNewText {
  /// Creates text built at layout time.
  const BuilderWhatsNewText(this.builder, {this.semanticsLabel}) : super._();

  /// Assembles the span.
  final WhatsNewTextSpanBuilder builder;

  /// What screen readers should announce.
  final String? semanticsLabel;

  @override
  InlineSpan toSpan(BuildContext context, TextStyle base) =>
      builder(context, base);

  @override
  String get plainText => semanticsLabel ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuilderWhatsNewText &&
          other.builder == builder &&
          other.semanticsLabel == semanticsLabel;

  @override
  int get hashCode => Object.hash(builder, semanticsLabel);
}
