import 'package:flutter/material.dart';

import 'whats_new_haptic.dart';
import 'whats_new_text.dart';

/// The full-width button that closes a What's New sheet.
@immutable
class WhatsNewPrimaryAction {
  /// Creates a primary action. The defaults match WhatsNewKit's.
  const WhatsNewPrimaryAction({
    this.title,
    this.backgroundColor,
    this.foregroundColor,
    this.haptic,
    this.onPressed,
  });

  /// The button's label.
  ///
  /// Leave this unset to use the platform's own translated "Continue" — see
  /// [resolveTitle]. Set it to say something else, in which case localizing it
  /// is yours to do.
  final WhatsNewText? title;

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

  /// The label to render, falling back to the ambient localizations.
  ///
  /// WhatsNewKit hardcodes "Continue"; so did this package, in two places.
  /// Flutter already ships that word translated into every locale
  /// [MaterialLocalizations] supports, so the default comes from there rather
  /// than from a string literal. English is used only when there are no
  /// Material localizations above [context] at all.
  WhatsNewText resolveTitle(BuildContext context) {
    final WhatsNewText? explicit = title;
    if (explicit != null) {
      return explicit;
    }
    final MaterialLocalizations? localizations =
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    return WhatsNewText(localizations?.continueButtonLabel ?? 'Continue');
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WhatsNewPrimaryAction &&
        other.title == title &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.haptic == haptic &&
        other.onPressed == onPressed;
  }

  @override
  int get hashCode => Object.hash(
        title,
        backgroundColor,
        foregroundColor,
        haptic,
        onPressed,
      );
}
