import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

WhatsNew _entry(WhatsNewVersion version) {
  return WhatsNew(
    version: version,
    title: WhatsNewText('Version $version'),
    features: <WhatsNewFeature>[
      WhatsNewFeature(
        icon: Icons.star,
        title: 'A feature',
        subtitle: 'Some supporting copy.',
      ),
    ],
  );
}

Future<WhatsNewController> _controller({
  required WhatsNewVersion currentVersion,
  required List<WhatsNew> collection,
  Set<WhatsNewVersion> presented = const <WhatsNewVersion>{},
}) async {
  final WhatsNewController controller = WhatsNewController(
    currentVersion: currentVersion,
    versionStore: InMemoryWhatsNewVersionStore(presented),
    collection: collection,
  );
  await controller.load();
  return controller;
}

void main() {
  const WhatsNewVersion v100 = WhatsNewVersion(1, 0, 0);
  const WhatsNewVersion v101 = WhatsNewVersion(1, 0, 1);
  const WhatsNewVersion v110 = WhatsNewVersion(1, 1, 0);
  const WhatsNewVersion v111 = WhatsNewVersion(1, 1, 1);

  group('pendingWhatsNew — the WhatsNewKit algorithm', () {
    test('presents the entry matching the running version', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: <WhatsNew>[_entry(v100)],
      );
      expect(controller.pendingWhatsNew?.version, v100);
    });

    test('presents nothing when that version was already shown', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: <WhatsNew>[_entry(v100)],
        presented: <WhatsNewVersion>{v100},
      );
      expect(controller.pendingWhatsNew, isNull);
    });

    test('presents the new entry after an update', () async {
      final List<WhatsNew> collection = <WhatsNew>[_entry(v100), _entry(v101)]
        ..shuffle();
      final WhatsNewController controller = await _controller(
        currentVersion: v101,
        collection: collection,
        presented: <WhatsNewVersion>{v100},
      );
      expect(controller.pendingWhatsNew?.version, v101);
    });

    test('falls back to the major.minor.0 entry on a patch release', () async {
      final List<WhatsNew> collection = <WhatsNew>[_entry(v100), _entry(v110)]
        ..shuffle();
      final WhatsNewController controller = await _controller(
        currentVersion: v111,
        collection: collection,
      );
      expect(controller.pendingWhatsNew?.version, v110);
    });

    test('presents nothing when the fallback was already shown', () async {
      final List<WhatsNew> collection = <WhatsNew>[_entry(v100), _entry(v110)]
        ..shuffle();
      final WhatsNewController controller = await _controller(
        currentVersion: v111,
        collection: collection,
        presented: <WhatsNewVersion>{v110},
      );
      expect(controller.pendingWhatsNew, isNull);
    });

    test('presents nothing when no entry matches', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: const WhatsNewVersion(3, 0, 0),
        collection: <WhatsNew>[_entry(v100)],
      );
      expect(controller.pendingWhatsNew, isNull);
    });

    test('skips releases the reader jumped over, as WhatsNewKit does',
        () async {
      // Upgrading 1.0.0 -> 1.1.0 shows only the 1.1.x entry: versions are
      // compared for equality, never for ordering.
      final WhatsNewController controller = await _controller(
        currentVersion: v110,
        collection: <WhatsNew>[_entry(v100), _entry(v110)],
      );
      expect(controller.pendingWhatsNew?.version, v110);
    });

    test('returns null before load completes', () {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: v100,
        versionStore: InMemoryWhatsNewVersionStore(),
        collection: <WhatsNew>[_entry(v100)],
      );
      expect(controller.isLoaded, isFalse);
      expect(controller.pendingWhatsNew, isNull);
    });
  });

  group('bookkeeping', () {
    test('markPresented suppresses the entry next time', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: <WhatsNew>[_entry(v100)],
      );
      expect(controller.pendingWhatsNew?.version, v100);
      await controller.markPresented(v100);
      expect(controller.pendingWhatsNew, isNull);
      expect(controller.presentedVersions, <WhatsNewVersion>{v100});
    });

    test('resetPresentedVersions brings the entry back', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: <WhatsNew>[_entry(v100)],
        presented: <WhatsNewVersion>{v100},
      );
      expect(controller.pendingWhatsNew, isNull);
      await controller.resetPresentedVersions();
      expect(controller.pendingWhatsNew?.version, v100);
    });

    test('load is idempotent', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: <WhatsNew>[_entry(v100)],
      );
      await controller.load();
      await controller.load();
      expect(controller.isLoaded, isTrue);
      expect(controller.loadError, isNull);
    });

    test('records a load failure instead of throwing', () async {
      WhatsNewAppVersion.reset();
      WhatsNewAppVersion.resolver = () async => throw StateError('no resolver');
      addTearDown(WhatsNewAppVersion.reset);

      final WhatsNewController controller = WhatsNewController(
        versionStore: InMemoryWhatsNewVersionStore(),
        collection: <WhatsNew>[_entry(v100)],
      );
      await controller.load();

      expect(controller.isLoaded, isFalse);
      expect(controller.loadError, isA<StateError>());
      expect(controller.pendingWhatsNew, isNull);
    });

    test('reports an unconfigured app version instead of guessing', () async {
      WhatsNewAppVersion.reset();
      addTearDown(WhatsNewAppVersion.reset);

      final WhatsNewController controller = WhatsNewController(
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      await controller.load();

      expect(controller.isLoaded, isFalse);
      expect(controller.loadError, isA<StateError>());
      expect(
        (controller.loadError! as StateError).message,
        contains('does not know the running app version'),
      );
    });

    test('resolves the app version through WhatsNewAppVersion', () async {
      WhatsNewAppVersion.reset();
      WhatsNewAppVersion.resolver = () async => '2.3.4+56';
      addTearDown(WhatsNewAppVersion.reset);

      final WhatsNewController controller = WhatsNewController(
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      await controller.load();

      expect(controller.currentVersion, const WhatsNewVersion(2, 3, 4));
    });

    test('notifies listeners when the collection changes', () async {
      final WhatsNewController controller = await _controller(
        currentVersion: v100,
        collection: const <WhatsNew>[],
      );
      int notifications = 0;
      controller.addListener(() => notifications += 1);

      controller.collection = <WhatsNew>[_entry(v100)];

      expect(notifications, 1);
      expect(controller.pendingWhatsNew?.version, v100);
    });
  });
}
