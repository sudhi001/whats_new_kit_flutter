import 'package:flutter/widgets.dart';

import '../theme/whats_new_form_factor.dart';

/// How the footer's backdrop is drawn.
enum WhatsNewFooterBackground {
  /// A blurred backdrop, matching iOS's `UIBlurEffect(style: .regular)`.
  blur,

  /// A flat opaque fill. Cheaper than [blur] on constrained devices.
  solid,

  /// No backdrop at all — the content scrolls visibly behind the buttons.
  none,
}

/// How the footer treats the bottom safe area.
enum WhatsNewSafeAreaBehavior {
  /// The footer's bottom padding *includes* the safe area, matching
  /// WhatsNewKit's `edgesIgnoringSafeArea(.bottom)`.
  absorb,

  /// The safe area inset is added on top of the footer's bottom padding.
  /// Useful on Android devices with a tall gesture bar.
  add,
}

/// How the title, features and actions are arranged.
enum WhatsNewContentLayout {
  /// Title above the feature list, with the actions pinned to the bottom.
  single,

  /// Title and actions in one column, the feature list scrolling beside them.
  ///
  /// Uses the horizontal space a landscape phone or tablet has and the
  /// vertical space it does not.
  twoColumn,

  /// [twoColumn] on a wide, short surface; [single] everywhere else.
  adaptive,
}

/// Resolves an inset for a given form factor.
typedef WhatsNewInsetResolver = EdgeInsets Function(
    WhatsNewFormFactor formFactor);

/// The geometry of a What's New surface.
///
/// Every default is taken verbatim from `WhatsNew.Layout` in WhatsNewKit, plus
/// two values that are implicit in SwiftUI: [contentHorizontalPadding] (`16`,
/// from a bare `.padding(.horizontal)`) and [footerPrimaryButtonVerticalPadding]
/// (`16`, from a bare `.padding(.vertical)`).
///
/// Unlike the Swift original — whose defaults live in a mutable static — this
/// type is immutable. Override it per call site, or app-wide through
/// `WhatsNewTheme.layout`.
@immutable
class WhatsNewLayout {
  /// Creates a layout. Every argument defaults to WhatsNewKit's value.
  const WhatsNewLayout({
    this.showsScrollBar = false,
    this.scrollBottomContentInset = 150,
    this.contentSpacing = 60,
    this.contentPadding = const EdgeInsets.only(top: 65),
    this.contentHorizontalPadding = 16,
    this.featureListSpacing = 25,
    this.featureListPadding = const EdgeInsetsDirectional.only(start: 15),
    this.featureImageWidth = 40,
    this.featureImageSize = 28,
    this.featureHorizontalSpacing = 15,
    this.featureCrossAxisAlignment = CrossAxisAlignment.center,
    this.featureVerticalSpacing = 2,
    this.footerActionSpacing = 15,
    this.footerPrimaryButtonCornerRadius = 14,
    this.footerPrimaryButtonVerticalPadding = 16,
    this.minTapTargetSize = 48,
    this.footerBlurBleed = 10,
    this.footerBackground = WhatsNewFooterBackground.blur,
    this.bottomSafeAreaBehavior = WhatsNewSafeAreaBehavior.absorb,
    this.respectHighContrast = true,
    this.breakpoints = const WhatsNewBreakpoints(),
    this.contentLayout = WhatsNewContentLayout.adaptive,
    this.maxContentWidth = 560,
    this.twoColumnMinWidth = 600,
    this.twoColumnSpacing = 48,
    this.twoColumnMaxWidth = 1000,
    this.twoColumnTitleFlex = 5,
    this.twoColumnFeaturesFlex = 6,
    this.constrainedHorizontalMargin = 20,
    this.centerContentWhenConstrained = true,
    this.sheetTopCornerRadius = 10,
    this.showDragHandle = false,
    this.dialogMaxWidth = 520,
    this.dialogMaxHeight = 720,
    this.dialogInsetPadding = const EdgeInsets.all(24),
    this.featuresPaddingResolver,
    this.footerPaddingResolver,
  });

  /// The stock layout, identical to WhatsNewKit's `WhatsNew.Layout.default`.
  static const WhatsNewLayout standard = WhatsNewLayout();

  /// Whether the content scroll view shows a scrollbar.
  final bool showsScrollBar;

