import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_feature_row.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const Size _phonePortrait = Size(393, 852);
const Size _phoneLandscape = Size(852, 393);

/// Arabic copy, so the test exercises real right-to-left script rather than
/// Latin text forced into an RTL layout.
WhatsNew _arabic() => WhatsNew(
      version: const WhatsNewVersion(1, 0, 0),
      title: const WhatsNewText('ما الجديد'),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.star,
          title: 'ميزات جديدة',
          subtitle: 'اعرض ميزات تطبيقك الجديدة تمامًا مثل تطبيقات أبل.',
        ),
        WhatsNewFeature(
          icon: Icons.bolt,
          title: 'عرض تلقائي',
          subtitle: 'أعلن عن إصدار جديد وسيتم عرضه تلقائيًا.',
        ),
      ],
      primaryAction: const WhatsNewPrimaryAction(
        title: WhatsNewText('متابعة'),
      ),
      secondaryAction: WhatsNewSecondaryAction(
        title: const WhatsNewText('اعرف المزيد'),
        onPressed: (WhatsNewActionContext action) {},
      ),
    );

Future<void> _pump(
  WidgetTester tester, {
  required TextDirection direction,
  Size size = _phonePortrait,
  WhatsNew? whatsNew,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: Brightness.dark),
    home: Directionality(
      textDirection: direction,
      child: WhatsNewView(whatsNew: whatsNew ?? _arabic()),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('right-to-left layout', () {
    testWidgets('the feature icon sits after the text, not before it',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.rtl);

      final Rect icon = tester.getRect(find.byIcon(Icons.star));
      final Rect text = tester.getRect(find.text('ميزات جديدة'));

      expect(icon.left, greaterThan(text.right),
          reason: 'in RTL the leading column is on the right');
    });

    testWidgets('the same content mirrors in LTR', (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.ltr);

      final Rect icon = tester.getRect(find.byIcon(Icons.star));
      final Rect text = tester.getRect(find.text('ميزات جديدة'));

      expect(icon.right, lessThan(text.left));
    });

    testWidgets('the feature list start inset applies on the right',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.rtl);
      final Rect row = tester.getRect(find.byType(WhatsNewFeatureRow).first);

      // 16 content padding + 15 featureListPadding.start, measured from the
      // right edge because start is the right in RTL.
      expect(
          _phonePortrait.width - row.right, moreOrLessEquals(31, epsilon: 0.5));
      expect(row.left, moreOrLessEquals(16, epsilon: 0.5));
    });

    testWidgets('the same inset applies on the left in LTR',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.ltr);
      final Rect row = tester.getRect(find.byType(WhatsNewFeatureRow).first);

      expect(row.left, moreOrLessEquals(31, epsilon: 0.5));
      expect(
          _phonePortrait.width - row.right, moreOrLessEquals(16, epsilon: 0.5));
    });

    testWidgets('feature text hugs the right edge of its column',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.rtl);

      final Text title = tester.widget<Text>(find.text('ميزات جديدة'));
      expect(title.textAlign, TextAlign.start,
          reason: 'start resolves to the right under RTL');
      expect(
        Directionality.of(tester.element(find.text('ميزات جديدة'))),
        TextDirection.rtl,
      );

      // The short title and the long subtitle should share a right edge.
      final Rect titleRect = tester.getRect(find.text('ميزات جديدة'));
      final Rect subtitleRect = tester.getRect(
          find.text('اعرض ميزات تطبيقك الجديدة تمامًا مثل تطبيقات أبل.'));
      expect(titleRect.right, moreOrLessEquals(subtitleRect.right, epsilon: 1));
      expect(titleRect.left, greaterThan(subtitleRect.left),
          reason: 'the shorter line is inset from the left, not the right');
    });

    testWidgets('the title stays centred in both directions',
        (WidgetTester tester) async {
      for (final TextDirection direction in TextDirection.values) {
        await _pump(tester, direction: direction);
        final Rect title = tester.getRect(find.text('ما الجديد'));
        final double leftGap = title.left;
        final double rightGap = _phonePortrait.width - title.right;
        expect((leftGap - rightGap).abs(), lessThan(1),
            reason:
                'the title is centred, so it must not shift with direction');
      }
    });

    testWidgets('the footer buttons span the same box in both directions',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.ltr);
      final Rect ltr = tester.getRect(find.text('متابعة'));

      await _pump(tester, direction: TextDirection.rtl);
      final Rect rtl = tester.getRect(find.text('متابعة'));

      expect(rtl.center.dx, moreOrLessEquals(ltr.center.dx, epsilon: 1));
    });
  });

  group('right-to-left in the two-column layout', () {
    testWidgets('the title column sits on the right',
        (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.rtl, size: _phoneLandscape);

      final Rect title = tester.getRect(find.text('ما الجديد'));
      final Rect feature =
          tester.getRect(find.byType(WhatsNewFeatureRow).first);

      expect(title.left, greaterThan(feature.right),
          reason: 'the leading column is on the right in RTL');
    });

    testWidgets('and on the left in LTR', (WidgetTester tester) async {
      await _pump(tester, direction: TextDirection.ltr, size: _phoneLandscape);

      final Rect title = tester.getRect(find.text('ما الجديد'));
      final Rect feature =
          tester.getRect(find.byType(WhatsNewFeatureRow).first);

      expect(title.right, lessThan(feature.left));
    });
  });

  group('right-to-left robustness', () {
    for (final MapEntry<String, Size> surface in <String, Size>{
      'portrait': _phonePortrait,
      'landscape': _phoneLandscape,
      'tablet': const Size(1024, 1366),
    }.entries) {
      testWidgets('renders ${surface.key} in RTL without overflowing',
          (WidgetTester tester) async {
        await _pump(tester, direction: TextDirection.rtl, size: surface.value);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('inline Markdown survives an RTL context',
        (WidgetTester tester) async {
      await _pump(
        tester,
        direction: TextDirection.rtl,
        whatsNew: WhatsNew(
          version: const WhatsNewVersion(1, 0, 0),
          title: const WhatsNewText('ما الجديد'),
          features: <WhatsNewFeature>[
            const WhatsNewFeature.rich(
              image: WhatsNewImage.icon(Icons.star),
              title: WhatsNewText('ميزة'),
              subtitle: WhatsNewText.markdown('استخدم **الأداة** الآن.'),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('الأداة'), findsOneWidget);
    });

    testWidgets('semantics carry the right text direction',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, direction: TextDirection.rtl);

      expect(
        tester.getSemantics(find.text('ما الجديد')).textDirection,
        TextDirection.rtl,
      );
      handle.dispose();
    });
  });
}
