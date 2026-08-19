import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const WhatsNewVersion v100 = WhatsNewVersion(1, 0, 0);
  const WhatsNewVersion v110 = WhatsNewVersion(1, 1, 0);

  group('InMemoryWhatsNewVersionStore', () {
    test('starts empty', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      expect(await store.presentedVersions(), isEmpty);
      expect(await store.hasPresented(v100), isFalse);
    });

    test('records and reports a saved version', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.save(v100);
      expect(await store.presentedVersions(), <WhatsNewVersion>[v100]);
      expect(await store.hasPresented(v100), isTrue);
      expect(await store.hasPresented(v110), isFalse);
    });

    test('accepts a seed', () async {
      final InMemoryWhatsNewVersionStore store =
          InMemoryWhatsNewVersionStore(<WhatsNewVersion>{v100});
      expect(await store.hasPresented(v100), isTrue);
    });

    test('removes individually and in bulk', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.save(v100);
      await store.save(v110);
      await store.remove(v100);
      expect(await store.presentedVersions(), <WhatsNewVersion>[v110]);
      await store.removeAll();
      expect(await store.presentedVersions(), isEmpty);
    });

    test('exposes an unmodifiable view of its versions', () async {
      final InMemoryWhatsNewVersionStore store = InMemoryWhatsNewVersionStore();
      await store.save(v100);
      expect(() => store.versions.add(v110), throwsUnsupportedError);
    });
  });

  group('SharedPreferencesWhatsNewVersionStore', () {
    void mockPreferences(
        [Map<String, Object> initial = const <String, Object>{}]) {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(initial);
    }

    setUp(mockPreferences);

    test('writes the WhatsNewKit key format', () async {
      final SharedPreferencesWhatsNewVersionStore store =
          SharedPreferencesWhatsNewVersionStore();
      await store.save(const WhatsNewVersion(1, 2, 0));

      final SharedPreferencesAsync preferences = SharedPreferencesAsync();
      expect(await preferences.getString('WhatsNewKit.1.2.0'), '1.2.0');
    });

    test('reads back what it wrote', () async {
      final SharedPreferencesWhatsNewVersionStore store =
          SharedPreferencesWhatsNewVersionStore();
      await store.save(v100);
      await store.save(v110);
      expect(
        (await store.presentedVersions()).toSet(),
        <WhatsNewVersion>{v100, v110},
      );
    });

    test('reads records written by the Swift package', () async {
      mockPreferences(<String, Object>{
        'WhatsNewKit.2.1.0': '2.1.0',
        'unrelated.setting': 'ignored',
      });
      final SharedPreferencesWhatsNewVersionStore store =
          SharedPreferencesWhatsNewVersionStore();
      expect(
        await store.presentedVersions(),
        <WhatsNewVersion>[const WhatsNewVersion(2, 1, 0)],
      );
    });

    test('leaves unrelated keys alone when clearing', () async {
      mockPreferences(<String, Object>{
        'WhatsNewKit.1.0.0': '1.0.0',
        'other': 'keep me',
      });
      final SharedPreferencesWhatsNewVersionStore store =
          SharedPreferencesWhatsNewVersionStore();
      await store.removeAll();

      expect(await store.presentedVersions(), isEmpty);
      expect(await SharedPreferencesAsync().getString('other'), 'keep me');
    });
  });

  group('CachingWhatsNewVersionStore', () {
    test('reports null until preloaded', () async {
      final CachingWhatsNewVersionStore store =
          CachingWhatsNewVersionStore(InMemoryWhatsNewVersionStore());
      expect(store.cached, isNull);
      await store.preload();
      expect(store.cached, isEmpty);
    });

    test('serves reads from memory after preloading', () async {
      final InMemoryWhatsNewVersionStore inner = InMemoryWhatsNewVersionStore();
      await inner.save(v100);
      final CachingWhatsNewVersionStore store =
          CachingWhatsNewVersionStore(inner);
      await store.preload();

      // A write behind the cache's back is not observed.
      await inner.save(v110);
      expect(store.cached, <WhatsNewVersion>{v100});
    });

    test('writes through to the wrapped store', () async {
      final InMemoryWhatsNewVersionStore inner = InMemoryWhatsNewVersionStore();
      final CachingWhatsNewVersionStore store =
          CachingWhatsNewVersionStore(inner);
      await store.preload();
      await store.save(v100);

      expect(store.cached, <WhatsNewVersion>{v100});
      expect(await inner.hasPresented(v100), isTrue);
    });

    test('preloads lazily when read before preload', () async {
      final InMemoryWhatsNewVersionStore inner = InMemoryWhatsNewVersionStore();
      await inner.save(v100);
      final CachingWhatsNewVersionStore store =
          CachingWhatsNewVersionStore(inner);
      expect(await store.presentedVersions(), <WhatsNewVersion>[v100]);
    });
  });
}
