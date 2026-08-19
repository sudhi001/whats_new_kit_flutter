import 'package:flutter/widgets.dart';

import 'whats_new_image.dart';
import 'whats_new_text.dart';

/// One row of a What's New sheet: artwork, a title and a subtitle.
@immutable
class WhatsNewFeature {
  /// Creates a feature from an icon and two plain strings.
  ///
  /// This is the common case:
  ///
  /// ```dart
  /// WhatsNewFeature(
  ///   icon: Icons.star,
  ///   title: 'Time Machine',
  ///   subtitle: 'Travel back in time.',
  /// )
  /// ```
  ///
  /// Pass [iconColor] to tint one row differently from the accent color. For
  /// artwork other than an icon, or for styled text, use
  /// [WhatsNewFeature.rich].
  WhatsNewFeature({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
  })  : image = WhatsNewImage.icon(icon, color: iconColor),
        title = WhatsNewText(title),
        subtitle = WhatsNewText(subtitle);

  /// Creates a feature from fully specified parts.
  const WhatsNewFeature.rich({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  /// The artwork shown in the leading column.
  final WhatsNewImage image;

  /// The feature's headline.
  final WhatsNewText title;

  /// The feature's supporting copy.
  final WhatsNewText subtitle;

  /// Returns a copy of this feature with the given fields replaced.
  WhatsNewFeature copyWith({
    WhatsNewImage? image,
    WhatsNewText? title,
    WhatsNewText? subtitle,
  }) {
    return WhatsNewFeature.rich(
      image: image ?? this.image,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewFeature &&
          other.image == image &&
          other.title == title &&
          other.subtitle == subtitle;

  @override
  int get hashCode => Object.hash(image, title, subtitle);
}
