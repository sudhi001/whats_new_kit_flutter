import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

WhatsNew _entry() => WhatsNew(
      version: const WhatsNewVersion(1, 0, 0),
      title: const WhatsNewText("What's New"),
      features: <WhatsNewFeature>[
        WhatsNewFeature(icon: Icons.star, title: 'One', subtitle: 'Two'),
      ],
      secondaryAction: WhatsNewSecondaryAction.dismiss(title: 'Not now'),
    );

Future<void> _pumpTrigger(
  WidgetTester tester,
  Future<void> Function(BuildContext context) onTap,
) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => unawaited(onTap(context)),
        child: const Text('show'),
      ),
    ),
  ));
}

void main() {
  group('the sheet reports how it closed', () {
    testWidgets('the primary button reports primaryAction',
        (WidgetTester tester) async {
      WhatsNewDismissal? result;
      await _pumpTrigger(tester, (BuildContext context) async {
        result = await WhatsNewSheet.show(context, whatsNew: _entry());
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result, WhatsNewDismissal.primaryAction);
      expect(result!.isAcknowledged, isTrue);
    });

    testWidgets('a swipe-down reports dismissed', (WidgetTester tester) async {
      WhatsNewDismissal? result;
      await _pumpTrigger(tester, (BuildContext context) async {
        result = await WhatsNewSheet.show(context, whatsNew: _entry());
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(WhatsNewView), const Offset(0, 600), 1500);
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsNothing);
      expect(result, WhatsNewDismissal.dismissed);
      expect(result!.isAcknowledged, isFalse);
    });

    testWidgets('a secondary action that closes the sheet reports dismissed',
        (WidgetTester tester) async {
      // Documented behaviour rather than a limitation glossed over: a modal
      // route reports that it popped, not why, so anything other than the
      // primary button is reported as `dismissed`.
      WhatsNewDismissal? result;
      await _pumpTrigger(tester, (BuildContext context) async {
        result = await WhatsNewSheet.show(context, whatsNew: _entry());
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsNothing);
      expect(result, WhatsNewDismissal.dismissed);
    });

    testWidgets('showWhatsNewSheet returns the same thing',
        (WidgetTester tester) async {
      WhatsNewDismissal? result;
      await _pumpTrigger(tester, (BuildContext context) async {
        result = await showWhatsNewSheet(
          context,
          version: '1.0.0',
          title: "What's New",
          features: <WhatsNewFeature>[
            WhatsNewFeature(icon: Icons.star, title: 'One', subtitle: 'Two'),
          ],
        );
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(result, WhatsNewDismissal.primaryAction);
    });
  });

  group('WhatsNewObserver', () {
    testWidgets('sees the surface open and close', (WidgetTester tester) async {
      final List<String> events = <String>[];
      final WhatsNewObserver observer = WhatsNewObserver(
        onPresented: (WhatsNew entry) => events.add('shown ${entry.version}'),
        onDismissed: (WhatsNew entry, WhatsNewDismissal how) =>
            events.add('closed ${how.name}'),
      );

      await _pumpTrigger(tester, (BuildContext context) async {
        await WhatsNewSheet.show(
          context,
          whatsNew: _entry(),
          observer: observer,
        );
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(events, <String>['shown 1.0.0']);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(events, <String>['shown 1.0.0', 'closed primaryAction']);
    });

    testWidgets('still fires when the store write fails',
        (WidgetTester tester) async {
      final List<WhatsNewDismissal> closed = <WhatsNewDismissal>[];
      await _pumpTrigger(tester, (BuildContext context) async {
        await WhatsNewSheet.show(
          context,
          whatsNew: _entry(),
          versionStore: _FailingStore(),
          skipIfAlreadyPresented: false,
          onError: (Object _, StackTrace __) {},
          observer: WhatsNewObserver(
            onDismissed: (WhatsNew _, WhatsNewDismissal how) => closed.add(how),
          ),
        );
      });

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(closed, <WhatsNewDismissal>[WhatsNewDismissal.primaryAction]);
    });

    testWidgets('a controller passes its observer through',
        (WidgetTester tester) async {
      final List<String> events = <String>[];
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 0, 0),
        collection: <WhatsNew>[_entry()],
        versionStore: InMemoryWhatsNewVersionStore(),
        observer: WhatsNewObserver(
          onPresented: (WhatsNew _) => events.add('shown'),
          onDismissed: (WhatsNew _, WhatsNewDismissal how) =>
              events.add(how.name),
        ),
      );
      addTearDown(controller.dispose);

      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (BuildContext c) {
          ctx = c;
          return const SizedBox.shrink();
        }),
      ));

      unawaited(controller.presentIfNeeded(ctx));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(events, <String>['shown', 'primaryAction']);
    });
  });
}

final class _FailingStore extends WhatsNewVersionStore {
  @override
  Future<List<WhatsNewVersion>> presentedVersions() async =>
      const <WhatsNewVersion>[];
  @override
  Future<void> save(WhatsNewVersion version) async => throw StateError('nope');
  @override
  Future<void> remove(WhatsNewVersion version) async =>
      throw StateError('nope');
  @override
  Future<void> removeAll() async => throw StateError('nope');
}