  /// Empty space appended below the content so it can scroll clear of the
  /// pinned footer.
  final double scrollBottomContentInset;

  /// Vertical gap between the title and the feature list.
  final double contentSpacing;

  /// Padding around the whole content block.
  final EdgeInsets contentPadding;

  /// Horizontal padding applied to the content block.
  final double contentHorizontalPadding;

  /// Vertical gap between two features.
  final double featureListSpacing;

  /// Padding around the feature list, applied inside [featuresPaddingResolver].
  final EdgeInsetsDirectional featureListPadding;

  /// Width of the column reserved for each feature's image.
  final double featureImageWidth;

  /// Rendered size of a feature's icon inside that column.
  final double featureImageSize;

  /// Gap between a feature's image and its text.
  final double featureHorizontalSpacing;

  /// How a feature's image aligns against its text column.
  final CrossAxisAlignment featureCrossAxisAlignment;

  /// Gap between a feature's title and subtitle.
  final double featureVerticalSpacing;

  /// Gap between the secondary and primary actions in the footer.
  final double footerActionSpacing;

  /// Corner radius of the primary button.
  final double footerPrimaryButtonCornerRadius;

  /// Vertical padding inside the primary button, which sets its height.
  final double footerPrimaryButtonVerticalPadding;

  /// The smallest a tappable control is allowed to be.
  ///
  /// Defaults to 48, which clears every bar at once: Apple's Human Interface
  /// Guidelines ask for 44pt, Material and the Android guidance ask for 48dp,
  /// and WCAG 2.2 target size asks for 24 CSS px. A bare text link is only
  /// about 22pt tall, so it is padded out to this without changing how it
  /// looks.
  final double minTapTargetSize;

  /// How far the footer's backdrop extends above the footer itself.
  ///
  /// WhatsNewKit expresses this as a negative top padding on its visual effect
  /// view, so the blur bleeds over the scrolling content.
  final double footerBlurBleed;

  /// How the footer's backdrop is drawn.
  final WhatsNewFooterBackground footerBackground;

  /// How the footer treats the bottom safe area.
  final WhatsNewSafeAreaBehavior bottomSafeAreaBehavior;

  /// Whether to drop the footer blur when the reader has asked for higher
  /// contrast.
  ///
  /// Mirrors Reduce Transparency on Apple platforms: a translucent bar over
  /// moving content is exactly what that setting exists to remove.
  final bool respectHighContrast;

  /// The thresholds used to pick a [WhatsNewFormFactor].
  final WhatsNewBreakpoints breakpoints;

  /// How the title, features and actions are arranged.
  final WhatsNewContentLayout contentLayout;

  /// The widest the content column grows before it is centred in the surface.
  ///
  /// Without a cap, a feature subtitle on a tablet runs to a line length no
  /// one wants to read. Set this to [double.infinity] to reproduce
  /// WhatsNewKit's behaviour, which simply pads a full-width column.
  final double maxContentWidth;

  /// The width at or above which [WhatsNewContentLayout.adaptive] may choose
  /// two columns. It also requires the surface to be wider than it is tall.
  final double twoColumnMinWidth;

  /// The gap between the two columns.
  final double twoColumnSpacing;

  /// The widest the two-column row grows before it is centred.
  ///
  /// Keeps the feature column near [maxContentWidth] on a large landscape
  /// tablet or desktop window instead of letting it stretch edge to edge.
  final double twoColumnMaxWidth;

  /// The share of the width given to the title column.
  final int twoColumnTitleFlex;

  /// The share of the width given to the feature column.
  final int twoColumnFeaturesFlex;

  /// The side margin kept when [maxContentWidth] is capping the content.
  ///
  /// The wide responsive paddings exist to narrow a full-width column; once
  /// the column is capped they would only push it off-centre, so this margin
  /// replaces them.
  final double constrainedHorizontalMargin;

  /// Whether to centre the content vertically once [maxContentWidth] is
  /// capping it.
  ///
  /// A three-feature list pinned to the top of a tall tablet screen leaves the
  /// lower two thirds empty. Phones are never capped, so they keep
  /// WhatsNewKit's top alignment.
  final bool centerContentWhenConstrained;

  /// The corner radius of the bottom sheet's top edge.
  final double sheetTopCornerRadius;

