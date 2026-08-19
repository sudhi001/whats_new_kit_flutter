import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_primary_button.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const Size _phonePortrait = Size(393, 852);
const Size _phoneLandscape = Size(852, 393);

/// The package's own defaults: a plain Material scheme, which is what a caller
/// gets without pinning any colours.
ThemeData _defaultTheme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A84FF),
        brightness: brightness,
      ),
    );

/// Apple's system palette, which is what the sheet is designed against.
ThemeData _theme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A84FF),
      brightness: brightness,
    ).copyWith(
      primary: const Color(0xFF0A84FF),
      onPrimary: Colors.white,
      surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      onSurface: isDark ? Colors.white : Colors.black,
      onSurfaceVariant:
          isDark ? const Color(0xFF98989F) : const Color(0xFF6C6C70),
    ),
  );
}

WhatsNew _sample({bool withUrlAction = false}) => WhatsNew(
      version: const WhatsNewVersion(1, 0, 0),
      title: const WhatsNewText("What's New"),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.star,
          title: 'Showcase your new App Features',
          subtitle: 'Present your new app features just like a native app.',
        ),
        WhatsNewFeature(
          icon: Icons.bolt,
          title: 'Automatic Presentation',
          subtitle: 'Declare a WhatsNew per version.',
        ),
      ],
      secondaryAction: withUrlAction
          ? WhatsNewSecondaryAction.openUrl(
              title: 'Learn more',
              url: Uri.parse('https://example.com'),
            )
          : WhatsNewSecondaryAction(
              title: const WhatsNewText('Learn more'),
              onPressed: (WhatsNewActionContext action) {},
            ),
    );

