import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'whats_new_haptic.dart';
import 'whats_new_text.dart';

/// Handed to a secondary action's callback so it can drive the sheet.
///
/// This is the Flutter equivalent of the `Binding<PresentationMode>` that
/// WhatsNewKit passes to a custom secondary action.
class WhatsNewActionContext {
  /// Creates an action context bound to [context].
  const WhatsNewActionContext(this.context);

  /// The build context of the button that was tapped.
  final BuildContext context;

  /// Closes the What's New sheet.
  void dismiss() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Presents [builder] as a sheet on top of the What's New sheet.
  Future<T?> present<T>(WidgetBuilder builder) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: builder,
    );
  }
}

/// Called when the secondary action is tapped.
typedef WhatsNewActionCallback = FutureOr<void> Function(
  WhatsNewActionContext action,
);

/// The optional text link shown above the primary button.
@immutable
class WhatsNewSecondaryAction {
  /// Creates a secondary action with a custom callback.
  const WhatsNewSecondaryAction({
    required this.title,
    this.foregroundColor,
    this.haptic,
    required this.onPressed,
  });

  /// Creates a secondary action that opens [url] in the platform browser.
  factory WhatsNewSecondaryAction.openUrl({
    required String title,
    required Uri url,
    LaunchMode mode = LaunchMode.platformDefault,
    Color? foregroundColor,
    WhatsNewHaptic? haptic,
  }) {
    return WhatsNewSecondaryAction(
      title: WhatsNewText(title),
      foregroundColor: foregroundColor,
      haptic: haptic,
      onPressed: (WhatsNewActionContext action) async {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: mode);
        }
      },
    );
  }

  /// Creates a secondary action that simply closes the sheet.
  factory WhatsNewSecondaryAction.dismiss({
    required String title,
    Color? foregroundColor,
    WhatsNewHaptic? haptic,
  }) {
    return WhatsNewSecondaryAction(
      title: WhatsNewText(title),
      foregroundColor: foregroundColor,
      haptic: haptic,
      onPressed: (WhatsNewActionContext action) => action.dismiss(),
    );
  }

  /// Creates a secondary action that presents [builder] on top of the sheet.
  factory WhatsNewSecondaryAction.present({
    required String title,
    required WidgetBuilder builder,
    Color? foregroundColor,
    WhatsNewHaptic? haptic,
  }) {
    return WhatsNewSecondaryAction(
      title: WhatsNewText(title),
      foregroundColor: foregroundColor,
      haptic: haptic,
      onPressed: (WhatsNewActionContext action) =>
          action.present<void>(builder),
    );
  }

  /// The link's label.
  final WhatsNewText title;

  /// The label color. Defaults to the resolved accent color.
  final Color? foregroundColor;

  /// Feedback played the moment the link is tapped.
  final WhatsNewHaptic? haptic;

  /// Runs when the link is tapped.
  final WhatsNewActionCallback onPressed;
}