  /// Whether the bottom sheet shows a grabber at the top.
  ///
  /// Apple's guidance is to show one when a sheet can be dragged, which this
  /// one can. It defaults to off because WhatsNewKit has none and the
  /// reference screenshots do not show one; turn it on if discoverability
  /// matters more to you than matching the original.
  final bool showDragHandle;

  /// The widest the dialog presentation grows.
  final double dialogMaxWidth;

  /// The tallest the dialog presentation grows.
  final double dialogMaxHeight;

  /// The margin between the dialog and the window edge.
  final EdgeInsets dialogInsetPadding;

  /// Overrides the responsive padding around the feature list.
  final WhatsNewInsetResolver? featuresPaddingResolver;

  /// Overrides the responsive padding around the footer.
  final WhatsNewInsetResolver? footerPaddingResolver;

  /// The padding around the feature list for [formFactor].
  ///
  /// When [widthConstrained] is true the content column is already capped by
  /// [maxContentWidth], so the wide responsive insets are dropped.
  EdgeInsets featuresPaddingFor(
    WhatsNewFormFactor formFactor, {
    bool widthConstrained = false,
  }) {
    final WhatsNewInsetResolver? resolver = featuresPaddingResolver;
    if (resolver != null) {
      return resolver(formFactor);
    }
    if (widthConstrained) {
      return EdgeInsets.zero;
    }
    switch (formFactor) {
      case WhatsNewFormFactor.regular:
        return const EdgeInsets.symmetric(horizontal: 100);
      case WhatsNewFormFactor.desktop:
        return const EdgeInsets.symmetric(horizontal: 16);
      case WhatsNewFormFactor.compact:
      case WhatsNewFormFactor.compactLandscape:
        return EdgeInsets.zero;
    }
  }

  /// The padding around the footer for [formFactor].
  ///
  /// When [widthConstrained] is true the footer is already capped by
  /// [maxContentWidth], so the wide side insets collapse to
  /// [constrainedHorizontalMargin] while the bottom inset is kept.
  EdgeInsets footerPaddingFor(
    WhatsNewFormFactor formFactor, {
    bool widthConstrained = false,
  }) {
    final WhatsNewInsetResolver? resolver = footerPaddingResolver;
    if (resolver != null) {
      return resolver(formFactor);
    }
    if (widthConstrained) {
      return EdgeInsets.only(
        left: constrainedHorizontalMargin,
        right: constrainedHorizontalMargin,
        bottom: _bottomInsetFor(formFactor),
      );
    }
    switch (formFactor) {
      case WhatsNewFormFactor.regular:
        return const EdgeInsets.fromLTRB(150, 0, 150, 50);
      case WhatsNewFormFactor.compactLandscape:
        return const EdgeInsets.fromLTRB(40, 0, 40, 35);
      case WhatsNewFormFactor.desktop:
        return const EdgeInsets.only(bottom: 30);
      case WhatsNewFormFactor.compact:
        return const EdgeInsets.fromLTRB(20, 0, 20, 80);
    }
  }

  /// The bottom inset the footer keeps regardless of how wide the surface is.
  double _bottomInsetFor(WhatsNewFormFactor formFactor) {
    switch (formFactor) {
      case WhatsNewFormFactor.regular:
        return 50;
      case WhatsNewFormFactor.compactLandscape:
        return 35;
      case WhatsNewFormFactor.desktop:
        return 30;
      case WhatsNewFormFactor.compact:
        return 80;
    }
  }

  /// Whether two columns should be used on a surface of [size].
  bool usesTwoColumns(Size size) {
    switch (contentLayout) {
      case WhatsNewContentLayout.single:
        return false;
      case WhatsNewContentLayout.twoColumn:
        return true;
      case WhatsNewContentLayout.adaptive:
        return size.width >= twoColumnMinWidth && size.width > size.height;
    }
  }

