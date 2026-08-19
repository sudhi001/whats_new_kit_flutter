import 'package:flutter/widgets.dart';

import '../models/whats_new.dart';
import '../models/whats_new_feature.dart';
import '../models/whats_new_haptic.dart';
import '../models/whats_new_layout.dart';
import '../models/whats_new_primary_action.dart';
import '../models/whats_new_secondary_action.dart';
import '../models/whats_new_text.dart';
import '../models/whats_new_version.dart';
import '../store/whats_new_version_store.dart';
import '../theme/whats_new_theme.dart';
import '../util/app_version.dart';
import 'whats_new_presentation.dart';
import 'whats_new_sheet.dart';

/// Presents a What's New sheet.
///
/// ```dart
/// showWhatsNewSheet(
///   context,
///   version: '1.0.0',
///   title: "What's New",
///   features: <WhatsNewFeature>[
///     WhatsNewFeature(
///       icon: Icons.star,
///       title: 'Time Machine',
///       subtitle: 'Travel back in time.',
///     ),
///   ],
///   onContinue: () {},
/// );
/// ```
///
/// Colors come from `Theme.of(context)`, so the sheet follows the app's light
/// and dark schemes without configuration. Pass [accentColor] to tint one sheet
/// differently, or register a `WhatsNewTheme` extension to restyle them all.
///
/// Leave [version] unset to take the running app's version from
/// [WhatsNewAppVersion], which you configure once at startup; passing it keeps
/// the whole call synchronous up to the point the route is pushed, and means
/// [WhatsNewAppVersion] never has to be configured at all.
///
/// Nothing is remembered unless [versionStore] is given. With one, the version
/// is recorded when the sheet is dismissed, and — with [skipIfAlreadyPresented]
/// left on — a later call for the same version returns without presenting.
///
/// Pass [textDirection] to render one sheet in a specific direction, for copy
/// in a different script from the rest of the app.
///
/// The returned future completes once the sheet has been dismissed.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  String? version,
  required String title,
  required List<WhatsNewFeature> features,
  String continueLabel = 'Continue',
  VoidCallback? onContinue,
  WhatsNewSecondaryAction? secondaryAction,
  WhatsNewHaptic? continueHaptic,
  Color? accentColor,
  Color? continueBackgroundColor,
  Color? continueForegroundColor,
  WhatsNewLayout? layout,
  WhatsNewTheme? theme,
  WhatsNewVersionStore? versionStore,
  bool skipIfAlreadyPresented = true,
  WhatsNewPresentation presentation = WhatsNewPresentation.adaptive,
  WhatsNewMarkPresented markPresented = WhatsNewMarkPresented.anyDismissal,
  bool useRootNavigator = true,
  bool isDismissible = true,
  TextDirection? textDirection,
  VoidCallback? onDismiss,
}) async {
  final WhatsNewVersion resolvedVersion = version != null
      ? WhatsNewVersion.parse(version)
      : await WhatsNewAppVersion.current();

  if (!context.mounted) {
    return;
  }

  final WhatsNew whatsNew = WhatsNew(
    version: resolvedVersion,
    title: WhatsNewText(title),
    features: features,
    primaryAction: WhatsNewPrimaryAction(
      title: WhatsNewText(continueLabel),
      backgroundColor: continueBackgroundColor,
      foregroundColor: continueForegroundColor,
      haptic: continueHaptic,
      onPressed: onContinue,
    ),
    secondaryAction: secondaryAction,
  );

  final WhatsNewTheme? mergedTheme = accentColor == null
      ? theme
      : (theme ?? const WhatsNewTheme()).copyWith(accentColor: accentColor);

  return WhatsNewSheet.show(
    context,
    whatsNew: whatsNew,
    versionStore: versionStore,
    layout: layout,
    theme: mergedTheme,
    skipIfAlreadyPresented: skipIfAlreadyPresented,
    presentation: presentation,
    markPresented: markPresented,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    textDirection: textDirection,
    onDismiss: onDismiss,
  );
}
