/// An Apple-style "What's New" sheet for Flutter.
///
/// A faithful port of [WhatsNewKit](https://github.com/SvenTiigi/WhatsNewKit),
/// with a Flutter-idiomatic API and colors derived from `Theme.of(context)`.
///
/// The short version:
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
/// To show one sheet per release automatically, give a [WhatsNewController] the
/// entries your app ships with and install a [WhatsNewAutoSheet].
library;

export 'src/controller/whats_new_auto_sheet.dart';
export 'src/controller/whats_new_controller.dart';
export 'src/controller/whats_new_scope.dart';
export 'src/models/whats_new.dart';
export 'src/models/whats_new_feature.dart';
export 'src/models/whats_new_haptic.dart';
export 'src/models/whats_new_image.dart';
export 'src/models/whats_new_layout.dart';
export 'src/models/whats_new_primary_action.dart';
export 'src/models/whats_new_secondary_action.dart';
export 'src/models/whats_new_text.dart';
export 'src/models/whats_new_version.dart';
export 'src/presentation/show_whats_new_sheet.dart';
export 'src/presentation/whats_new_presentation.dart';
export 'src/presentation/whats_new_sheet.dart';
export 'src/store/caching_store.dart';
export 'src/store/in_memory_store.dart';
export 'src/store/shared_preferences_store.dart';
export 'src/store/whats_new_version_store.dart';
export 'src/text/inline_markdown.dart';
export 'src/theme/whats_new_form_factor.dart';
export 'src/theme/whats_new_resolved_theme.dart';
export 'src/theme/whats_new_theme.dart';
export 'src/util/app_version.dart';
export 'src/view/whats_new_text_view.dart';
export 'src/view/whats_new_view.dart';
