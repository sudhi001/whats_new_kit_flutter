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

  @override
  Widget build(BuildContext context) {
    if (mode == WhatsNewFooterBackground.none) {
      return child;
    }

    // A ClipRect is mandatory: without an enclosing clip a BackdropFilter
    // samples the entire layer rather than just the area behind the footer.
    final Widget backdrop = ClipRect(
      child: mode == WhatsNewFooterBackground.blur
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: ColoredBox(color: scrim),
            )
          : ColoredBox(color: scrim),
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
