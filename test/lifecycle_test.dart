import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const TextStyle _base = TextStyle(fontSize: 15);

/// Records which objects Flutter's allocation instrumentation sees disposed.
///
/// `GestureRecognizer.dispose` dispatches an [ObjectDisposed] event, so this is
/// a direct observation of disposal rather than a proxy for it.
class _DisposalWatcher {
  _DisposalWatcher() {
    FlutterMemoryAllocations.instance.addListener(_onEvent);
  }

  final Set<Object> disposed = <Object>{};

  void _onEvent(ObjectEvent event) {
    if (event is ObjectDisposed) {
      disposed.add(event.object);
    }
  }

  bool sawDisposalOf(Object object) =>
      disposed.any((Object each) => identical(each, object));

  void stop() => FlutterMemoryAllocations.instance.removeListener(_onEvent);
}

void main() {
  group('WhatsNewTextView recognizer lifecycle', () {
    testWidgets('disposes the recognizers it built when unmounted',
        (WidgetTester tester) async {
      final List<Uri> taps = <Uri>[];

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            WhatsNewTheme(onMarkdownLinkTap: taps.add),
          ],
        ),
        home: const Scaffold(
          body: WhatsNewTextView(
            text: WhatsNewText.markdown('read [the docs](https://example.com)'),
            style: _base,
          ),
        ),
      ));

      final RichText rich = tester.widget<RichText>(find.byType(RichText));
      final List<GestureRecognizer> recognizers =
          collectSpanRecognizers(rich.text);
      expect(recognizers, hasLength(1));

      final _DisposalWatcher watcher = _DisposalWatcher();
      addTearDown(watcher.stop);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      expect(
        watcher.sawDisposalOf(recognizers.single),
        isTrue,
        reason: 'unmounting must dispose the recognizer it created',
      );
    });

    testWidgets('does not accumulate recognizers across rebuilds',
        (WidgetTester tester) async {
      Widget host(String markdown) => MaterialApp(
            home: Scaffold(
              body: WhatsNewTextView(
                text: WhatsNewText.markdown(markdown),
                style: _base,
              ),
            ),
          );

      await tester.pumpWidget(host('one [a](https://a.dev)'));
      final RichText first = tester.widget<RichText>(find.byType(RichText));
      final GestureRecognizer firstRecognizer =
          collectSpanRecognizers(first.text).single;

      final _DisposalWatcher watcher = _DisposalWatcher();
      addTearDown(watcher.stop);

      await tester.pumpWidget(host('two [b](https://b.dev)'));
      final RichText second = tester.widget<RichText>(find.byType(RichText));
      final List<GestureRecognizer> live = collectSpanRecognizers(second.text);

      expect(live, hasLength(1), reason: 'one link means one recognizer');
      expect(live.single, isNot(same(firstRecognizer)));
      expect(
        watcher.sawDisposalOf(firstRecognizer),
        isTrue,
        reason: 'the superseded recognizer must be disposed, not orphaned',
      );
    });

    testWidgets('routes a Markdown link tap to the theme handler',
        (WidgetTester tester) async {
      final List<Uri> taps = <Uri>[];

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            WhatsNewTheme(onMarkdownLinkTap: taps.add),
          ],
        ),
        home: const Scaffold(
          body: WhatsNewTextView(
            text: WhatsNewText.markdown('read [the docs](https://example.com)'),
            style: _base,
          ),
        ),
      ));

      final RichText rich = tester.widget<RichText>(find.byType(RichText));
      final TapGestureRecognizer recognizer =
          collectSpanRecognizers(rich.text).single as TapGestureRecognizer;
      recognizer.onTap!();

      expect(taps, <Uri>[Uri.parse('https://example.com')]);
    });
  });

  group('WhatsNewController lifecycle', () {
    test('stops notifying once disposed', () async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      await controller.load();

      int notifications = 0;
      void listener() => notifications += 1;
      controller.addListener(listener);
      controller.removeListener(listener);
      controller.dispose();

      expect(notifications, 0);
      expect(controller.addListener, isNotNull);
    });
  });

  group('everything is configurable', () {
    test('sheet and dialog geometry live on the layout', () {
      const WhatsNewLayout layout = WhatsNewLayout.standard;
      expect(layout.sheetTopCornerRadius, 10);
      expect(layout.dialogMaxWidth, 520);
      expect(layout.dialogMaxHeight, 720);
      expect(layout.dialogInsetPadding, const EdgeInsets.all(24));

      final WhatsNewLayout custom = layout.copyWith(
        sheetTopCornerRadius: 28,
        dialogMaxWidth: 700,
      );
      expect(custom.sheetTopCornerRadius, 28);
      expect(custom.dialogMaxWidth, 700);
      // copyWith must not disturb neighbouring fields.
      expect(custom.dialogMaxHeight, 720);
      expect(custom.contentSpacing, layout.contentSpacing);
    });

    testWidgets('Markdown styling is theme-driven',
        (WidgetTester tester) async {
      late WhatsNewResolvedTheme resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[
            WhatsNewTheme(
              markdownStyle: InlineMarkdownStyle(
                codeFontFamily: 'Fira Code',
                codeFontSizeFactor: 1.5,
                linkColor: Color(0xFF00FF00),
              ),
            ),
          ],
        ),
        home: Builder(builder: (BuildContext context) {
          resolved = WhatsNewTheme.resolve(context);
          return const SizedBox.shrink();
        }),
      ));

      final TextStyle code = resolved.markdownStyle.resolveCodeStyle(_base);
      expect(code.fontFamily, 'Fira Code');
      expect(code.fontSize, 15 * 1.5);
      expect(
        resolved.markdownStyle.resolveLinkStyle(_base).color,
        const Color(0xFF00FF00),
      );
    });

    testWidgets('the footer scrim opacity is configurable',
        (WidgetTester tester) async {
      late WhatsNewResolvedTheme resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(surface: Color(0xFF1C1C1E)),
          extensions: const <ThemeExtension<dynamic>>[
            WhatsNewTheme(footerScrimOpacity: 0.25),
          ],
        ),
        home: Builder(builder: (BuildContext context) {
          resolved = WhatsNewTheme.resolve(context);
          return const SizedBox.shrink();
        }),
      ));

      expect(resolved.footerScrimColor.a, closeTo(0.25, 0.001));
    });
  });
}
