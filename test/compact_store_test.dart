import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySharedPreferencesAsync backing;

  setUp(() {
    backing = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = backing;
  });

  CompactWhatsNewVersionStore store({bool removeLegacyKeys = true}) =>
      CompactWhatsNewVersionStore(removeLegacyKeys: removeLegacyKeys);

  Future<void> seed(Map<String, String> values) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    for (final MapEntry<String, String> entry in values.entries) {
      await prefs.setString(entry.key, entry.value);
    }
  }

  Future<Set<String>> keys() => SharedPreferencesAsync().getKeys();

  group('one key instead of one per release', () {
    test('records everything under a single preference', () async {
      final CompactWhatsNewVersionStore s = store();
      await s.save(const WhatsNewVersion(1, 0, 0));
      await s.save(const WhatsNewVersion(1, 1, 0));
      await s.save(const WhatsNewVersion(2, 0, 0));

      final Set<String> written = await keys();
      expect(written, <String>{CompactWhatsNewVersionStore.storageKey});

      expect(
        jsonDecode((await SharedPreferencesAsync()
            .getString(CompactWhatsNewVersionStore.storageKey))!),
        <String>['1.0.0', '1.1.0', '2.0.0'],
      );
    });

    test('reads back what it wrote', () async {
      await store().save(const WhatsNewVersion(1, 2, 3));
      expect(await store().presentedVersions(),
          <WhatsNewVersion>[const WhatsNewVersion(1, 2, 3)]);
      expect(
          await store().hasPresented(const WhatsNewVersion(1, 2, 3)), isTrue);
    });

    test('remove and removeAll', () async {
      final CompactWhatsNewVersionStore s = store();
      await s.save(const WhatsNewVersion(1, 0, 0));
      await s.save(const WhatsNewVersion(1, 1, 0));

      await s.remove(const WhatsNewVersion(1, 0, 0));
      expect(await s.presentedVersions(),
          <WhatsNewVersion>[const WhatsNewVersion(1, 1, 0)]);

      await s.removeAll();
      expect(await s.presentedVersions(), isEmpty);
    });
  });

  group('migrating from the WhatsNewKit format', () {
    test('imports existing records so nothing is re-presented', () async {
      await seed(<String, String>{
        'WhatsNewKit.1.0.0': '1.0.0',
        'WhatsNewKit.1.1.0': '1.1.0',
        'unrelated.setting': 'keep me',
      });

      final CompactWhatsNewVersionStore s = store();
      expect(
        (await s.presentedVersions()).map((WhatsNewVersion v) => v.toString()),
        containsAll(<String>['1.0.0', '1.1.0']),
      );
      expect(await s.hasPresented(const WhatsNewVersion(1, 1, 0)), isTrue,
          reason: 'a migrated reader must not see 1.1 again');
    });

    test('clears the legacy keys but leaves the app\'s own alone', () async {
      await seed(<String, String>{
        'WhatsNewKit.1.0.0': '1.0.0',
        'unrelated.setting': 'keep me',
      });
      await store().presentedVersions();

      expect(await keys(), <String>{
        'unrelated.setting',
        CompactWhatsNewVersionStore.storageKey,
      });
    });

    test('can keep the legacy keys for a Swift build sharing the store',
        () async {
      await seed(<String, String>{'WhatsNewKit.1.0.0': '1.0.0'});
      await store(removeLegacyKeys: false).presentedVersions();

      expect(
          await keys(),
          containsAll(<String>{
            'WhatsNewKit.1.0.0',
            CompactWhatsNewVersionStore.storageKey,
          }));
    });

    test('the legacy scan happens once, not on every read', () async {
      await seed(<String, String>{'WhatsNewKit.1.0.0': '1.0.0'});
      await store().presentedVersions();

      // A second instance sees the compact key and must not re-import — if it
      // did, a version removed after migration would come back.
      final CompactWhatsNewVersionStore second = store();
      await second.remove(const WhatsNewVersion(1, 0, 0));
      expect(await store().presentedVersions(), isEmpty);
    });
  });

  group('robustness', () {
    test('a corrupt payload reads as empty rather than throwing', () async {
      await seed(<String, String>{
        CompactWhatsNewVersionStore.storageKey: 'not json',
      });
      // Empty means at worst one sheet shows twice. Throwing here would
      // suppress every sheet for the life of the install.
      expect(await store().presentedVersions(), isEmpty);
    });

    test('unparseable entries are skipped, valid ones kept', () async {
      await seed(<String, String>{
        CompactWhatsNewVersionStore.storageKey:
            jsonEncode(<Object?>['1.0.0', 'banana', 42, '2.0.0']),
      });
      expect(
        (await store().presentedVersions())
            .map((WhatsNewVersion v) => v.toString())
            .toList()
          ..sort(),
        <String>['1.0.0', '2.0.0'],
      );
    });
  });

  group('launch record', () {
    test('round-trips and clears', () async {
      final CompactWhatsNewVersionStore s = store();
      expect(await s.lastLaunchedVersion(), isNull);

      await s.recordLaunch(const WhatsNewVersion(1, 4, 0));
      expect(await s.lastLaunchedVersion(), const WhatsNewVersion(1, 4, 0));

      await s.clearLaunchRecord();
      expect(await s.lastLaunchedVersion(), isNull);
    });

    test('survives removeAll of the presented set', () async {
      final CompactWhatsNewVersionStore s = store();
      await s.recordLaunch(const WhatsNewVersion(1, 4, 0));
      await s.save(const WhatsNewVersion(1, 4, 0));
      await s.removeAll();

      expect(await s.presentedVersions(), isEmpty);
      expect(await s.lastLaunchedVersion(), const WhatsNewVersion(1, 4, 0),
          reason: 'removeAll clears presented versions, not the launch record');
    });
  });
}
