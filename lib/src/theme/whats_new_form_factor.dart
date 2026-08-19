import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The layout bucket a What's New surface falls into.
///
/// These are the Flutter equivalents of the UIKit size classes that
/// WhatsNewKit branches on when choosing its paddings.
enum WhatsNewFormFactor {
  /// A phone in portrait — UIKit's compact width, regular height.
  compact,

  /// A phone in landscape — UIKit's compact vertical size class.
  compactLandscape,

  /// A tablet, or any surface at least [WhatsNewBreakpoints.regularWidth] wide.
  regular,

  /// A desktop window, where WhatsNewKit compiles its `#if os(macOS)` branch.
  desktop,
}

/// The size thresholds used to pick a [WhatsNewFormFactor].
@immutable
class WhatsNewBreakpoints {
  /// Creates a set of breakpoints.
  const WhatsNewBreakpoints({
    this.regularWidth = 600,
    this.compactHeight = 500,
    this.desktopMinWidth = 900,
    this.useShortestSide = false,
  });

  /// The width at or above which a surface counts as [WhatsNewFormFactor.regular].
  ///
  /// 600 reproduces UIKit's regular width class well: iPads and Max-class
  /// iPhones in landscape both land here, matching iOS.
  final double regularWidth;

  /// The height below which a surface counts as
  /// [WhatsNewFormFactor.compactLandscape].
  final double compactHeight;

  /// The width at or above which a desktop platform uses the macOS paddings.
  final double desktopMinWidth;

  /// Whether to test [Size.shortestSide] rather than width against
  /// [regularWidth].
  ///
  /// Enable this for stricter parity with Apple's size classes, where a
  /// standard (non-Max) iPhone stays compact even in landscape.
  final bool useShortestSide;

  /// Resolves the form factor for a surface of [size] on [platform].
  ///
  /// The branch order mirrors WhatsNewKit's: regular width is tested before
  /// compact height, so a landscape tablet is [WhatsNewFormFactor.regular]
  /// rather than [WhatsNewFormFactor.compactLandscape].
  WhatsNewFormFactor resolve(Size size, TargetPlatform platform) {
    if (_isDesktop(platform) && size.width >= desktopMinWidth) {
      return WhatsNewFormFactor.desktop;
    }
    final double widthMetric = useShortestSide ? size.shortestSide : size.width;
    if (widthMetric >= regularWidth) {
      return WhatsNewFormFactor.regular;
    }
    if (size.height < compactHeight) {
      return WhatsNewFormFactor.compactLandscape;
    }
    return WhatsNewFormFactor.compact;
  }

  static bool _isDesktop(TargetPlatform platform) =>
      isDesktopPlatform(platform);

  /// Returns a copy of these breakpoints with the given fields replaced.
  WhatsNewBreakpoints copyWith({
    double? regularWidth,
    double? compactHeight,
    double? desktopMinWidth,
    bool? useShortestSide,
  }) {
    return WhatsNewBreakpoints(
      regularWidth: regularWidth ?? this.regularWidth,
      compactHeight: compactHeight ?? this.compactHeight,
      desktopMinWidth: desktopMinWidth ?? this.desktopMinWidth,
      useShortestSide: useShortestSide ?? this.useShortestSide,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewBreakpoints &&
          other.regularWidth == regularWidth &&
          other.compactHeight == compactHeight &&
          other.desktopMinWidth == desktopMinWidth &&
          other.useShortestSide == useShortestSide;

  @override
  int get hashCode => Object.hash(
      regularWidth, compactHeight, desktopMinWidth, useShortestSide);
}

/// Whether [platform] is a desktop operating system.
///
/// Web is excluded: a wide browser window is not a desktop app, and the
/// presentation rules differ.
bool isDesktopPlatform(TargetPlatform platform) =>
    !kIsWeb &&
    (platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux);
