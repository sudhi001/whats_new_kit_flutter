import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// A store whose reads can be held open, so a second caller can be let in
/// while the first is still awaiting.
final class _BlockingStore extends WhatsNewVersionStore {
  final Completer<void> gate = Completer<void>();
  final Set<WhatsNewVersion> _versions = <WhatsNewVersion>{};
  int reads = 0;

  @override
  Future<List<WhatsNewVersion>> presentedVersions() async {
    reads += 1;
    await gate.future;
    return _versions.toList(growable: false);
  }

  @override
  Future<void> save(WhatsNewVersion version) async => _versions.add(version);

  @override
  Future<void> remove(WhatsNewVersion version) async =>
      _versions.remove(version);

  @override
  Future<void> removeAll() async => _versions.clear();
}

/// A store that fails every operation.
final class _FailingStore extends WhatsNewVersionStore {
  @override
  Future<List<WhatsNewVersion>> presentedVersions() async =>
      throw StateError('unavailable');

  @override
  Future<void> save(WhatsNewVersion version) async =>
      throw StateError('unavailable');

  @override
  Future<void> remove(WhatsNewVersion version) async =>
      throw StateError('unavailable');

  @override
  Future<void> removeAll() async => throw StateError('unavailable');
}

WhatsNew _entry() => WhatsNew.of(
      version: '1.0.0',
      title: "What's New",
      features: <WhatsNewFeature>[
        WhatsNewFeature(icon: Icons.star, title: 'One', subtitle: 'Two'),
      ],
    );

WhatsNewController _controller({
  WhatsNewVersionStore? store,
  WhatsNewErrorReporter? onError,
}) {
  return WhatsNewController(
    currentVersion: const WhatsNewVersion(1, 0, 0),
    collection: <WhatsNew>[_entry()],
    versionStore: store ?? InMemoryWhatsNewVersionStore(),
    onError: onError ?? (Object _, StackTrace __) {},
  );
}

