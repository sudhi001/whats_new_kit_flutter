import 'package:flutter/widgets.dart';

import '../models/whats_new_layout.dart';
import '../text/inline_markdown.dart';

/// A fully resolved set of colors, text styles and geometry.
///
/// Produced by `WhatsNewTheme.resolve` and consumed by the widgets. Every field
/// is non-null, so the render path never has to fall back on anything.
@immutable
class WhatsNewResolvedTheme {
  /// Creates a resolved theme. All arguments are required by design.
  const WhatsNewResolvedTheme({
    required this.accentColor,
    required this.sheetBackgroundColor,
    required this.footerScrimColor,
    required this.primaryButtonBackgroundColor,
    required this.primaryButtonForegroundColor,
    required this.titleStyle,
    required this.featureTitleStyle,
    required this.featureSubtitleStyle,
    required this.primaryButtonTextStyle,
    required this.secondaryButtonTextStyle,
    required this.footerBlurSigma,
    required this.pressedOpacity,
    required this.markdownStyle,
    required this.onMarkdownLinkTap,
    required this.layout,
  });

  /// The tint used for feature icons and the secondary action.
  final Color accentColor;

  /// The surface behind the whole sheet.
  final Color sheetBackgroundColor;

  /// The translucent fill drawn over the footer's blur.
  final Color footerScrimColor;

  /// The primary button's fill.
  final Color primaryButtonBackgroundColor;

  /// The primary button's label color.
  final Color primaryButtonForegroundColor;

  /// The large title at the top of the sheet.
  final TextStyle titleStyle;

  /// A feature's title.
  final TextStyle featureTitleStyle;

  /// A feature's subtitle.
  final TextStyle featureSubtitleStyle;

  /// The primary button's label.
  final TextStyle primaryButtonTextStyle;

  /// The secondary action's label.
  final TextStyle secondaryButtonTextStyle;

  /// Blur radius applied behind the footer.
  final double footerBlurSigma;

  /// Opacity a button drops to while pressed.
  final double pressedOpacity;

  /// How inline Markdown is styled.
  final InlineMarkdownStyle markdownStyle;

  /// Runs when a Markdown link is tapped.
  final InlineMarkdownLinkTapHandler onMarkdownLinkTap;

  /// The geometry of the surface.
  final WhatsNewLayout layout;

  /// Returns a copy of this theme with the given fields replaced.
  WhatsNewResolvedTheme copyWith({
    Color? accentColor,
    Color? sheetBackgroundColor,
    Color? footerScrimColor,
    Color? primaryButtonBackgroundColor,
    Color? primaryButtonForegroundColor,
    TextStyle? titleStyle,
    TextStyle? featureTitleStyle,
    TextStyle? featureSubtitleStyle,
    TextStyle? primaryButtonTextStyle,
    TextStyle? secondaryButtonTextStyle,
    double? footerBlurSigma,
    double? pressedOpacity,
    InlineMarkdownStyle? markdownStyle,
    InlineMarkdownLinkTapHandler? onMarkdownLinkTap,
    WhatsNewLayout? layout,
  }) {
    return WhatsNewResolvedTheme(
      accentColor: accentColor ?? this.accentColor,
      sheetBackgroundColor: sheetBackgroundColor ?? this.sheetBackgroundColor,
      footerScrimColor: footerScrimColor ?? this.footerScrimColor,
      primaryButtonBackgroundColor:
          primaryButtonBackgroundColor ?? this.primaryButtonBackgroundColor,
      primaryButtonForegroundColor:
          primaryButtonForegroundColor ?? this.primaryButtonForegroundColor,
      titleStyle: titleStyle ?? this.titleStyle,
      featureTitleStyle: featureTitleStyle ?? this.featureTitleStyle,
      featureSubtitleStyle: featureSubtitleStyle ?? this.featureSubtitleStyle,
      primaryButtonTextStyle:
          primaryButtonTextStyle ?? this.primaryButtonTextStyle,
      secondaryButtonTextStyle:
          secondaryButtonTextStyle ?? this.secondaryButtonTextStyle,
      footerBlurSigma: footerBlurSigma ?? this.footerBlurSigma,
      pressedOpacity: pressedOpacity ?? this.pressedOpacity,
      markdownStyle: markdownStyle ?? this.markdownStyle,
      onMarkdownLinkTap: onMarkdownLinkTap ?? this.onMarkdownLinkTap,
      layout: layout ?? this.layout,
    );
  }
}
