import 'package:flutter/widgets.dart';

import '../models/whats_new.dart';
import '../models/whats_new_layout.dart';
import '../models/whats_new_secondary_action.dart';
import '../theme/whats_new_form_factor.dart';
import '../theme/whats_new_resolved_theme.dart';
import 'whats_new_blur_background.dart';
import 'whats_new_primary_button.dart';

/// The pinned actions at the bottom of a What's New sheet.
class WhatsNewFooter extends StatelessWidget {
  /// Creates a footer.
  const WhatsNewFooter({
    super.key,
    required this.whatsNew,
    required this.theme,
    required this.formFactor,
    required this.onPrimaryPressed,
    this.autofocusPrimary = false,
    this.pinned = true,
    this.widthConstrained = false,
  });

  /// The entry being shown.
  final WhatsNew whatsNew;

  /// The resolved styling.
  final WhatsNewResolvedTheme theme;

  /// Which padding set to use.
  final WhatsNewFormFactor formFactor;

  /// Runs when the primary button is activated.
  final VoidCallback onPrimaryPressed;

  /// Whether the primary button takes focus when the sheet opens.
  final bool autofocusPrimary;

  /// Whether this footer is pinned over scrolling content.
  ///
  /// A pinned footer gets the blurred backdrop and the responsive bottom
  /// inset. Laid out inline — as the two-column arrangement does — it needs
  /// neither.
  final bool pinned;

  /// Whether the footer is already capped by `maxContentWidth`.
  final bool widthConstrained;

  @override
  Widget build(BuildContext context) {
    final WhatsNewLayout layout = theme.layout;
    final WhatsNewSecondaryAction? secondary = whatsNew.secondaryAction;

    // Per-instance action colors win over the resolved theme.
    final Color? primaryForeground = whatsNew.primaryAction.foregroundColor;
    final WhatsNewResolvedTheme primaryTheme = primaryForeground == null
        ? theme
        : theme.copyWith(
            primaryButtonForegroundColor: primaryForeground,
            primaryButtonTextStyle:
                theme.primaryButtonTextStyle.copyWith(color: primaryForeground),
          );
    final WhatsNewResolvedTheme secondaryTheme =
        secondary?.foregroundColor == null
            ? theme
            : theme.copyWith(
                secondaryButtonTextStyle: theme.secondaryButtonTextStyle
                    .copyWith(color: secondary!.foregroundColor),
              );

    EdgeInsets padding = pinned
        ? layout.footerPaddingFor(formFactor,
            widthConstrained: widthConstrained)
        : EdgeInsets.zero;
    if (pinned &&
        layout.bottomSafeAreaBehavior == WhatsNewSafeAreaBehavior.add) {
      padding = padding.copyWith(
        bottom: padding.bottom + MediaQuery.viewPaddingOf(context).bottom,
      );
    }

    final Widget actions = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (secondary != null) ...<Widget>[
            WhatsNewSecondaryButton(
              label: secondary.title,
              semanticsLabel: secondary.title.plainText,
              theme: secondaryTheme,
              isLink: secondary.isLink,
              onPressed: () {
                secondary.haptic?.call();
                secondary.onPressed(WhatsNewActionContext(context));
              },
            ),
            SizedBox(height: layout.footerActionSpacing),
          ],
          WhatsNewPrimaryButton(
            label: whatsNew.primaryAction.title,
            semanticsLabel: whatsNew.primaryAction.title.plainText,
            theme: primaryTheme,
            backgroundColor: whatsNew.primaryAction.backgroundColor ??
                theme.primaryButtonBackgroundColor,
            autofocus: autofocusPrimary,
            onPressed: onPrimaryPressed,
          ),
        ],
      ),
    );

    if (!pinned) {
      return actions;
    }

    return WhatsNewBlurBackground(
      bleedTop: layout.footerBlurBleed,
      sigma: theme.footerBlurSigma,
      scrim: theme.footerScrimColor,
      mode: layout.footerBackground,
      respectHighContrast: layout.respectHighContrast,
      child: actions,
    );
  }
}
