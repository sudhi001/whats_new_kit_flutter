import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/whats_new_layout.dart';
import '../text/inline_markdown.dart';
import 'whats_new_resolved_theme.dart';

export 'whats_new_resolved_theme.dart';

/// App-wide styling for What's New surfaces.
///
/// Every field is nullable: anything left unset is derived from the ambient
/// [ColorScheme] and [TextTheme], so the package follows `Theme.of(context)` by
/// default and adapts to light and dark without configuration.
///
/// Register it on your theme to restyle every What's New sheet at once:
///
/// ```dart
/// ThemeData(
///   extensions: const <ThemeExtension<dynamic>>[
///     WhatsNewTheme(accentColor: Colors.cyan),
///   ],
/// )
/// ```
@immutable
class WhatsNewTheme extends ThemeExtension<WhatsNewTheme> {
  /// Creates a theme override. Unset fields fall through to the defaults.
  const WhatsNewTheme({
    this.accentColor,
    this.titleStyle,
    this.featureTitleStyle,
    this.featureSubtitleStyle,
    this.primaryButtonTextStyle,
    this.secondaryButtonTextStyle,
    this.primaryButtonBackgroundColor,
    this.primaryButtonForegroundColor,
    this.sheetBackgroundColor,
    this.footerBlurSigma,
    this.footerScrimColor,
    this.footerScrimOpacity,
    this.pressedOpacity,
    this.markdownStyle,
    this.onMarkdownLinkTap,
    this.layout,
  });

  /// The tint used for feature icons and the secondary action.
  final Color? accentColor;

  /// Overrides the large title's style.
  final TextStyle? titleStyle;

  /// Overrides a feature title's style.
  final TextStyle? featureTitleStyle;

  /// Overrides a feature subtitle's style.
  final TextStyle? featureSubtitleStyle;

  /// Overrides the primary button label's style.
  final TextStyle? primaryButtonTextStyle;

  /// Overrides the secondary action label's style.
  final TextStyle? secondaryButtonTextStyle;

  /// Overrides the primary button's fill.
  final Color? primaryButtonBackgroundColor;

  /// Overrides the primary button's label color.
  final Color? primaryButtonForegroundColor;

  /// Overrides the sheet's background.
  final Color? sheetBackgroundColor;

  /// Overrides the footer's blur radius. Defaults to `20`.
  final double? footerBlurSigma;

  /// Overrides the translucent fill drawn over the footer's blur.
  ///
  /// Set this to control the fill outright; set [footerScrimOpacity] to keep
  /// the surface colour and change only how opaque it is.
  final Color? footerScrimColor;

  /// How opaque the footer's scrim is over the surface colour. Defaults to
  /// `0.70`. Ignored when [footerScrimColor] is set.
  final double? footerScrimOpacity;

  /// Overrides the opacity a button drops to while pressed. Defaults to `0.5`.
  final double? pressedOpacity;

  /// Overrides how inline Markdown is styled.
  final InlineMarkdownStyle? markdownStyle;

  /// Overrides what happens when a Markdown link is tapped.
  ///
  /// Defaults to opening the URL with `url_launcher`.
  final InlineMarkdownLinkTapHandler? onMarkdownLinkTap;

  /// Overrides the surface geometry.
  final WhatsNewLayout? layout;

  /// The theme registered on the ambient [ThemeData], if any.
  static WhatsNewTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<WhatsNewTheme>();

  /// Resolves the styling for a What's New surface.
  ///
  /// Values are taken from, in decreasing priority: [override], the
  /// [WhatsNewTheme] registered on the ambient theme, and finally the ambient
  /// [ColorScheme] and [TextTheme].
  static WhatsNewResolvedTheme resolve(
    BuildContext context, [
    WhatsNewTheme? override,
  ]) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    // Apple's Bold Text and Android's equivalent. Flutter surfaces the
    // setting but leaves honouring it to the app.
    final bool boldText = MediaQuery.boldTextOf(context);
    final WhatsNewTheme merged =
        (maybeOf(context) ?? const WhatsNewTheme()).merge(override);

    final Color accent = merged.accentColor ?? colors.primary;
    final Color surface = merged.sheetBackgroundColor ?? colors.surface;
    final TextStyle base =
        theme.textTheme.bodyMedium ?? const TextStyle(inherit: true);

