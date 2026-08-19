import 'package:flutter/widgets.dart';

import 'whats_new_haptic.dart';
import 'whats_new_text.dart';

/// The full-width button that closes a What's New sheet.
@immutable
class WhatsNewPrimaryAction {
  /// Creates a primary action. The defaults match WhatsNewKit's.
  const WhatsNewPrimaryAction({
    this.title = const WhatsNewText('Continue'),
    this.backgroundColor,
    this.foregroundColor,
    this.haptic,
    this.onPressed,
  });

  /// The button's label.
  final WhatsNewText title;

  /// The button's fill. Defaults to the resolved accent color.
  final Color? backgroundColor;

  /// The label color. Defaults to `ColorScheme.onPrimary`.
  final Color? foregroundColor;

  /// Feedback played the moment the button is tapped.
  final WhatsNewHaptic? haptic;

  /// Called after the sheet has been dismissed by this button.
  ///
  /// This fires *only* for a tap on the primary button — not for a swipe-down
  /// or a back gesture. For a callback that runs on any dismissal, use the
  /// `onDismiss` argument of `showWhatsNewSheet` or `WhatsNewSheet.show`.
  final VoidCallback? onPressed;

  /// Returns a copy of this action with the given fields replaced.
  WhatsNewPrimaryAction copyWith({
    WhatsNewText? title,
    Color? backgroundColor,
    Color? foregroundColor,
    WhatsNewHaptic? haptic,
    VoidCallback? onPressed,
  }) {
    return WhatsNewPrimaryAction(
      title: title ?? this.title,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      haptic: haptic ?? this.haptic,
      onPressed: onPressed ?? this.onPressed,
    );
  }
}
