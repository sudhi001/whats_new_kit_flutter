import 'package:flutter/services.dart';

/// The strength of an impact haptic.
enum WhatsNewImpactStyle {
  /// A light collision.
  light,

  /// A moderate collision. The default.
  medium,

  /// A forceful collision.
  heavy,

  /// A crisp, precise collision. Mapped to [heavy] on Flutter.
  rigid,

  /// A gentle, diffuse collision. Mapped to [light] on Flutter.
  soft,
}

/// The meaning of a notification haptic.
enum WhatsNewNotificationKind {
  /// A task completed successfully.
  success,

  /// A task completed with a caveat.
  warning,

  /// A task failed.
  error,
}

/// Haptic feedback played when a What's New action is tapped.
///
/// Flutter's [HapticFeedback] exposes fewer generators than UIKit, so two
/// mappings are approximate: impact intensity is not supported at all, and
/// every [WhatsNewHaptic.notification] plays a medium impact. The notification
/// variants are still modelled so a native-channel override stays a drop-in.
sealed class WhatsNewHaptic {
  const WhatsNewHaptic();

  /// A collision of the given [style].
  const factory WhatsNewHaptic.impact([WhatsNewImpactStyle style]) =
      WhatsNewImpactHaptic;

  /// A selection change.
  const factory WhatsNewHaptic.selection() = WhatsNewSelectionHaptic;

  /// The outcome of a task.
  const factory WhatsNewHaptic.notification([WhatsNewNotificationKind kind]) =
      WhatsNewNotificationHaptic;

  /// Plays this feedback.
  ///
  /// Named `call` so a haptic can be invoked directly — `haptic()` — mirroring
  /// the Swift original's `callAsFunction()`.
  Future<void> call();
}

/// A collision haptic. See [WhatsNewHaptic.impact].
class WhatsNewImpactHaptic extends WhatsNewHaptic {
  /// Creates an impact haptic.
  const WhatsNewImpactHaptic([this.style = WhatsNewImpactStyle.medium]);

  /// The strength of the collision.
  final WhatsNewImpactStyle style;

  @override
  Future<void> call() {
    switch (style) {
      case WhatsNewImpactStyle.light:
      case WhatsNewImpactStyle.soft:
        return HapticFeedback.lightImpact();
      case WhatsNewImpactStyle.medium:
        return HapticFeedback.mediumImpact();
      case WhatsNewImpactStyle.heavy:
      case WhatsNewImpactStyle.rigid:
        return HapticFeedback.heavyImpact();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewImpactHaptic && other.style == style;

  @override
  int get hashCode => style.hashCode;
}

/// A selection haptic. See [WhatsNewHaptic.selection].
class WhatsNewSelectionHaptic extends WhatsNewHaptic {
  /// Creates a selection haptic.
  const WhatsNewSelectionHaptic();

  @override
  Future<void> call() => HapticFeedback.selectionClick();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WhatsNewSelectionHaptic;

  @override
  int get hashCode => (WhatsNewSelectionHaptic).hashCode;
}

/// A notification haptic. See [WhatsNewHaptic.notification].
class WhatsNewNotificationHaptic extends WhatsNewHaptic {
  /// Creates a notification haptic.
  const WhatsNewNotificationHaptic(
      [this.kind = WhatsNewNotificationKind.success]);

  /// The outcome being reported.
  final WhatsNewNotificationKind kind;

  @override
  Future<void> call() => HapticFeedback.mediumImpact();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewNotificationHaptic && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;
}