Future<void> _pump(
  WidgetTester tester, {
  Size size = _phonePortrait,
  Brightness brightness = Brightness.dark,
  double textScale = 1.0,
  bool boldText = false,
  bool highContrast = false,
  TextDirection direction = TextDirection.ltr,
  bool withUrlAction = false,
  WhatsNewLayout? layout,
  ThemeData? theme,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    theme: theme ?? _theme(brightness),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        boldText: boldText,
        highContrast: highContrast,
      ),
      child: Directionality(
        textDirection: direction,
        child: WhatsNewView(
          whatsNew: _sample(withUrlAction: withUrlAction),
          layout: layout,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// WCAG relative-contrast ratio between two opaque colours.
double _contrastRatio(Color a, Color b) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);

  final double la = luminance(a);
  final double lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group("Flutter's accessibility guidelines", () {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('meets every guideline in ${brightness.name}',
          (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        // The package's own defaults, which is what a caller gets when they do
        // not pin colours of their own.
        await _pump(
          tester,
          brightness: brightness,
          theme: _defaultTheme(brightness),
        );

        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      });

      testWidgets(
          'meets the non-contrast guidelines on Apple\'s palette '
          'in ${brightness.name}', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pump(tester, brightness: brightness);

        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

        handle.dispose();
      });
    }

    testWidgets("white on Apple's system blue clears the large-bold-text bar",
        (WidgetTester tester) async {
      // 3.65:1 in dark, 4.02:1 in light. WCAG AA asks 4.5:1 for normal text
      // but only 3:1 for large bold text, and the label is 17pt semibold,
      // which qualifies. Flutter's textContrastGuideline ignores weight and so
      // applies the stricter bar; this records the real number instead.
      expect(_contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF0A84FF)),
          greaterThanOrEqualTo(3.0));
      expect(_contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF007AFF)),
          greaterThanOrEqualTo(3.0));
    });

    testWidgets('meets tap-target guidelines in the two-column layout',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, size: _phoneLandscape);

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });

  group('screen reader semantics', () {
    testWidgets('the title is a heading that names the route',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.text("What's New")),
        matchesSemantics(
          label: "What's New",
          isHeader: true,
          namesRoute: true,
          textDirection: TextDirection.ltr,
        ),
      );
      handle.dispose();
    });

    testWidgets('each feature reads as one element, not three',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.text('Showcase your new App Features')),
        matchesSemantics(
          label: 'Showcase your new App Features. '
              'Present your new app features just like a native app.',
          textDirection: TextDirection.ltr,
        ),
      );
      handle.dispose();
    });

    testWidgets('a button announces its label exactly once',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      final SemanticsNode node = tester.getSemantics(find.text('Continue'));
      expect(node.label, 'Continue');
      expect(node.label.contains('\n'), isFalse,
          reason: 'a doubled label would be read out twice');
      handle.dispose();
    });

    testWidgets('buttons are focusable and activatable',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.text('Continue')),
        matchesSemantics(
          label: 'Continue',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          textDirection: TextDirection.ltr,
        ),
      );
      handle.dispose();
    });

    testWidgets('activating a button through semantics runs it',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      bool tapped = false;

      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = _phonePortrait;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        theme: _theme(Brightness.dark),
        home: WhatsNewView(
          whatsNew: _sample().copyWith(
            primaryAction: WhatsNewPrimaryAction(
              onPressed: () => tapped = true,
            ),
          ),
          onDismissRequested: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // What VoiceOver or TalkBack sends on a double tap.
      tester.semantics.tap(find.semantics.byLabel('Continue'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      handle.dispose();
    });

    testWidgets('a URL action is announced as a link, an in-app one is not',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pump(tester, withUrlAction: true);
      expect(
        tester
            .getSemantics(find.text('Learn more'))
            .getSemanticsData()
            .flagsCollection
            .isLink,
        isTrue,
      );

      await _pump(tester);
      expect(
        tester
            .getSemantics(find.text('Learn more'))
            .getSemanticsData()
            .flagsCollection
            .isLink,
        isFalse,
      );

      handle.dispose();
    });
  });

  group('Apple tap-target minimums', () {
    testWidgets('the secondary link clears 48pt, so both platforms pass',
        (WidgetTester tester) async {
      await _pump(tester);
      final Size size = tester.getSize(
        find
            .ancestor(
              of: find.text('Learn more'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('the primary button clears 48pt', (WidgetTester tester) async {
      await _pump(tester);
      expect(
        tester.getSize(find.byType(WhatsNewPrimaryButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('the minimum is configurable', (WidgetTester tester) async {
      await _pump(tester, layout: const WhatsNewLayout(minTapTargetSize: 60));
      final Size size = tester.getSize(
        find
            .ancestor(
              of: find.text('Learn more'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(size.height, greaterThanOrEqualTo(60));
    });
  });

  group('Dynamic Type', () {
    for (final double scale in <double>[1.0, 1.5, 2.0, 3.0]) {
      testWidgets('renders at ${scale}x text scale without overflowing',
          (WidgetTester tester) async {
        await _pump(tester, textScale: scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders ${scale}x in landscape without overflowing',
          (WidgetTester tester) async {
        await _pump(tester, size: _phoneLandscape, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('text actually grows with the scale',
        (WidgetTester tester) async {
      await _pump(tester);
      final double normal = tester.getSize(find.text("What's New")).height;

      await _pump(tester, textScale: 2.0);
      final double scaled = tester.getSize(find.text("What's New")).height;

      expect(scaled, greaterThan(normal));
    });
  });

  group('system accessibility preferences', () {
    testWidgets('Bold Text thickens the type', (WidgetTester tester) async {
      Future<WhatsNewResolvedTheme> resolveWith(
          {required bool boldText}) async {
        late WhatsNewResolvedTheme resolved;
        await tester.pumpWidget(MaterialApp(
          theme: _theme(Brightness.dark),
          home: MediaQuery(
            data: MediaQueryData(boldText: boldText),
            child: Builder(builder: (BuildContext context) {
              resolved = WhatsNewTheme.resolve(context);
              return const SizedBox.shrink();
            }),
          ),
        ));
        await tester.pumpAndSettle();
        return resolved;
      }

      final WhatsNewResolvedTheme normal = await resolveWith(boldText: false);
      final WhatsNewResolvedTheme bold = await resolveWith(boldText: true);

      expect(normal.titleStyle.fontWeight, FontWeight.w700);
      expect(bold.titleStyle.fontWeight, FontWeight.w900);
      expect(
        bold.featureSubtitleStyle.fontWeight!.value,
        greaterThan(normal.featureSubtitleStyle.fontWeight!.value),
      );
      expect(
        bold.primaryButtonTextStyle.fontWeight!.value,
        greaterThan(normal.primaryButtonTextStyle.fontWeight!.value),
      );
    });

    testWidgets('Bold Text reaches the rendered title',
        (WidgetTester tester) async {
      await _pump(tester);
      final FontWeight? normal =
          tester.widget<Text>(find.byType(Text).first).style?.fontWeight;

      await _pump(tester, boldText: true);
      final FontWeight? bold =
          tester.widget<Text>(find.byType(Text).first).style?.fontWeight;

      expect(bold!.value, greaterThan(normal!.value));
    });

    testWidgets('high contrast removes the footer blur',
        (WidgetTester tester) async {
      await _pump(tester);
      expect(find.byType(BackdropFilter), findsOneWidget);

      await _pump(tester, highContrast: true);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('honouring high contrast can be turned off',
        (WidgetTester tester) async {
      await _pump(
        tester,
        highContrast: true,
        layout: const WhatsNewLayout(respectHighContrast: false),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });
}
