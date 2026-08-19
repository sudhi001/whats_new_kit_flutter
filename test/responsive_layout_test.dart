import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

void main() {
  const WhatsNewBreakpoints breakpoints = WhatsNewBreakpoints();
  const WhatsNewLayout layout = WhatsNewLayout.standard;

  group('form factors', () {
    test('a phone in portrait is compact', () {
      expect(
        breakpoints.resolve(const Size(393, 852), TargetPlatform.iOS),
        WhatsNewFormFactor.compact,
      );
    });

    test('a narrow phone in landscape is compactLandscape', () {
      expect(
        breakpoints.resolve(const Size(568, 320), TargetPlatform.iOS),
        WhatsNewFormFactor.compactLandscape,
      );
    });

    test('a tablet is regular', () {
      expect(
        breakpoints.resolve(const Size(1024, 1366), TargetPlatform.iOS),
        WhatsNewFormFactor.regular,
      );
    });

    test('width wins over height, as it does in WhatsNewKit', () {
      // A wide, short surface is regular rather than compactLandscape: the
      // Swift original tests the horizontal size class first.
      expect(
        breakpoints.resolve(const Size(900, 400), TargetPlatform.iOS),
        WhatsNewFormFactor.regular,
      );
    });

    test('a wide desktop window is desktop', () {
      expect(
        breakpoints.resolve(const Size(1200, 800), TargetPlatform.macOS),
        WhatsNewFormFactor.desktop,
      );
    });

    test('a narrow desktop window falls back to a mobile bucket', () {
      expect(
        breakpoints.resolve(const Size(700, 800), TargetPlatform.macOS),
        WhatsNewFormFactor.regular,
      );
    });

    test('useShortestSide keeps a standard phone compact in landscape', () {
      const WhatsNewBreakpoints strict =
          WhatsNewBreakpoints(useShortestSide: true);
      expect(
        strict.resolve(const Size(852, 393), TargetPlatform.iOS),
        WhatsNewFormFactor.compactLandscape,
      );
    });
  });

  group('padding tables match WhatsNewKit', () {
    test('phone portrait', () {
      expect(
        layout.featuresPaddingFor(WhatsNewFormFactor.compact),
        EdgeInsets.zero,
      );
      expect(
        layout.footerPaddingFor(WhatsNewFormFactor.compact),
        const EdgeInsets.fromLTRB(20, 0, 20, 80),
      );
    });

    test('phone landscape', () {
      expect(
        layout.featuresPaddingFor(WhatsNewFormFactor.compactLandscape),
        EdgeInsets.zero,
      );
      expect(
        layout.footerPaddingFor(WhatsNewFormFactor.compactLandscape),
        const EdgeInsets.fromLTRB(40, 0, 40, 35),
      );
    });

    test('tablet', () {
      expect(
        layout.featuresPaddingFor(WhatsNewFormFactor.regular),
        const EdgeInsets.symmetric(horizontal: 100),
      );
      expect(
        layout.footerPaddingFor(WhatsNewFormFactor.regular),
        const EdgeInsets.fromLTRB(150, 0, 150, 50),
      );
    });

    test('desktop', () {
      expect(
        layout.featuresPaddingFor(WhatsNewFormFactor.desktop),
        const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(
        layout.footerPaddingFor(WhatsNewFormFactor.desktop),
        const EdgeInsets.only(bottom: 30),
      );
    });

    test('a resolver overrides the table', () {
      const WhatsNewLayout custom = WhatsNewLayout(
        footerPaddingResolver: _flatFooterPadding,
      );
      expect(
        custom.footerPaddingFor(WhatsNewFormFactor.compact),
        const EdgeInsets.all(8),
      );
    });
  });

  group('layout defaults match WhatsNewKit', () {
    test('every geometry constant', () {
      expect(layout.showsScrollBar, isFalse);
      expect(layout.scrollBottomContentInset, 150);
      expect(layout.contentSpacing, 60);
      expect(layout.contentPadding, const EdgeInsets.only(top: 65));
      expect(layout.contentHorizontalPadding, 16);
      expect(layout.featureListSpacing, 25);
      expect(
        layout.featureListPadding,
        const EdgeInsetsDirectional.only(start: 15),
      );
      expect(layout.featureImageWidth, 40);
      expect(layout.featureHorizontalSpacing, 15);
      expect(layout.featureVerticalSpacing, 2);
      expect(layout.footerActionSpacing, 15);
      expect(layout.footerPrimaryButtonCornerRadius, 14);
      expect(layout.footerBlurBleed, 10);
    });
  });
}

EdgeInsets _flatFooterPadding(WhatsNewFormFactor formFactor) =>
    const EdgeInsets.all(8);
