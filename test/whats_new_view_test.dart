import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_feature_row.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_primary_button.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const WhatsNewVersion _v100 = WhatsNewVersion(1, 0, 0);

List<WhatsNewFeature> _features() => <WhatsNewFeature>[
      WhatsNewFeature(
        icon: Icons.star,
        title: 'Showcase your new App Features',
        subtitle: 'Present your new app features.',
      ),
      WhatsNewFeature(
        icon: Icons.auto_awesome,
        title: 'Automatic Presentation',
        subtitle: 'Declare a WhatsNew per version.',
      ),
    ];

/// Pins the surface so layout assertions describe a known arrangement.
void _useSurface(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
}

const Size _phonePortrait = Size(393, 852);

Widget _host({required WidgetBuilder builder, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData(brightness: Brightness.dark),
    home: Scaffold(body: Builder(builder: builder)),
  );
}

void main() {
  group('WhatsNewView', () {
    testWidgets('renders the title and every feature',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Showcase your new App Features'), findsOneWidget);
      expect(find.text('Automatic Presentation'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('omits the secondary action when there is none',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      expect(find.byType(WhatsNewSecondaryButton), findsNothing);
    });

    testWidgets('lays the feature image column out at the layout width',
        (WidgetTester tester) async {
      _useSurface(tester, _phonePortrait);
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      final Size iconBox = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.star),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(iconBox.width, WhatsNewLayout.standard.featureImageWidth);
    });

    testWidgets('spaces features by featureListSpacing',
        (WidgetTester tester) async {
      _useSurface(tester, _phonePortrait);
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      final double firstBottom =
          tester.getRect(find.byType(WhatsNewFeatureRow).first).bottom;
      final double secondTop =
          tester.getRect(find.byType(WhatsNewFeatureRow).last).top;
      expect(
        secondTop - firstBottom,
        moreOrLessEquals(WhatsNewLayout.standard.featureListSpacing,
            epsilon: 0.5),
      );
    });

    testWidgets('takes its colors from the ambient ColorScheme',
        (WidgetTester tester) async {
      final ThemeData theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, theme.colorScheme.primary);
    });

    testWidgets('lets a WhatsNewTheme extension override the accent',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          extensions: const <ThemeExtension<dynamic>>[
            WhatsNewTheme(accentColor: Color(0xFF00FFAA)),
          ],
        ),
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ),
      ));

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, const Color(0xFF00FFAA));
    });

    testWidgets('records the version when disposed with a store',
        (WidgetTester tester) async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
          versionStore: store,
        ),
      ));

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(await store.hasPresented(_v100), isTrue);
    });
  });

  group('showWhatsNewSheet', () {
    testWidgets('presents, dismisses and reports the continue tap',
        (WidgetTester tester) async {
      bool continued = false;
      bool dismissed = false;

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            onContinue: () => continued = true,
            onDismiss: () => dismissed = true,
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text("What's New"), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsNothing);
      expect(continued, isTrue);
      expect(dismissed, isTrue);
    });

    testWidgets('records the version on the continue tap',
        (WidgetTester tester) async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            versionStore: store,
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(await store.hasPresented(_v100), isTrue);
    });

    testWidgets('records the version on a swipe-down, as WhatsNewKit does',
        (WidgetTester tester) async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            versionStore: store,
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.fling(find.text("What's New"), const Offset(0, 800), 2000);
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsNothing);
      expect(await store.hasPresented(_v100), isTrue);
    });

    testWidgets('leaves the version unrecorded on a swipe-down when asked to',
        (WidgetTester tester) async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            versionStore: store,
            markPresented: WhatsNewMarkPresented.primaryActionOnly,
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.fling(find.text("What's New"), const Offset(0, 800), 2000);
      await tester.pumpAndSettle();

      expect(await store.hasPresented(_v100), isFalse);
    });

    testWidgets('presents nothing when the version was already shown',
        (WidgetTester tester) async {
      final InMemoryWhatsNewVersionStore store =
          InMemoryWhatsNewVersionStore(<WhatsNewVersion>{_v100});

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            versionStore: store,
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsNothing);
    });

    testWidgets('runs the secondary action without closing the sheet',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(_host(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showWhatsNewSheet(
            context,
            version: '1.0.0',
            title: "What's New",
            features: _features(),
            secondaryAction: WhatsNewSecondaryAction(
              title: const WhatsNewText('Learn more'),
              onPressed: (WhatsNewActionContext action) => tapped = true,
            ),
            presentation: WhatsNewPresentation.bottomSheet,
          ),
          child: const Text('open'),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn more'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.text("What's New"), findsOneWidget);
    });
  });

  group('WhatsNewAutoSheet', () {
    testWidgets('presents once, then never again in the same session',
        (WidgetTester tester) async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: _v100,
        versionStore: InMemoryWhatsNewVersionStore(),
        collection: <WhatsNew>[
          WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ],
      );

      await tester.pumpWidget(WhatsNewScope(
        controller: controller,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const WhatsNewAutoSheet(
            presentation: WhatsNewPresentation.bottomSheet,
            child: Scaffold(body: Text('home')),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text("What's New"), findsNothing);

      // A rebuild must not bring it back.
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text("What's New"), findsNothing);
    });

    testWidgets('presents nothing when there is no pending entry',
        (WidgetTester tester) async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: _v100,
        versionStore: InMemoryWhatsNewVersionStore(<WhatsNewVersion>{_v100}),
        collection: <WhatsNew>[
          WhatsNew.of(
            version: '1.0.0',
            title: "What's New",
            features: _features(),
          ),
        ],
      );

      await tester.pumpWidget(WhatsNewScope(
        controller: controller,
        child: MaterialApp(
          home: const WhatsNewAutoSheet(
            child: Scaffold(body: Text('home')),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });
}
