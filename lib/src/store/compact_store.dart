import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/whats_new_version.dart';
import 'whats_new_version_store.dart';

/// A version store that keeps every presented version in a single preference.
///
/// [SharedPreferencesWhatsNewVersionStore] reproduces WhatsNewKit's format:
/// one key per release, named `WhatsNewKit.<version>`. Finding them means
/// calling `getKeys()`, which materialises **every preference the host app
/// owns** — and the set only grows, so a long-lived app accumulates a key per
/// release forever.
///
/// This keeps the same information under two fixed keys, so reads and writes
/// touch only what belongs to this package. Existing `WhatsNewKit.<version>`
/// records are imported the first time it runs, so switching stores does not
/// re-present sheets the reader has already seen.
///
/// The trade-off is the Swift format: an app sharing preferences with a
/// WhatsNewKit build should stay on
/// [SharedPreferencesWhatsNewVersionStore].
final class CompactWhatsNewVersionStore extends WhatsNewVersionStore
    implements WhatsNewLaunchRecordStore {
  /// Creates a compact store. Pass [preferences] to supply your own instance.
  ///
  /// Set [removeLegacyKeys] false to leave the imported
  /// `WhatsNewKit.<version>` keys in place — worth doing if a Swift build of
  /// the same app still reads them.
  CompactWhatsNewVersionStore({
    SharedPreferencesAsync? preferences,
    this.removeLegacyKeys = true,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  /// The key holding the presented versions, as a JSON array of strings.
  static const String storageKey = 'WhatsNewKitFlutter.presentedVersions';

  final SharedPreferencesAsync _preferences;

  /// Whether importing legacy records also deletes them.
  final bool removeLegacyKeys;

  Set<WhatsNewVersion>? _versions;

  Future<Set<WhatsNewVersion>> _read() async {
    final Set<WhatsNewVersion>? loaded = _versions;
    if (loaded != null) {
      return loaded;
    }
    final String? raw = await _preferences.getString(storageKey);
    if (raw == null) {
      // Absent, so this is either a fresh install or an app switching over
      // from the WhatsNewKit format. Either way the scan happens exactly once:
      // the write below means this branch is never taken again.
      final Set<WhatsNewVersion> imported = await _importLegacy();
      _versions = imported;
      await _write(imported);
      return imported;
    }
    return _versions = _decode(raw);
  }

  static Set<WhatsNewVersion> _decode(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <WhatsNewVersion>{};
      }
      return <WhatsNewVersion>{
        for (final Object? entry in decoded)
          if (entry is String)
            if (WhatsNewVersion.tryParse(entry) case final WhatsNewVersion v) v,
      };
    } on FormatException {
      // Corrupt rather than absent. Treating it as empty re-presents at worst
      // one sheet; throwing would suppress every sheet forever.
      return <WhatsNewVersion>{};
    }
  }

  Future<Set<WhatsNewVersion>> _importLegacy() async {
    final Set<String> keys = await _preferences.getKeys();
    final String prefix = '${WhatsNewVersion.storageKeyPrefix}.';
    final List<String> legacy =
        keys.where((String key) => key.startsWith(prefix)).toList();

    final Set<WhatsNewVersion> imported = <WhatsNewVersion>{
      for (final String key in legacy)
        if (WhatsNewVersion.tryParse(key.substring(prefix.length))
            case final WhatsNewVersion version)
          version,
    };

    if (removeLegacyKeys && legacy.isNotEmpty) {
      await Future.wait(
        legacy.map((String key) => _preferences.remove(key)),
      );
    }
    return imported;
  }

  Future<void> _write(Set<WhatsNewVersion> versions) {
    final List<String> sorted =
        versions.map((WhatsNewVersion v) => v.toString()).toList()..sort();
    return _preferences.setString(storageKey, jsonEncode(sorted));
  }

  @override
  Future<List<WhatsNewVersion>> presentedVersions() async =>
      (await _read()).toList(growable: false);

  @override
  Future<void> save(WhatsNewVersion version) async {
    final Set<WhatsNewVersion> versions = await _read();
    if (versions.add(version)) {
      await _write(versions);
    }
  }

  @override
  Future<void> remove(WhatsNewVersion version) async {
    final Set<WhatsNewVersion> versions = await _read();
    if (versions.remove(version)) {
      await _write(versions);
    }
  }

  @override
  Future<void> removeAll() async {
    _versions = <WhatsNewVersion>{};
    await _preferences.remove(storageKey);
  }

  @override
  Future<WhatsNewVersion?> lastLaunchedVersion() async {
    final String? recorded =
        await _preferences.getString(kWhatsNewLaunchRecordKey);
    return recorded == null ? null : WhatsNewVersion.tryParse(recorded);
  }

  @override
  Future<void> recordLaunch(WhatsNewVersion version) =>
      _preferences.setString(kWhatsNewLaunchRecordKey, version.toString());

  @override
  Future<void> clearLaunchRecord() =>
      _preferences.remove(kWhatsNewLaunchRecordKey);
}
