import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../models/whats_new_layout.dart';

/// The backdrop drawn behind the footer.
///
/// WhatsNewKit gives its visual effect view a *negative* top padding, so the
/// blur extends above the footer and softens the content scrolling underneath.
/// [bleedTop] reproduces that overhang.
class WhatsNewBlurBackground extends StatelessWidget {
  /// Creates a footer backdrop.
  const WhatsNewBlurBackground({
    super.key,
    required this.child,
    required this.bleedTop,
    required this.sigma,
    required this.scrim,
    this.mode = WhatsNewFooterBackground.blur,
    this.respectHighContrast = true,
  });

  /// The footer itself, which sizes this widget.
  final Widget child;

  /// How far the backdrop extends above [child].
  final double bleedTop;

  /// The blur radius.
  final double sigma;

  /// The translucent fill drawn over the blur.
  final Color scrim;

  /// How the backdrop is drawn.
  final WhatsNewFooterBackground mode;

  /// Whether a high-contrast preference downgrades [mode] to a solid fill.
  final bool respectHighContrast;

  @override
  Widget build(BuildContext context) {
    if (mode == WhatsNewFooterBackground.none) {
      return child;
    }

    // Reduce Transparency on Apple platforms, and the equivalent elsewhere:
    // a translucent bar over moving content is what that setting removes.
    final bool blurred = mode == WhatsNewFooterBackground.blur &&
        !(respectHighContrast && MediaQuery.highContrastOf(context));

    // A ClipRect is mandatory: without an enclosing clip a BackdropFilter
    // samples the entire layer rather than just the area behind the footer.
    final Widget backdrop = ClipRect(
      child: blurred
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: ColoredBox(color: scrim),
            )
          // Opaque, so the text over it stays legible without the blur.
          : ColoredBox(
              color: Color.alphaBlend(scrim, scrim.withValues(alpha: 1))),
    );

    return Stack(
      // Clip.none lets the backdrop overhang the footer's own bounds.
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: -bleedTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: backdrop,
        ),
        child,
      ],
    );
  }
}
