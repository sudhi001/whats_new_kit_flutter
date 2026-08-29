import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

WhatsNew _release(String version, String feature) => WhatsNew.of(
      version: version,
      title: 'Version $version',
      features: <WhatsNewFeature>[
        WhatsNewFeature(
            icon: Icons.star, title: feature, subtitle: 'in $version'),
      ],
    );

/// Four shipped releases.
List<WhatsNew> _collection() => <WhatsNew>[
      _release('1.0.0', 'Launch'),
      _release('1.1.0', 'Search'),
      _release('1.2.0', 'Sync'),
      _release('1.3.0', 'Widgets'),
    ];

/// A store that keeps presented versions but no launch record — what every
/// custom store written against 0.1.x looks like.
final class _RecordlessStore extends WhatsNewVersionStore {
  final Set<WhatsNewVersion> _versions = <WhatsNewVersion>{};
  @override
  Future<List<WhatsNewVersion>> presentedVersions() async =>
      _versions.toList(growable: false);
  @override
  Future<void> save(WhatsNewVersion version) async => _versions.add(version);
  @override
  Future<void> remove(WhatsNewVersion version) async =>
      _versions.remove(version);
  @override
  Future<void> removeAll() async => _versions.clear();
}

Future<WhatsNewController> _loaded({
  required String version,
  WhatsNewPresentationPolicy policy = WhatsNewPresentationPolicy.exactThenMinor,
  bool suppressOnFirstInstall = false,
  WhatsNewVersionStore? store,
  WhatsNewMerge? merge,
}) async {
  final WhatsNewController controller = WhatsNewController(
    currentVersion: WhatsNewVersion.parse(version),
    collection: _collection(),
    versionStore: store ?? InMemoryWhatsNewVersionStore(),
    presentationPolicy: policy,
    suppressOnFirstInstall: suppressOnFirstInstall,
    mergeMissedEntries: merge,
  );
  await controller.load();
  return controller;
}

