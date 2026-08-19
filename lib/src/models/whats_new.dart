import 'package:flutter/widgets.dart';

import 'whats_new_feature.dart';
import 'whats_new_primary_action.dart';
import 'whats_new_secondary_action.dart';
import 'whats_new_text.dart';
import 'whats_new_version.dart';

/// Everything shown for one release: a version, a title, some features and up
/// to two actions.
@immutable
class WhatsNew {
  /// Creates a What's New entry.
  const WhatsNew({
    required this.version,
    required this.title,
    required this.features,
    this.primaryAction = const WhatsNewPrimaryAction(),
    this.secondaryAction,
  });

  /// Creates a What's New entry from plain strings.
  ///
  /// ```dart
  /// WhatsNew.of(
  ///   version: '1.2.0',
  ///   title: "What's New",
  ///   features: <WhatsNewFeature>[...],
  /// )
  /// ```
  factory WhatsNew.of({
    required String version,
    required String title,
    required List<WhatsNewFeature> features,
    WhatsNewPrimaryAction primaryAction = const WhatsNewPrimaryAction(),
    WhatsNewSecondaryAction? secondaryAction,
  }) {
    return WhatsNew(
      version: WhatsNewVersion.parse(version),
      title: WhatsNewText(title),
      features: features,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
    );
  }

  /// The release this entry describes.
  final WhatsNewVersion version;

  /// The large title at the top of the sheet.
  final WhatsNewText title;

  /// The rows shown below the title.
  final List<WhatsNewFeature> features;

  /// The full-width button that closes the sheet.
  final WhatsNewPrimaryAction primaryAction;

  /// An optional text link shown above the primary button.
  final WhatsNewSecondaryAction? secondaryAction;

  /// Returns a copy of this entry with the given fields replaced.
  WhatsNew copyWith({
    WhatsNewVersion? version,
    WhatsNewText? title,
    List<WhatsNewFeature>? features,
    WhatsNewPrimaryAction? primaryAction,
    WhatsNewSecondaryAction? secondaryAction,
  }) {
    return WhatsNew(
      version: version ?? this.version,
      title: title ?? this.title,
      features: features ?? this.features,
      primaryAction: primaryAction ?? this.primaryAction,
      secondaryAction: secondaryAction ?? this.secondaryAction,
    );
  }
}

/// Declares the What's New entries an app ships with.
///
/// WhatsNewKit uses a Swift result builder here; in Dart a plain list plus
/// collection-`if` and spreads covers the same ground:
///
/// ```dart
/// class MyApp with WhatsNewCollectionProvider {
///   @override
///   List<WhatsNew> get whatsNewCollection => <WhatsNew>[
///         whatsNew_1_0_0,
///         if (kDebugMode) whatsNew_1_1_0_beta,
///         ...archivedReleases,
///       ];
/// }
/// ```
mixin WhatsNewCollectionProvider {
  /// The entries this app ships with, one per release.
  List<WhatsNew> get whatsNewCollection;
}
