import 'package:flutter/widgets.dart';

import '../models/whats_new_text.dart';
import '../theme/whats_new_resolved_theme.dart';
import 'whats_new_text_view.dart';

/// The full-width button at the bottom of a What's New sheet.
///
/// Deliberately not built on Material's buttons: WhatsNewKit's style is a flat
/// rounded rectangle whose only press feedback is an opacity drop, with no ink
/// ripple, no elevation and no animation curve.
class WhatsNewPrimaryButton extends StatefulWidget {
  /// Creates a primary button.
  const WhatsNewPrimaryButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.theme,
    required this.backgroundColor,
    required this.onPressed,
    this.autofocus = false,
  });

  /// The button's label.
  final WhatsNewText label;

  /// What screen readers announce.
  final String semanticsLabel;

  /// The resolved styling.
  final WhatsNewResolvedTheme theme;

  /// The button's fill.
  final Color backgroundColor;

  /// Runs when the button is activated by tap or keyboard.
  final VoidCallback onPressed;

  /// Whether the button takes focus when the sheet opens.
  ///
  /// Mirrors WhatsNewKit's `.keyboardShortcut(.defaultAction)` on macOS.
  final bool autofocus;

  @override
  State<WhatsNewPrimaryButton> createState() => _WhatsNewPrimaryButtonState();
}

class _WhatsNewPrimaryButtonState extends State<WhatsNewPrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WhatsNewResolvedTheme theme = widget.theme;

    // Merged so the label, the button flag and the focusability arrive as a
    // single node; otherwise a screen reader meets an unlabelled focus node
    // sitting beside the labelled one.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: widget.semanticsLabel,
        onTap: widget.onPressed,
        child: FocusableActionDetector(
          autofocus: widget.autofocus,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails _) => _setPressed(true),
            onTapUp: (TapUpDetails _) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onPressed,
            // The label is supplied by the Semantics above; without this a
            // screen reader would announce it twice. The focus semantics from
            // FocusableActionDetector sit outside this and are left intact.
            child: ExcludeSemantics(
              child: Opacity(
                opacity: _pressed ? theme.pressedOpacity : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(
                      theme.layout.footerPrimaryButtonCornerRadius,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: double.infinity,
                      minHeight: theme.layout.minTapTargetSize,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical:
                            theme.layout.footerPrimaryButtonVerticalPadding,
                      ),
                      child: WhatsNewTextView(
                        text: widget.label,
                        style: theme.primaryButtonTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The optional text link shown above the primary button.
class WhatsNewSecondaryButton extends StatefulWidget {
  /// Creates a secondary button.
  const WhatsNewSecondaryButton({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.theme,
    required this.onPressed,
    this.isLink = false,
  });

  /// The link's label.
  final WhatsNewText label;

  /// What screen readers announce.
  final String semanticsLabel;

  /// The resolved styling.
  final WhatsNewResolvedTheme theme;

  /// Runs when the link is activated.
  final VoidCallback onPressed;

  /// Whether this action opens a URL, which screen readers announce
  /// differently from an in-app button.
  final bool isLink;

  @override
  State<WhatsNewSecondaryButton> createState() =>
      _WhatsNewSecondaryButtonState();
}

class _WhatsNewSecondaryButtonState extends State<WhatsNewSecondaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        link: widget.isLink,
        label: widget.semanticsLabel,
        onTap: widget.onPressed,
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails _) => _setPressed(true),
            onTapUp: (TapUpDetails _) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onPressed,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: _pressed ? widget.theme.pressedOpacity : 1,
                // A bare text link is about 22pt tall; Apple asks for 44pt of
                // tappable area, so it is padded out without moving the text.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: widget.theme.layout.minTapTargetSize,
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: WhatsNewTextView(
                      text: widget.label,
                      style: widget.theme.secondaryButtonTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