void main() {
  group('entriesSince', () {
    test('lists what was released in between, oldest first', () async {
      final WhatsNewController c = await _loaded(version: '1.3.0');
      addTearDown(c.dispose);

      expect(
        c
            .entriesSince(const WhatsNewVersion(1, 0, 0))
            .map((WhatsNew e) => e.version.toString()),
        <String>['1.1.0', '1.2.0', '1.3.0'],
      );
    });

    test('excludes releases newer than the running version', () async {
      final WhatsNewController c = await _loaded(version: '1.2.0');
      addTearDown(c.dispose);

      expect(
        c
            .entriesSince(WhatsNewVersion.zero)
            .map((WhatsNew e) => e.version.toString()),
        <String>['1.0.0', '1.1.0', '1.2.0'],
        reason: '1.3.0 has not shipped to this reader yet',
      );
    });
  });

  group('allMissedSince', () {
    test('merges the releases a reader jumped over', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      // The reader was last here on 1.0.0.
      await store.recordLaunch(const WhatsNewVersion(1, 0, 0));

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        policy: WhatsNewPresentationPolicy.allMissedSince,
        store: store,
      );
      addTearDown(c.dispose);

      final WhatsNew? pending = c.pendingWhatsNew;
      expect(pending, isNotNull);
      expect(
        pending!.features.map((WhatsNewFeature f) => f.title.plainText),
        <String>['Search', 'Sync', 'Widgets'],
        reason: 'the default rule would have shown only Widgets',
      );
      expect(pending.title.plainText, 'Version 1.3.0');
    });

    test('a single missed release is presented as itself, unmerged', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.recordLaunch(const WhatsNewVersion(1, 2, 0));

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        policy: WhatsNewPresentationPolicy.allMissedSince,
        store: store,
      );
      addTearDown(c.dispose);

      expect(c.pendingWhatsNew!.version, const WhatsNewVersion(1, 3, 0));
      expect(c.pendingWhatsNew!.features, hasLength(1));
    });

    test('nothing to catch up on presents nothing', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.recordLaunch(const WhatsNewVersion(1, 3, 0));

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        policy: WhatsNewPresentationPolicy.allMissedSince,
        store: store,
      );
      addTearDown(c.dispose);
      expect(c.pendingWhatsNew, isNull);
    });

    test('a custom merge wins', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.recordLaunch(const WhatsNewVersion(1, 0, 0));

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        policy: WhatsNewPresentationPolicy.allMissedSince,
        store: store,
        merge: (List<WhatsNew> missed) => missed.last.copyWith(
          title: WhatsNewText('You missed ${missed.length} releases'),
        ),
      );
      addTearDown(c.dispose);

      expect(c.pendingWhatsNew!.title.plainText, 'You missed 3 releases');
    });

    test('degrades to the default rule on a store with no launch record',
        () async {
      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        policy: WhatsNewPresentationPolicy.allMissedSince,
        store: _RecordlessStore(),
      );
      addTearDown(c.dispose);

      // Not an error, not empty — the WhatsNewKit rule, exactly as before.
      expect(c.pendingWhatsNew!.version, const WhatsNewVersion(1, 3, 0));
      expect(c.pendingWhatsNew!.features, hasLength(1));
      expect(c.lastLaunchedVersion, isNull);
    });
  });

  group('latestOnly', () {
    test('picks the newest entry at or below the running version', () async {
      final WhatsNewController c = await _loaded(
        version: '1.2.7',
        policy: WhatsNewPresentationPolicy.latestOnly,
      );
      addTearDown(c.dispose);

      // The default rule would fall back to 1.2.0 too, but latestOnly also
      // covers a running version no entry is near.
      expect(c.pendingWhatsNew!.version, const WhatsNewVersion(1, 2, 0));
    });

    test('covers a running version the default rule misses entirely', () async {
      final WhatsNewController c = await _loaded(
        version: '1.4.9',
        policy: WhatsNewPresentationPolicy.latestOnly,
      );
      addTearDown(c.dispose);
      expect(c.pendingWhatsNew!.version, const WhatsNewVersion(1, 3, 0));

      final WhatsNewController other = await _loaded(version: '1.4.9');
      addTearDown(other.dispose);
      expect(other.pendingWhatsNew, isNull,
          reason: 'no 1.4.9 and no 1.4.0 entry exists');
    });
  });

  group('first install', () {
    test('is suppressed when asked, and only the first time', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();

      final WhatsNewController first = await _loaded(
        version: '1.3.0',
        suppressOnFirstInstall: true,
        store: store,
      );
      expect(first.isFirstLaunch, isTrue);
      expect(first.pendingWhatsNew, isNull,
          reason: 'a brand new reader has no "before" to be shown a diff from');
      first.dispose();

      // The next release presents normally: the launch was recorded.
      final WhatsNewController second = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 3, 0),
        collection: _collection(),
        versionStore: store,
        suppressOnFirstInstall: true,
      );
      await second.load();
      addTearDown(second.dispose);

      expect(second.isFirstLaunch, isFalse);
      expect(second.lastLaunchedVersion, const WhatsNewVersion(1, 3, 0));
      expect(second.pendingWhatsNew, isNotNull);
    });

    test('an upgrader is never treated as a first install', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.recordLaunch(const WhatsNewVersion(1, 2, 0));

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        suppressOnFirstInstall: true,
        store: store,
      );
      addTearDown(c.dispose);

      expect(c.isFirstLaunch, isFalse);
      expect(c.pendingWhatsNew, isNotNull);
    });

    test('an app upgrading into launch records is not a first install',
        () async {
      // Presented versions but no launch record: this reader has been here
      // before, under a version of the package that kept no record.
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore(
        <WhatsNewVersion>{const WhatsNewVersion(1, 2, 0)},
      );

      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        suppressOnFirstInstall: true,
        store: store,
      );
      addTearDown(c.dispose);

      expect(c.isFirstLaunch, isFalse);
      expect(c.pendingWhatsNew, isNotNull);
    });

    test('suppression is off by default', () async {
      final WhatsNewController c = await _loaded(version: '1.3.0');
      addTearDown(c.dispose);
      expect(c.isFirstLaunch, isTrue);
      expect(c.pendingWhatsNew, isNotNull,
          reason: 'the 0.1.x behaviour must be unchanged by default');
    });
  });

  group('the launch record survives a round trip', () {
    test('reset clears it, so a replay reads as a first install', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      final WhatsNewController c = await _loaded(
        version: '1.3.0',
        store: store,
      );
      addTearDown(c.dispose);

      expect(await store.lastLaunchedVersion(), const WhatsNewVersion(1, 3, 0));

      await c.resetPresentedVersions();
      expect(await store.lastLaunchedVersion(), isNull);
      expect(c.lastLaunchedVersion, isNull);
    });
  });
}
