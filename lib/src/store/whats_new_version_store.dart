import '../models/whats_new.dart';
import '../models/whats_new_version.dart';

/// Reads the versions that have already been presented.
abstract interface class ReadableWhatsNewVersionStore {
  /// Every version recorded as presented.
  Future<List<WhatsNewVersion>> presentedVersions();
}

/// Records that a version has been presented.
abstract interface class WriteableWhatsNewVersionStore {
  /// Records [version] as presented.
  Future<void> save(WhatsNewVersion version);
}

/// Persists which What's New versions a reader has already seen.
///
/// Implement this to back the record with something other than the bundled
/// stores — a database, a synced key-value service, or your own settings file.
/// The storage key format is documented on [WhatsNewVersion.storageKey].
abstract base class WhatsNewVersionStore
    implements ReadableWhatsNewVersionStore, WriteableWhatsNewVersionStore {
  /// Creates a version store.
  const WhatsNewVersionStore();

  /// Whether [version] has already been presented.
  Future<bool> hasPresented(WhatsNewVersion version) async {
    final List<WhatsNewVersion> versions = await presentedVersions();
    return versions.contains(version);
  }

  /// Whether [whatsNew]'s version has already been presented.
  Future<bool> hasPresentedEntry(WhatsNew whatsNew) =>
      hasPresented(whatsNew.version);

  /// Forgets that [version] was presented.
  Future<void> remove(WhatsNewVersion version);

  /// Forgets every presented version.
  Future<void> removeAll();
}
