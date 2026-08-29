import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_feature_row.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_footer.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// A sheet with a secondary action — the case where the footer outgrows
/// `scrollBottomContentInset`, and the one the README, the example app and the
/// goldens all use.
WhatsNew _sample({int featureCount = 8, bool secondaryAction = true}) {
  return WhatsNew(
    version: const WhatsNewVersion(1, 0, 0),
    title: const WhatsNewText("What's New"),
    features: <WhatsNewFeature>[
      for (int index = 0; index < featureCount; index += 1)
        WhatsNewFeature(
          icon: Icons.star,
          title: 'Feature $index',
          subtitle: 'The supporting copy for feature number $index.',
        ),
    ],
    secondaryAction: secondaryAction
        ? WhatsNewSecondaryAction(
            title: const WhatsNewText('Learn more'),
            onPressed: (WhatsNewActionContext action) {},
          )
        : null,
  );
}

/// The global rectangle a single matched widget occupies.
Rect _rectOf(WidgetTester tester, Finder finder) {
  final RenderBox box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _pump(
  WidgetTester tester, {
  required Size surface,
  required WhatsNew whatsNew,
  double textScale = 1,
  WhatsNewLayout? layout,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
        ),
        child: WhatsNewView(whatsNew: whatsNew, layout: layout),
      ),
    ),
  );
  // One settle for the layout, one more for the post-frame footer measurement
  // to land and rebuild.
  await tester.pumpAndSettle();
}

/// Scrolls the feature list as far as it will go.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final Finder scrollable = find.byType(Scrollable).first;
  final ScrollableState state = tester.state<ScrollableState>(scrollable);
  state.position.jumpTo(state.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  group('the pinned footer never occludes content', () {
    for (final double scale in <double>[1.0, 2.0, 3.0]) {
      testWidgets('the last feature clears the footer at ${scale}x text scale',
          (WidgetTester tester) async {
        await _pump(
          tester,
          surface: const Size(393, 852),
          whatsNew: _sample(),
          textScale: scale,
        );
        await _scrollToEnd(tester);

        final Rect lastFeature =
            _rectOf(tester, find.byType(WhatsNewFeatureRow).last);
        final Rect footer = _rectOf(tester, find.byType(WhatsNewFooter));

        expect(
          lastFeature.bottom,
          lessThanOrEqualTo(footer.top),
          reason:
              'the last feature row is ${lastFeature.bottom - footer.top}pt '
              'underneath the footer and cannot be scrolled clear',
        );
      });
    }

    testWidgets('an added safe-area inset is accounted for',
        (WidgetTester tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(393, 852)
        ..viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: WhatsNewView(
              whatsNew: _sample(),
              layout: const WhatsNewLayout(
                bottomSafeAreaBehavior: WhatsNewSafeAreaBehavior.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _scrollToEnd(tester);

      expect(
        _rectOf(tester, find.byType(WhatsNewFeatureRow).last).bottom,
        lessThanOrEqualTo(_rectOf(tester, find.byType(WhatsNewFooter)).top),
      );
    });

    testWidgets('a tablet keeps the capped column clear of the footer',
        (WidgetTester tester) async {
      await _pump(
        tester,
        surface: const Size(1024, 1366),
        whatsNew: _sample(featureCount: 8),
        textScale: 2,
      );
      await _scrollToEnd(tester);

      expect(
        _rectOf(tester, find.byType(WhatsNewFeatureRow).last).bottom,
        lessThanOrEqualTo(_rectOf(tester, find.byType(WhatsNewFooter)).top),
      );
    });

    testWidgets(
        'the WhatsNewKit constant still applies without a footer that '
        'outgrows it', (WidgetTester tester) async {
      // No secondary action: 54pt button + 80pt padding = 134 < 150, so the
      // original constant governs and parity is preserved.
      await _pump(
        tester,
        surface: const Size(393, 852),
        whatsNew: _sample(secondaryAction: false),
      );
      await _scrollToEnd(tester);

      final Finder scrollable = find.byType(Scrollable).first;
      final SingleChildScrollView view =
          tester.widget<SingleChildScrollView>(find
              .ancestor(
                of: scrollable,
                matching: find.byType(SingleChildScrollView),
              )
              .first);
      expect((view.padding as EdgeInsets?)?.bottom, 150);
    });
  });
}