void main() {
  group('load', () {
    test('a concurrent caller joins the in-flight load instead of bailing',
        () async {
      final _BlockingStore store = _BlockingStore();
      final WhatsNewController controller = _controller(store: store);
      addTearDown(controller.dispose);

      final Future<void> first = controller.load();
      final Future<void> second = controller.load();
      expect(controller.isLoaded, isFalse);

      store.gate.complete();
      await Future.wait(<Future<void>>[first, second]);

      // Both futures must observe the finished load. Before the fix the
      // second returned immediately with isLoaded still false.
      expect(controller.isLoaded, isTrue);
      expect(store.reads, 1,
          reason: 'the store should be read once, not twice');
    });

    test('a second resolvePending sees the entry, not null', () async {
      final _BlockingStore store = _BlockingStore();
      final WhatsNewController controller = _controller(store: store);
      addTearDown(controller.dispose);

      final Future<WhatsNew?> first = controller.resolvePending();
      final Future<WhatsNew?> second = controller.resolvePending();
      store.gate.complete();

      expect(await first, isNotNull);
      expect(await second, isNotNull);
    });

    test('a failed load can be retried', () async {
      WhatsNewAppVersion.reset();
      final WhatsNewController controller = _controller(store: _FailingStore());
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.isLoaded, isFalse);
      expect(controller.loadError, isA<StateError>());

      // The in-flight future must have been cleared, or the retry short
      // circuits on a future that already completed in failure.
      await controller.load();
      expect(controller.loadError, isA<StateError>());
    });
  });

  group('presentIfNeeded', () {
    testWidgets('two concurrent calls present exactly one sheet',
        (WidgetTester tester) async {
      final _BlockingStore store = _BlockingStore();
      final WhatsNewController controller = _controller(store: store);
      addTearDown(controller.dispose);

      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (BuildContext context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      ));

      // These futures only complete once the sheet closes, so they are
      // collected rather than awaited up front.
      final List<bool> results = <bool>[];
      unawaited(controller
          .presentIfNeeded(capturedContext)
          .then((bool shown) => results.add(shown)));
      unawaited(controller
          .presentIfNeeded(capturedContext)
          .then((bool shown) => results.add(shown)));
      store.gate.complete();
      await tester.pumpAndSettle();

      // Before the fix both callers cleared the guard and pushed a modal.
      expect(find.byType(WhatsNewView), findsOneWidget);
      expect(results, <bool>[false],
          reason: 'the loser must report that it presented nothing');

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(results.where((bool shown) => shown).length, 1,
          reason: 'exactly one of the two callers may present');
    });

    testWidgets('the session guard is released when nothing was presented',
        (WidgetTester tester) async {
      // No matching entry, so the first call presents nothing. It must not
      // burn the once-per-session budget.
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(9, 9, 9),
        collection: <WhatsNew>[_entry()],
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      addTearDown(controller.dispose);

      late BuildContext capturedContext;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (BuildContext context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      ));

      expect(await controller.presentIfNeeded(capturedContext), isFalse);

      controller.collection = <WhatsNew>[
        _entry().copyWith(version: const WhatsNewVersion(9, 9, 9)),
      ];
      bool? shown;
      unawaited(controller
          .presentIfNeeded(capturedContext)
          .then((bool result) => shown = result));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsOneWidget,
          reason: 'a call that presented nothing must not burn the session');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(shown, isTrue);
    });
  });

  group('disposal', () {
    test('disposing mid-load does not throw', () async {
      final _BlockingStore store = _BlockingStore();
      final WhatsNewController controller = _controller(store: store);

      final Future<void> loading = controller.load();
      controller.dispose();
      store.gate.complete();

      // Before the fix the notifyListeners() in load's finally threw
      // "A WhatsNewController was used after being disposed".
      await expectLater(loading, completes);
      expect(controller.isDisposed, isTrue);
    });

    test('markPresented and reset are safe after disposal', () async {
      final WhatsNewController controller = _controller();
      await controller.load();
      controller.dispose();

      await expectLater(
        controller.markPresented(const WhatsNewVersion(1, 0, 0)),
        completes,
      );
      await expectLater(controller.resetPresentedVersions(), completes);
    });
  });

  group('store failures are reported, not thrown', () {
    test('markPresented absorbs a failing write', () async {
      final List<Object> errors = <Object>[];
      final WhatsNewController controller = _controller(
        store: _FailingStore(),
        onError: (Object error, StackTrace _) => errors.add(error),
      );
      addTearDown(controller.dispose);

      await expectLater(
        controller.markPresented(const WhatsNewVersion(1, 0, 0)),
        completes,
      );
      expect(errors, hasLength(1));
    });

    testWidgets('onDismiss still runs when the store write fails',
        (WidgetTester tester) async {
      bool dismissed = false;
      final List<Object> errors = <Object>[];

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (BuildContext context) {
          return TextButton(
            onPressed: () => showWhatsNewSheet(
              context,
              version: '1.0.0',
              title: "What's New",
              features: <WhatsNewFeature>[
                WhatsNewFeature(
                    icon: Icons.star, title: 'One', subtitle: 'Two'),
              ],
              versionStore: _FailingStore(),
              skipIfAlreadyPresented: false,
              onError: (Object error, StackTrace _) => errors.add(error),
              onDismiss: () => dismissed = true,
            ),
            child: const Text('show'),
          );
        }),
      ));

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewView), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue,
          reason: 'a failed write must not eat onDismiss');
      expect(errors, isNotEmpty);
    });

    testWidgets('an unreadable store still presents rather than staying silent',
        (WidgetTester tester) async {
      final List<Object> errors = <Object>[];
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (BuildContext context) {
          return TextButton(
            onPressed: () => showWhatsNewSheet(
              context,
              version: '1.0.0',
              title: "What's New",
              features: <WhatsNewFeature>[
                WhatsNewFeature(
                    icon: Icons.star, title: 'One', subtitle: 'Two'),
              ],
              versionStore: _FailingStore(),
              onError: (Object error, StackTrace _) => errors.add(error),
            ),
            child: const Text('show'),
          );
        }),
      ));

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.byType(WhatsNewView), findsOneWidget);
      expect(errors, isNotEmpty);
    });
  });
}
