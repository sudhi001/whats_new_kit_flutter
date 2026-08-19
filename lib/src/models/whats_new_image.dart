import 'package:flutter/widgets.dart';

import '../theme/whats_new_resolved_theme.dart';

/// The artwork shown beside a feature.
///
/// WhatsNewKit renders an SF Symbol at `.font(.title)` with `.imageScale(.large)`
/// in the accent color; [WhatsNewImage.icon] is the direct equivalent. The other
/// variants cover bundled artwork and arbitrary widgets.
@immutable
sealed class WhatsNewImage {
  const WhatsNewImage();

  /// An icon, tinted with the accent color unless [color] is given.
  const factory WhatsNewImage.icon(
    IconData icon, {
    Color? color,
    double? size,
  }) = IconWhatsNewImage;

  /// A bundled image asset.
  const factory WhatsNewImage.asset(
    String name, {
    String? package,
    Color? color,
    double? size,
  }) = AssetWhatsNewImage;

  /// An arbitrary widget, for SVGs, animations or anything else.
  const factory WhatsNewImage.widget(Widget child) = WidgetWhatsNewImage;

  /// Builds the artwork, sized and tinted from [theme].
  Widget build(BuildContext context, WhatsNewResolvedTheme theme);
}

/// An icon. See [WhatsNewImage.icon].
class IconWhatsNewImage extends WhatsNewImage {
  /// Creates an icon image.
  const IconWhatsNewImage(this.icon, {this.color, this.size});

  /// The icon to draw.
  final IconData icon;

  /// The tint. Defaults to the resolved accent color.
  final Color? color;

  /// The rendered size. Defaults to `WhatsNewLayout.featureImageSize`.
  final double? size;

  @override
  Widget build(BuildContext context, WhatsNewResolvedTheme theme) {
    return Icon(
      icon,
      size: size ?? theme.layout.featureImageSize,
      color: color ?? theme.accentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IconWhatsNewImage &&
          other.icon == icon &&
          other.color == color &&
          other.size == size;

  @override
  int get hashCode => Object.hash(icon, color, size);
}

/// A bundled asset. See [WhatsNewImage.asset].
class AssetWhatsNewImage extends WhatsNewImage {
  /// Creates an asset image.
  const AssetWhatsNewImage(this.name, {this.package, this.color, this.size});

  /// The asset key.
  final String name;

  /// The package the asset lives in, if not the host app.
  final String? package;

  /// A tint applied to the asset. Leave null to draw it unmodified.
  final Color? color;

  /// The rendered size. Defaults to `WhatsNewLayout.featureImageSize`.
  final double? size;

  @override
  Widget build(BuildContext context, WhatsNewResolvedTheme theme) {
    final double resolvedSize = size ?? theme.layout.featureImageSize;
    return Image.asset(
      name,
      package: package,
      width: resolvedSize,
      height: resolvedSize,
      color: color,
      fit: BoxFit.contain,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetWhatsNewImage &&
          other.name == name &&
          other.package == package &&
          other.color == color &&
          other.size == size;

  @override
  int get hashCode => Object.hash(name, package, color, size);
}

/// An arbitrary widget. See [WhatsNewImage.widget].
class WidgetWhatsNewImage extends WhatsNewImage {
  /// Creates a widget image.
  const WidgetWhatsNewImage(this.child);

  /// The widget to draw.
  final Widget child;

  @override
  Widget build(BuildContext context, WhatsNewResolvedTheme theme) => child;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetWhatsNewImage && other.child == child;

  @override
  int get hashCode => child.hashCode;
}
