import 'package:shared_preferences/shared_preferences.dart';

import '../models/whats_new_version.dart';
import 'whats_new_version_store.dart';

/// A version store backed by `shared_preferences`.
///
/// Keys are written as `WhatsNewKit.<version>` with the version string as the
/// value — byte-identical to WhatsNewKit's `UserDefaults` format, so an app
/// migrating from the Swift package reads its existing records with no
/// migration step.
final class SharedPreferencesWhatsNewVersionStore extends WhatsNewVersionStore
    implements WhatsNewLaunchRecordStore {
  /// Creates a store. Pass [preferences] to supply your own instance.
  SharedPreferencesWhatsNewVersionStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<WhatsNewVersion>> presentedVersions() async {
    final Set<String> keys = await _preferences.getKeys();
    return keys
        .where((String key) =>
            key.startsWith('${WhatsNewVersion.storageKeyPrefix}.'))
        .map((String key) => WhatsNewVersion.tryParse(
            key.substring(WhatsNewVersion.storageKeyPrefix.length + 1)))
        .whereType<WhatsNewVersion>()
        .toList(growable: false);
  }

  @override
  Future<void> save(WhatsNewVersion version) =>
      _preferences.setString(version.storageKey, version.toString());

  @override
  Future<void> remove(WhatsNewVersion version) =>
      _preferences.remove(version.storageKey);

  @override
  Future<void> removeAll() async {
    final Set<String> keys = await _preferences.getKeys();
    await Future.wait(<Future<void>>[
      for (final String key in keys)
        if (key.startsWith('${WhatsNewVersion.storageKeyPrefix}.'))
          _preferences.remove(key),
    ]);
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
