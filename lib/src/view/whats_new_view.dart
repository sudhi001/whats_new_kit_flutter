import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/whats_new.dart';
import '../models/whats_new_layout.dart';
import '../store/whats_new_version_store.dart';
import '../theme/whats_new_form_factor.dart';
import '../theme/whats_new_theme.dart';
import 'whats_new_feature_row.dart';
import 'whats_new_footer.dart';
import 'whats_new_text_view.dart';

/// The What's New surface itself: a scrolling title and feature list under a
/// pinned, blur-backed footer.
///
/// Most apps present this through `showWhatsNewSheet` or `WhatsNewSheet.show`
/// rather than building it directly. Use it directly to embed the content in a
/// page of your own — an onboarding flow, or a "What's New" entry in settings.
class WhatsNewView extends StatefulWidget {
  /// Creates a What's New surface.
  const WhatsNewView({
    super.key,
    required this.whatsNew,
    this.versionStore,
    this.layout,
    this.theme,
    this.onDismissRequested,
    this.autofocusPrimaryAction = false,
  });

  /// The entry to render.
  final WhatsNew whatsNew;

  /// Where the presented version is recorded.
  ///
  /// When set, this widget records [WhatsNew.version] as it is disposed —
  /// matching WhatsNewKit, which saves in `onDisappear` and therefore records a
  /// swipe-down just as it records the primary button.
  ///
  /// The sheet helpers pass `null` here and record from the route's future
  /// instead, which avoids an unawaited write during teardown.
  final WhatsNewVersionStore? versionStore;

  /// Overrides the surface geometry.
  final WhatsNewLayout? layout;

  /// Overrides the styling.
  final WhatsNewTheme? theme;

  /// Called when the primary button asks for the surface to close.
  ///
  /// Defaults to popping the enclosing route.
  final VoidCallback? onDismissRequested;

  /// Whether the primary button takes focus on open.
  final bool autofocusPrimaryAction;

  @override
  State<WhatsNewView> createState() => _WhatsNewViewState();
}

class _WhatsNewViewState extends State<WhatsNewView> {
  @override
  void dispose() {
    final WhatsNewVersionStore? store = widget.versionStore;
    if (store != null) {
      // Fire-and-forget: the surface is going away either way, and the write
      // must happen for a swipe-down just as it does for the button.
      unawaited(store.save(widget.whatsNew.version));
    }
    super.dispose();
  }

