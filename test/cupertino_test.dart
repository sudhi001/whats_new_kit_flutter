import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

WhatsNew _entry() => WhatsNew.of(
      version: '1.0.0',
      title: "What's New",
      features: <WhatsNewFeature>[
        WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
      ],
    );

Widget _trigger({required WhatsNewPresentation presentation}) {
  return Builder(
    builder: (BuildContext context) => CupertinoButton(
      onPressed: () => showWhatsNewSheet(
        context,
        version: '1.0.0',
        title: "What's New",
        presentation: presentation,
        features: <WhatsNewFeature>[
          WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
        ],
      ),
      child: const Text('show'),
    ),
  );
}

void main() {
  group('theming inside a CupertinoApp', () {
    // A CupertinoApp installs a Material Theme derived from its
    // CupertinoThemeData, so every colour the package reads resolves properly.
    testWidgets('dark mode is dark, not a white Material default',
        (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: WhatsNewView(whatsNew: _entry()),
      ));
      await tester.pumpAndSettle();

      final WhatsNewResolvedTheme resolved =
          WhatsNewTheme.resolve(tester.element(find.byType(WhatsNewView)));

      expect(resolved.sheetBackgroundColor.computeLuminance(), lessThan(0.1));
      expect(resolved.titleStyle.color!.computeLuminance(), greaterThan(0.5));
    });

    testWidgets('light mode is light', (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.light),
        home: WhatsNewView(whatsNew: _entry()),
      ));
      await tester.pumpAndSettle();

      final WhatsNewResolvedTheme resolved =
          WhatsNewTheme.resolve(tester.element(find.byType(WhatsNewView)));

      expect(
          resolved.sheetBackgroundColor.computeLuminance(), greaterThan(0.8));
      expect(resolved.titleStyle.color!.computeLuminance(), lessThan(0.2));
    });
  });

  group('presenting inside a CupertinoApp', () {
    for (final WhatsNewPresentation presentation
        in WhatsNewPresentation.values) {
      testWidgets('$presentation works with the Material delegates added',
          (WidgetTester tester) async {
        await tester.pumpWidget(CupertinoApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: _trigger(presentation: presentation),
        ));

        await tester.tap(find.text('show'));
        await tester.pumpAndSettle();

        expect(find.byType(WhatsNewView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('page needs no localizations at all',
        (WidgetTester tester) async {
      await tester.pumpWidget(CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: _trigger(presentation: WhatsNewPresentation.page),
      ));

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsOneWidget);
    });

    testWidgets('a sheet without them explains itself',
        (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: Builder(builder: (BuildContext c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));

      // Flutter's own assertion fires from deep inside showModalBottomSheet and
      // never mentions this package. Ours names the fix.
      await expectLater(
        WhatsNewSheet.show(
          ctx,
          whatsNew: _entry(),
          presentation: WhatsNewPresentation.bottomSheet,
        ),
        throwsA(isA<FlutterError>().having(
          (FlutterError e) => e.toString(),
          'message',
          allOf(
            contains('MaterialLocalizations'),
            contains('DefaultMaterialLocalizations.delegate'),
            contains('CupertinoApp'),
            contains('WhatsNewPresentation.page'),
          ),
        )),
      );
    });
  });
}
