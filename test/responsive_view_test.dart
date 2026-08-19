import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_feature_row.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const Size _phonePortrait = Size(393, 852);
const Size _phoneLandscape = Size(852, 393);
const Size _tabletPortrait = Size(1024, 1366);
const Size _tabletLandscape = Size(1366, 1024);
const Size _splitViewNarrow = Size(507, 1024);
const Size _tinyWatchLike = Size(220, 320);

WhatsNew _sample() => WhatsNew.of(
      version: '1.0.0',
      title: "What's New",
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.star,
          title: 'One',
          subtitle: 'The first thing that changed.',
        ),
        WhatsNewFeature(
          icon: Icons.bolt,
          title: 'Two',
          subtitle: 'The second thing that changed.',
        ),
      ],
      secondaryAction: WhatsNewSecondaryAction(
        title: const WhatsNewText('Learn more'),
        onPressed: (WhatsNewActionContext action) {},
      ),
    );

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  WhatsNewLayout? layout,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: Brightness.dark),
    home: WhatsNewView(whatsNew: _sample(), layout: layout),
  ));
  await tester.pumpAndSettle();
}

/// True when the title and the feature list sit side by side.
bool _isTwoColumn(WidgetTester tester) {
  final Rect title = tester.getRect(find.text("What's New"));
  final Rect firstFeature =
      tester.getRect(find.byType(WhatsNewFeatureRow).first);
  return firstFeature.left >= title.right;
}

void main() {
  group('arrangement adapts to the surface', () {
    testWidgets('phone portrait uses one column', (WidgetTester tester) async {
      await _pumpAt(tester, _phonePortrait);
      expect(_isTwoColumn(tester), isFalse);
    });

    testWidgets('phone landscape uses two columns',
        (WidgetTester tester) async {
      await _pumpAt(tester, _phoneLandscape);
      expect(_isTwoColumn(tester), isTrue);
    });

    testWidgets('tablet portrait uses one column', (WidgetTester tester) async {
      await _pumpAt(tester, _tabletPortrait);
      expect(_isTwoColumn(tester), isFalse);
    });

    testWidgets('tablet landscape uses two columns',
        (WidgetTester tester) async {
      await _pumpAt(tester, _tabletLandscape);
      expect(_isTwoColumn(tester), isTrue);
    });

    testWidgets('a narrow split view stays one column',
        (WidgetTester tester) async {
      await _pumpAt(tester, _splitViewNarrow);
      expect(_isTwoColumn(tester), isFalse);
    });

    testWidgets('rotating re-arranges without losing content',
        (WidgetTester tester) async {
      await _pumpAt(tester, _phonePortrait);
      expect(_isTwoColumn(tester), isFalse);

      tester.view.physicalSize = _phoneLandscape;
      await tester.pumpAndSettle();

      expect(_isTwoColumn(tester), isTrue);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.byType(WhatsNewFeatureRow), findsNWidgets(2));
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
    });
  });

  group('content width is capped on large surfaces', () {
    testWidgets('a tablet does not stretch text to the full width',
        (WidgetTester tester) async {
      await _pumpAt(tester, _tabletPortrait);

      final double rowWidth =
          tester.getSize(find.byType(WhatsNewFeatureRow).first).width;
      expect(
        rowWidth,
        lessThanOrEqualTo(WhatsNewLayout.standard.maxContentWidth),
      );
      // Without the cap this row would span the full 1024pt surface, giving a
      // line length no one wants to read.
      expect(rowWidth, lessThan(_tabletPortrait.width * 0.6));
    });

    testWidgets('the primary button is capped too',
        (WidgetTester tester) async {
      await _pumpAt(tester, _tabletPortrait);
      final double buttonWidth = tester.getSize(find.text('Continue')).width;
      expect(buttonWidth,
          lessThanOrEqualTo(WhatsNewLayout.standard.maxContentWidth));
    });

    testWidgets('a phone is never capped, keeping WhatsNewKit geometry',
        (WidgetTester tester) async {
      await _pumpAt(tester, _phonePortrait);

      final Rect row = tester.getRect(find.byType(WhatsNewFeatureRow).first);
      // 16 content padding + 15 feature list padding.
      expect(row.left, moreOrLessEquals(31, epsilon: 0.5));
    });

    testWidgets('an infinite cap restores the original full-width layout',
        (WidgetTester tester) async {
      await _pumpAt(
        tester,
        _tabletPortrait,
        layout: const WhatsNewLayout(
          maxContentWidth: double.infinity,
          contentLayout: WhatsNewContentLayout.single,
        ),
      );

      final Rect row = tester.getRect(find.byType(WhatsNewFeatureRow).first);
      // 16 content padding + 100 tablet inset + 15 feature list padding.
      expect(row.left, moreOrLessEquals(131, epsilon: 0.5));
    });
  });

  group('two columns stay readable on very wide surfaces', () {
    testWidgets('the feature column does not stretch edge to edge',
        (WidgetTester tester) async {
      await _pumpAt(tester, _tabletLandscape);

      final double rowWidth =
          tester.getSize(find.byType(WhatsNewFeatureRow).first).width;
      // Without the row cap this would be roughly 6/11 of 1366pt.
      expect(rowWidth, lessThan(WhatsNewLayout.standard.maxContentWidth + 40));
    });

    testWidgets('the row is centred once capped', (WidgetTester tester) async {
      await _pumpAt(tester, _tabletLandscape);

      final Rect title = tester.getRect(find.text("What's New"));
      final Rect lastFeature =
          tester.getRect(find.byType(WhatsNewFeatureRow).last);
      final double leftGap = title.left;
      final double rightGap = _tabletLandscape.width - lastFeature.right;
      expect((leftGap - rightGap).abs(), lessThan(60));
    });
  });

  group('arrangement is configurable', () {
    testWidgets('single can be forced in landscape',
        (WidgetTester tester) async {
      await _pumpAt(
        tester,
        _phoneLandscape,
        layout: const WhatsNewLayout(
          contentLayout: WhatsNewContentLayout.single,
        ),
      );
      expect(_isTwoColumn(tester), isFalse);
    });

    testWidgets('twoColumn can be forced in portrait',
        (WidgetTester tester) async {
      await _pumpAt(
        tester,
        _phonePortrait,
        layout: const WhatsNewLayout(
          contentLayout: WhatsNewContentLayout.twoColumn,
        ),
      );
      expect(_isTwoColumn(tester), isTrue);
    });

    testWidgets('the two-column threshold is movable',
        (WidgetTester tester) async {
      await _pumpAt(
        tester,
        _phoneLandscape,
        layout: const WhatsNewLayout(twoColumnMinWidth: 1200),
      );
      expect(_isTwoColumn(tester), isFalse);
    });
  });

  group('no overflow anywhere', () {
    for (final MapEntry<String, Size> surface in <String, Size>{
      'phone portrait': _phonePortrait,
      'phone landscape': _phoneLandscape,
      'tablet portrait': _tabletPortrait,
      'tablet landscape': _tabletLandscape,
      'narrow split view': _splitViewNarrow,
      'very small window': _tinyWatchLike,
    }.entries) {
      testWidgets('renders ${surface.key} without overflowing',
          (WidgetTester tester) async {
        await _pumpAt(tester, surface.value);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