  void _handlePrimaryPressed() {
    widget.whatsNew.primaryAction.haptic?.call();
    final VoidCallback? dismiss = widget.onDismissRequested;
    if (dismiss != null) {
      dismiss();
    } else {
      final NavigatorState navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
    widget.whatsNew.primaryAction.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    WhatsNewTheme? themeOverride = widget.theme;
    final WhatsNewLayout? layoutOverride = widget.layout;
    if (layoutOverride != null) {
      themeOverride = (themeOverride ?? const WhatsNewTheme())
          .copyWith(layout: layoutOverride);
    }
    final WhatsNewResolvedTheme theme =
        WhatsNewTheme.resolve(context, themeOverride);
    final WhatsNewLayout layout = theme.layout;

    return ColoredBox(
      color: theme.sheetBackgroundColor,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Measured from the surface, not the screen: the same widget has to
          // lay out correctly inside a narrow desktop dialog.
          final WhatsNewFormFactor formFactor = layout.breakpoints.resolve(
            constraints.biggest,
            Theme.of(context).platform,
          );

          return layout.usesTwoColumns(constraints.biggest)
              ? _buildTwoColumn(
                  context, theme, layout, formFactor, constraints.biggest)
              : _buildSingleColumn(
                  context, theme, layout, formFactor, constraints.biggest);
        },
      ),
    );
  }

  /// Title above the features, actions pinned to the bottom.
  Widget _buildSingleColumn(
    BuildContext context,
    WhatsNewResolvedTheme theme,
    WhatsNewLayout layout,
    WhatsNewFormFactor formFactor,
    Size surface,
  ) {
    final bool capped = surface.width > layout.maxContentWidth;

    return Stack(
      children: <Widget>[
        _buildScrollBody(context, theme, layout, formFactor,
            capped: capped, surface: surface),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _constrain(
            layout,
            capped: capped,
            child: WhatsNewFooter(
              whatsNew: widget.whatsNew,
              theme: theme,
              formFactor: formFactor,
              widthConstrained: capped,
              autofocusPrimary: widget.autofocusPrimaryAction,
              onPrimaryPressed: _handlePrimaryPressed,
            ),
          ),
        ),
      ],
    );
  }

  /// Title and actions beside a scrolling feature list.
  ///
  /// A landscape phone has plenty of width and almost no height, so stacking
  /// a 34pt title, a feature list and a pinned footer leaves nothing to scroll
  /// in. Splitting them uses the axis that actually has room.
  Widget _buildTwoColumn(
    BuildContext context,
    WhatsNewResolvedTheme theme,
    WhatsNewLayout layout,
    WhatsNewFormFactor formFactor,
    Size surface,
  ) {
    final EdgeInsets margin = EdgeInsets.only(
      top: layout.contentPadding.top / 2,
      left: layout.constrainedHorizontalMargin,
      right: layout.constrainedHorizontalMargin,
      bottom: layout.constrainedHorizontalMargin +
          (layout.bottomSafeAreaBehavior == WhatsNewSafeAreaBehavior.add
              ? MediaQuery.viewPaddingOf(context).bottom
              : 0),
    );

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: margin,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.twoColumnMaxWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: layout.twoColumnTitleFlex,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        WhatsNewTextView(
                          text: widget.whatsNew.title,
                          style: theme.titleStyle,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: layout.contentSpacing / 2),
                        WhatsNewFooter(
                          whatsNew: widget.whatsNew,
                          theme: theme,
                          formFactor: formFactor,
                          pinned: false,
                          autofocusPrimary: widget.autofocusPrimaryAction,
                          onPrimaryPressed: _handlePrimaryPressed,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: layout.twoColumnSpacing),
                Expanded(
                  flex: layout.twoColumnFeaturesFlex,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: layout.showsScrollBar),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _featureRows(theme, layout),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Centres [child] within [WhatsNewLayout.maxContentWidth] once the surface
  /// is wider than that.
  Widget _constrain(
    WhatsNewLayout layout, {
    required bool capped,
    required Widget child,
  }) {
    if (!capped) {
      return child;
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
        child: child,
      ),
    );
  }

  List<Widget> _featureRows(
    WhatsNewResolvedTheme theme,
    WhatsNewLayout layout,
  ) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < widget.whatsNew.features.length; index += 1) {
      if (index > 0) {
        rows.add(SizedBox(height: layout.featureListSpacing));
      }
      rows.add(
        WhatsNewFeatureRow(
          feature: widget.whatsNew.features[index],
          theme: theme,
        ),
      );
    }
    return rows;
  }

  Widget _buildScrollBody(
    BuildContext context,
    WhatsNewResolvedTheme theme,
    WhatsNewLayout layout,
    WhatsNewFormFactor formFactor, {
    required bool capped,
    required Size surface,
  }) {
    final TextDirection direction = Directionality.of(context);

    final Widget column = Padding(
      padding: layout.contentPadding.add(
        EdgeInsets.symmetric(horizontal: layout.contentHorizontalPadding),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          WhatsNewTextView(
            text: widget.whatsNew.title,
            style: theme.titleStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.contentSpacing),
          Padding(
            padding: layout
                .featuresPaddingFor(formFactor, widthConstrained: capped)
                .add(layout.featureListPadding.resolve(direction)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _featureRows(theme, layout),
            ),
          ),
        ],
      ),
    );

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context)
          .copyWith(scrollbars: layout.showsScrollBar),
      child: SingleChildScrollView(
        // WhatsNewKit appends an empty spacer of this height so the content can
        // scroll clear of the pinned footer.
        padding: EdgeInsets.only(bottom: layout.scrollBottomContentInset),
        child: !capped
            ? column
            : ConstrainedBox(
                // Fills the viewport so the content can centre in it when it
                // is shorter, while still scrolling when it is not.
                constraints: BoxConstraints(
                  minHeight: layout.centerContentWhenConstrained
                      ? math.max(
                          0,
                          surface.height - layout.scrollBottomContentInset,
                        )
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: layout.maxContentWidth),
                    child: column,
                  ),
                ),
              ),
      ),
    );
  }
}