    TextStyle styled({
      required double fontSize,
      required FontWeight fontWeight,
      required double lineHeight,
      required double letterSpacing,
      required Color color,
    }) {
      return base.copyWith(
        fontSize: fontSize,
        fontWeight: boldText ? _bolder(fontWeight) : fontWeight,
        height: lineHeight / fontSize,
        letterSpacing: letterSpacing,
        color: color,
        decoration: TextDecoration.none,
      );
    }

    final Color primaryButtonBackground =
        merged.primaryButtonBackgroundColor ?? accent;

    return WhatsNewResolvedTheme(
      accentColor: accent,
      sheetBackgroundColor: surface,
      footerScrimColor: merged.footerScrimColor ??
          surface.withValues(alpha: merged.footerScrimOpacity ?? 0.70),
      primaryButtonBackgroundColor: primaryButtonBackground,
      primaryButtonForegroundColor:
          merged.primaryButtonForegroundColor ?? colors.onPrimary,
      // SwiftUI `.largeTitle.bold()`.
      titleStyle: merged.titleStyle ??
          styled(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            lineHeight: 41,
            letterSpacing: 0.37,
            color: colors.onSurface,
          ),
      // SwiftUI `.subheadline.weight(.semibold)`.
      featureTitleStyle: merged.featureTitleStyle ??
          styled(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            lineHeight: 20,
            letterSpacing: -0.24,
            color: colors.onSurface,
          ),
      // SwiftUI `.subheadline` in the secondary label color.
      featureSubtitleStyle: merged.featureSubtitleStyle ??
          styled(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            lineHeight: 20,
            letterSpacing: -0.24,
            color: colors.onSurfaceVariant,
          ),
      // SwiftUI `.headline.weight(.semibold)`.
      primaryButtonTextStyle: merged.primaryButtonTextStyle ??
          styled(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            lineHeight: 22,
            letterSpacing: -0.41,
            color: merged.primaryButtonForegroundColor ?? colors.onPrimary,
          ),
      // SwiftUI `.body`.
      secondaryButtonTextStyle: merged.secondaryButtonTextStyle ??
          styled(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            lineHeight: 22,
            letterSpacing: -0.41,
            color: accent,
          ),
      footerBlurSigma: merged.footerBlurSigma ?? 20,
      pressedOpacity: merged.pressedOpacity ?? 0.5,
      markdownStyle: merged.markdownStyle ??
          InlineMarkdownStyle(
            linkColor: accent,
            codeBackgroundColor: colors.onSurface.withValues(alpha: 0.08),
          ),
      onMarkdownLinkTap: merged.onMarkdownLinkTap ?? launchMarkdownLink,
      layout: merged.layout ?? WhatsNewLayout.standard,
    );
  }

  /// Returns a copy of this theme with any set field of [other] applied on top.
  WhatsNewTheme merge(WhatsNewTheme? other) {
    if (other == null) {
      return this;
    }
    return WhatsNewTheme(
      accentColor: other.accentColor ?? accentColor,
      titleStyle: other.titleStyle ?? titleStyle,
      featureTitleStyle: other.featureTitleStyle ?? featureTitleStyle,
      featureSubtitleStyle: other.featureSubtitleStyle ?? featureSubtitleStyle,
      primaryButtonTextStyle:
          other.primaryButtonTextStyle ?? primaryButtonTextStyle,
      secondaryButtonTextStyle:
          other.secondaryButtonTextStyle ?? secondaryButtonTextStyle,
      primaryButtonBackgroundColor:
          other.primaryButtonBackgroundColor ?? primaryButtonBackgroundColor,
      primaryButtonForegroundColor:
          other.primaryButtonForegroundColor ?? primaryButtonForegroundColor,
      sheetBackgroundColor: other.sheetBackgroundColor ?? sheetBackgroundColor,
      footerBlurSigma: other.footerBlurSigma ?? footerBlurSigma,
      footerScrimColor: other.footerScrimColor ?? footerScrimColor,
      footerScrimOpacity: other.footerScrimOpacity ?? footerScrimOpacity,
      pressedOpacity: other.pressedOpacity ?? pressedOpacity,
      markdownStyle: other.markdownStyle ?? markdownStyle,
      onMarkdownLinkTap: other.onMarkdownLinkTap ?? onMarkdownLinkTap,
      layout: other.layout ?? layout,
    );
  }

  @override
  WhatsNewTheme copyWith({
    Color? accentColor,
    TextStyle? titleStyle,
    TextStyle? featureTitleStyle,
    TextStyle? featureSubtitleStyle,
    TextStyle? primaryButtonTextStyle,
    TextStyle? secondaryButtonTextStyle,
    Color? primaryButtonBackgroundColor,
    Color? primaryButtonForegroundColor,
    Color? sheetBackgroundColor,
    double? footerBlurSigma,
    Color? footerScrimColor,
    double? footerScrimOpacity,
    double? pressedOpacity,
    InlineMarkdownStyle? markdownStyle,
    InlineMarkdownLinkTapHandler? onMarkdownLinkTap,
    WhatsNewLayout? layout,
  }) {
    return WhatsNewTheme(
      accentColor: accentColor ?? this.accentColor,
      titleStyle: titleStyle ?? this.titleStyle,
      featureTitleStyle: featureTitleStyle ?? this.featureTitleStyle,
      featureSubtitleStyle: featureSubtitleStyle ?? this.featureSubtitleStyle,
      primaryButtonTextStyle:
          primaryButtonTextStyle ?? this.primaryButtonTextStyle,
      secondaryButtonTextStyle:
          secondaryButtonTextStyle ?? this.secondaryButtonTextStyle,
      primaryButtonBackgroundColor:
          primaryButtonBackgroundColor ?? this.primaryButtonBackgroundColor,
      primaryButtonForegroundColor:
          primaryButtonForegroundColor ?? this.primaryButtonForegroundColor,
      sheetBackgroundColor: sheetBackgroundColor ?? this.sheetBackgroundColor,
      footerBlurSigma: footerBlurSigma ?? this.footerBlurSigma,
      footerScrimColor: footerScrimColor ?? this.footerScrimColor,
      footerScrimOpacity: footerScrimOpacity ?? this.footerScrimOpacity,
      pressedOpacity: pressedOpacity ?? this.pressedOpacity,
      markdownStyle: markdownStyle ?? this.markdownStyle,
      onMarkdownLinkTap: onMarkdownLinkTap ?? this.onMarkdownLinkTap,
      layout: layout ?? this.layout,
    );
  }

  @override
  WhatsNewTheme lerp(ThemeExtension<WhatsNewTheme>? other, double t) {
    if (other is! WhatsNewTheme) {
      return this;
    }
    return WhatsNewTheme(
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      featureTitleStyle:
          TextStyle.lerp(featureTitleStyle, other.featureTitleStyle, t),
      featureSubtitleStyle:
          TextStyle.lerp(featureSubtitleStyle, other.featureSubtitleStyle, t),
      primaryButtonTextStyle: TextStyle.lerp(
          primaryButtonTextStyle, other.primaryButtonTextStyle, t),
      secondaryButtonTextStyle: TextStyle.lerp(
          secondaryButtonTextStyle, other.secondaryButtonTextStyle, t),
      primaryButtonBackgroundColor: Color.lerp(
          primaryButtonBackgroundColor, other.primaryButtonBackgroundColor, t),
      primaryButtonForegroundColor: Color.lerp(
          primaryButtonForegroundColor, other.primaryButtonForegroundColor, t),
      sheetBackgroundColor:
          Color.lerp(sheetBackgroundColor, other.sheetBackgroundColor, t),
      footerBlurSigma: _lerpDouble(footerBlurSigma, other.footerBlurSigma, t),
      footerScrimColor: Color.lerp(footerScrimColor, other.footerScrimColor, t),
      footerScrimOpacity:
          _lerpDouble(footerScrimOpacity, other.footerScrimOpacity, t),
      pressedOpacity: _lerpDouble(pressedOpacity, other.pressedOpacity, t),
      markdownStyle: t < 0.5 ? markdownStyle : other.markdownStyle,
      onMarkdownLinkTap: t < 0.5 ? onMarkdownLinkTap : other.onMarkdownLinkTap,
      layout: t < 0.5 ? layout : other.layout,
    );
  }

  /// Bumps [weight] one step for the reader's Bold Text setting.
  static FontWeight _bolder(FontWeight weight) {
    final int index = FontWeight.values.indexOf(weight);
    return FontWeight.values[math.min(index + 2, FontWeight.values.length - 1)];
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return (a ?? b!) + ((b ?? a!) - (a ?? b!)) * t;
  }
}
