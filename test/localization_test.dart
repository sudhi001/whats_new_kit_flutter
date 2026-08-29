import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

WhatsNew _entry({String title = "What's New", WhatsNewText? continueLabel}) =>
    WhatsNew(
      version: const WhatsNewVersion(1, 0, 0),
      title: WhatsNewText(title),
      features: <WhatsNewFeature>[
        WhatsNewFeature(icon: Icons.star, title: 'One', subtitle: 'Two'),
      ],
      primaryAction: WhatsNewPrimaryAction(title: continueLabel),
    );

Widget _app({required Locale locale, required Widget child}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const <Locale>[
      Locale('en'),
      Locale('de'),
      Locale('fr'),
      Locale('ar'),
      Locale('ja'),
    ],
    home: child,
  );
}

void main() {
  group('the primary button speaks the reader\'s language', () {
    // Flutter already ships "Continue" translated for every locale
    // MaterialLocalizations supports, so the package does not need its own
    // ARB files for the one string it owns.
    const Map<String, String> expected = <String, String>{
      'de': 'Weiter',
      'fr': 'Continuer',
      'ja': '続行',
    };

    for (final MapEntry<String, String> entry in expected.entries) {
      testWidgets('${entry.key} renders "${entry.value}"',
          (WidgetTester tester) async {
        await tester.pumpWidget(_app(
          locale: Locale(entry.key),
          child: WhatsNewView(whatsNew: _entry()),
        ));
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text('Continue'), findsNothing);
      });
    }

    testWidgets('English still says Continue', (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        locale: const Locale('en'),
        child: WhatsNewView(whatsNew: _entry()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('an explicit label is left alone', (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        locale: const Locale('de'),
        child: WhatsNewView(
          whatsNew: _entry(continueLabel: const WhatsNewText('Los geht\'s')),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Los geht\'s'), findsOneWidget);
    });

    testWidgets('falls back to English with no Material localizations',
        (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: WhatsNewView(whatsNew: _entry()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('collectionBuilder', () {
    testWidgets('picks the entries for the ambient locale',
        (WidgetTester tester) async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        versionStore: InMemoryWhatsNewVersionStore(),
        collectionBuilder: (Locale locale) => <WhatsNew>[
          _entry(
              title: switch (locale.languageCode) {
            'de' => 'Das ist neu',
            'ar' => 'ما الجديد',
            _ => "What's New",
          }),
        ],
      );
      addTearDown(controller.dispose);

      late BuildContext ctx;
      await tester.pumpWidget(_app(
        locale: const Locale('de'),
        child: Builder(builder: (BuildContext c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));

      unawaited(controller.presentIfNeeded(ctx));
      await tester.pumpAndSettle();

      expect(find.text('Das ist neu'), findsOneWidget);
      expect(controller.locale, const Locale('de'));
    });

    test('updateLocale rebuilds the collection, and is idempotent', () {
      int builds = 0;
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        versionStore: InMemoryWhatsNewVersionStore(),
        collectionBuilder: (Locale locale) {
          builds += 1;
          return <WhatsNew>[_entry(title: locale.languageCode)];
        },
      );
      addTearDown(controller.dispose);

      controller.updateLocale(const Locale('fr'));
      expect(controller.collection.single.title.plainText, 'fr');
      expect(builds, 1);

      controller.updateLocale(const Locale('fr'));
      expect(builds, 1, reason: 'the same locale must not rebuild');

      controller.updateLocale(const Locale('ja'));
      expect(controller.collection.single.title.plainText, 'ja');
      expect(builds, 2);
    });

    test('a plain collection is untouched without a builder', () {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        versionStore: InMemoryWhatsNewVersionStore(),
        collection: <WhatsNew>[_entry(title: 'fixed')],
      );
      addTearDown(controller.dispose);

      controller.updateLocale(const Locale('de'));
      expect(controller.collection.single.title.plainText, 'fixed');
      expect(controller.locale, isNull);
    });
  });
}