  /// Returns a copy of this layout with the given fields replaced.
  WhatsNewLayout copyWith({
    bool? showsScrollBar,
    double? scrollBottomContentInset,
    double? contentSpacing,
    EdgeInsets? contentPadding,
    double? contentHorizontalPadding,
    double? featureListSpacing,
    EdgeInsetsDirectional? featureListPadding,
    double? featureImageWidth,
    double? featureImageSize,
    double? featureHorizontalSpacing,
    CrossAxisAlignment? featureCrossAxisAlignment,
    double? featureVerticalSpacing,
    double? footerActionSpacing,
    double? footerPrimaryButtonCornerRadius,
    double? footerPrimaryButtonVerticalPadding,
    double? minTapTargetSize,
    double? footerBlurBleed,
    WhatsNewFooterBackground? footerBackground,
    WhatsNewSafeAreaBehavior? bottomSafeAreaBehavior,
    bool? respectHighContrast,
    WhatsNewBreakpoints? breakpoints,
    WhatsNewContentLayout? contentLayout,
    double? maxContentWidth,
    double? twoColumnMinWidth,
    double? twoColumnSpacing,
    double? twoColumnMaxWidth,
    int? twoColumnTitleFlex,
    int? twoColumnFeaturesFlex,
    double? constrainedHorizontalMargin,
    bool? centerContentWhenConstrained,
    double? sheetTopCornerRadius,
    bool? showDragHandle,
    double? dialogMaxWidth,
    double? dialogMaxHeight,
    EdgeInsets? dialogInsetPadding,
    WhatsNewInsetResolver? featuresPaddingResolver,
    WhatsNewInsetResolver? footerPaddingResolver,
  }) {
    return WhatsNewLayout(
      showsScrollBar: showsScrollBar ?? this.showsScrollBar,
      scrollBottomContentInset:
          scrollBottomContentInset ?? this.scrollBottomContentInset,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      contentPadding: contentPadding ?? this.contentPadding,
      contentHorizontalPadding:
          contentHorizontalPadding ?? this.contentHorizontalPadding,
      featureListSpacing: featureListSpacing ?? this.featureListSpacing,
      featureListPadding: featureListPadding ?? this.featureListPadding,
      featureImageWidth: featureImageWidth ?? this.featureImageWidth,
      featureImageSize: featureImageSize ?? this.featureImageSize,
      featureHorizontalSpacing:
          featureHorizontalSpacing ?? this.featureHorizontalSpacing,
      featureCrossAxisAlignment:
          featureCrossAxisAlignment ?? this.featureCrossAxisAlignment,
      featureVerticalSpacing:
          featureVerticalSpacing ?? this.featureVerticalSpacing,
      footerActionSpacing: footerActionSpacing ?? this.footerActionSpacing,
      footerPrimaryButtonCornerRadius: footerPrimaryButtonCornerRadius ??
          this.footerPrimaryButtonCornerRadius,
      footerPrimaryButtonVerticalPadding: footerPrimaryButtonVerticalPadding ??
          this.footerPrimaryButtonVerticalPadding,
      minTapTargetSize: minTapTargetSize ?? this.minTapTargetSize,
      footerBlurBleed: footerBlurBleed ?? this.footerBlurBleed,
      footerBackground: footerBackground ?? this.footerBackground,
      bottomSafeAreaBehavior:
          bottomSafeAreaBehavior ?? this.bottomSafeAreaBehavior,
      respectHighContrast: respectHighContrast ?? this.respectHighContrast,
      breakpoints: breakpoints ?? this.breakpoints,
      contentLayout: contentLayout ?? this.contentLayout,
      maxContentWidth: maxContentWidth ?? this.maxContentWidth,
      twoColumnMinWidth: twoColumnMinWidth ?? this.twoColumnMinWidth,
      twoColumnSpacing: twoColumnSpacing ?? this.twoColumnSpacing,
      twoColumnMaxWidth: twoColumnMaxWidth ?? this.twoColumnMaxWidth,
      twoColumnTitleFlex: twoColumnTitleFlex ?? this.twoColumnTitleFlex,
      twoColumnFeaturesFlex:
          twoColumnFeaturesFlex ?? this.twoColumnFeaturesFlex,
      constrainedHorizontalMargin:
          constrainedHorizontalMargin ?? this.constrainedHorizontalMargin,
      centerContentWhenConstrained:
          centerContentWhenConstrained ?? this.centerContentWhenConstrained,
      sheetTopCornerRadius: sheetTopCornerRadius ?? this.sheetTopCornerRadius,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
      dialogMaxHeight: dialogMaxHeight ?? this.dialogMaxHeight,
      dialogInsetPadding: dialogInsetPadding ?? this.dialogInsetPadding,
      featuresPaddingResolver:
          featuresPaddingResolver ?? this.featuresPaddingResolver,
      footerPaddingResolver:
          footerPaddingResolver ?? this.footerPaddingResolver,
    );
  }
}
