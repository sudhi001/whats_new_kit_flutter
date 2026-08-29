import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/src/view/whats_new_primary_button.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// A store whose writes always fail.
final class _FailingWriteStore extends WhatsNewVersionStore {
  final Set<WhatsNewVersion> seeded;
  _FailingWriteStore([Set<WhatsNewVersion>? seed])
      : seeded = <WhatsNewVersion>{...?seed};

  @override
  Future<List<WhatsNewVersion>> presentedVersions() async =>
      seeded.toList(growable: false);

  @override
  Future<void> save(WhatsNewVersion version) async =>
      throw StateError('disk full');

  @override
  Future<void> remove(WhatsNewVersion version) async =>
      throw StateError('disk full');

  @override
  Future<void> removeAll() async => throw StateError('disk full');
}

WhatsNew _entry({WhatsNewPrimaryAction? primaryAction}) => WhatsNew(
      version: const WhatsNewVersion(1, 0, 0),
      title: const WhatsNewText("What's New"),
      features: <WhatsNewFeature>[
        WhatsNewFeature(icon: Icons.star, title: 'One', subtitle: 'Two'),
      ],
      primaryAction: primaryAction ?? const WhatsNewPrimaryAction(),
    );

void main() {
  group('WhatsNewVersion.tryParse rejects every bad component', () {
    test('a non-numeric minor or patch is refused, not silently zeroed', () {
      expect(WhatsNewVersion.tryParse('1.zz'), isNull);
      expect(WhatsNewVersion.tryParse('1.2.zz'), isNull);
      expect(WhatsNewVersion.tryParse('1.garbage.garbage'), isNull);
    });

    test('more than three components is refused', () {
      expect(WhatsNewVersion.tryParse('1.2.3.4'), isNull);
    });

    test('valid versions still round-trip', () {
      expect(WhatsNewVersion.tryParse('1.2.3'), const WhatsNewVersion(1, 2, 3));
      expect(WhatsNewVersion.tryParse('1.2'), const WhatsNewVersion(1, 2));
      expect(WhatsNewVersion.tryParse('1'), const WhatsNewVersion(1));
      expect(
          WhatsNewVersion.tryParse('1.2.3+45'), const WhatsNewVersion(1, 2, 3));
      expect(WhatsNewVersion.tryParse('nope'), isNull);
      expect(WhatsNewVersion.tryParse(''), isNull);
    });

    test('a stray store key no longer reads back as a presented version', () {
      // The store filters raw preference keys through tryParse. Before this,
      // "WhatsNewKit.1.zz" was accepted as 1.0.0 and suppressed that sheet.
      expect(WhatsNewVersion.tryParse('1.zz'), isNull);
    });
  });

  group('parseCompat keeps WhatsNewKit parity, traps and all', () {
    test('drop-and-shift is preserved', () {
      expect(
          WhatsNewVersion.parseCompat('1.x.3'), const WhatsNewVersion(1, 3, 0));
      expect(
          WhatsNewVersion.parseCompat('1.2.3'), const WhatsNewVersion(1, 2, 3));
    });

    test('a Flutter version string still misparses, as documented', () {
      // Pinned deliberately: parseCompat exists to match the Swift package
      // byte for byte, and Swift does not strip build metadata either. The
      // doc comment warns callers off; use WhatsNewVersion.parse instead.
      expect(WhatsNewVersion.parseCompat('1.2.3+45'),
          const WhatsNewVersion(1, 2, 0));
      expect(WhatsNewVersion.parseCompat('2.0.0-beta.1'),
          const WhatsNewVersion(2, 0, 1));
      expect(WhatsNewVersion.parse('1.2.3+45'), const WhatsNewVersion(1, 2, 3));
    });
  });

  group('stripInlineMarkdown agrees with the renderer', () {
    test('literal asterisks the parser preserves survive the strip', () {
      expect(stripInlineMarkdown('2 * 3 * 4'), '2 * 3 * 4');
    });

    test('backslash escapes are honoured, not left dangling', () {
      expect(stripInlineMarkdown(r'a \* b'), 'a * b');
    });

    test('real syntax is still removed', () {
      expect(stripInlineMarkdown('**bold** and *italic*'), 'bold and italic');
      expect(stripInlineMarkdown('`code`'), 'code');
      expect(stripInlineMarkdown('[label](https://example.com)'), 'label');
    });
  });

  group('value equality', () {
    test('a WhatsNewTheme compares by value, so ThemeData can too', () {
      const WhatsNewTheme a = WhatsNewTheme(accentColor: Color(0xFF00FF00));
      final WhatsNewTheme b =
          WhatsNewTheme(accentColor: const Color(0xFF00FF00));
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      final ThemeData themeA =
          ThemeData(extensions: <ThemeExtension<dynamic>>[a]);
      final ThemeData themeB =
          ThemeData(extensions: <ThemeExtension<dynamic>>[b]);
      expect(themeA, themeB,
          reason: 'unequal themes invalidate every Theme.of dependent');
    });

    test('layouts and entries compare by value', () {
      expect(const WhatsNewLayout(), const WhatsNewLayout());
      expect(const WhatsNewLayout(contentSpacing: 10),
          isNot(const WhatsNewLayout(contentSpacing: 11)));
      expect(_entry(), _entry());
      expect(_entry().hashCode, _entry().hashCode);
    });
  });

  group('the primary button stays legible', () {
    testWidgets('a custom light background gets a dark label',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: _entry(
            primaryAction: const WhatsNewPrimaryAction(
              backgroundColor: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final WhatsNewPrimaryButton button = tester
          .widget<WhatsNewPrimaryButton>(find.byType(WhatsNewPrimaryButton));
      expect(button.backgroundColor, const Color(0xFFFFFFFF));
      expect(button.theme.primaryButtonTextStyle.color, const Color(0xFF000000),
          reason: 'white on white is invisible');
    });

    testWidgets('an explicit foreground still wins',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: _entry(
            primaryAction: const WhatsNewPrimaryAction(
              backgroundColor: Color(0xFFFFFFFF),
              foregroundColor: Color(0xFFFF0000),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<WhatsNewPrimaryButton>(find.byType(WhatsNewPrimaryButton))
            .theme
            .primaryButtonTextStyle
            .color,
        const Color(0xFFFF0000),
      );
    });
  });

  group('the caching store does not diverge from disk', () {
    test('a failed write leaves the cache untouched', () async {
      final CachingWhatsNewVersionStore store =
          CachingWhatsNewVersionStore(_FailingWriteStore());
      await store.preload();

      await expectLater(
          store.save(const WhatsNewVersion(1, 0, 0)), throwsStateError);

      expect(store.cached, isEmpty,
          reason: 'memory must not claim a version disk never recorded');
    });
  });

  group('WhatsNewAutoSheet.enabled', () {
    testWidgets('presents when flipped from false to true',
        (WidgetTester tester) async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        collection: <WhatsNew>[_entry()],
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      addTearDown(controller.dispose);

      bool enabled = false;
      await tester.pumpWidget(StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: WhatsNewAutoSheet(
              controller: controller,
              enabled: enabled,
              child: TextButton(
                onPressed: () => setState(() => enabled = true),
                child: const Text('enable'),
              ),
            ),
          );
        },
      ));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewView), findsNothing);

      await tester.tap(find.text('enable'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsOneWidget,
          reason: 'enabling after the first frame must still present');
    });
  });
}
