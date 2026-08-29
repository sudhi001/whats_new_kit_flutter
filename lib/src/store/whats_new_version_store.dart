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

/// Records the app version a reader last launched.
///
/// A version store answers "which sheets has this reader seen". That is not
/// the same question as "what were they running before", and the difference
/// matters twice:
///
/// * A fresh install of 1.4.0 and an upgrade from 1.3.0 are indistinguishable
///   from the presented set alone, so both get the 1.4 sheet. Showing "what's
///   new" to someone with no "before" is the wrong thing to do.
/// * A reader who goes 1.0.0 straight to 1.4.0 skipped three releases. Without
///   a record of where they started, there is no way to say what they missed.
///
/// Implement this alongside [WhatsNewVersionStore] to answer it. Stores that
/// do not are still perfectly usable — the controller falls back to its
/// original behaviour rather than failing.
abstract interface class WhatsNewLaunchRecordStore {
  /// The version recorded by the previous [recordLaunch], or `null` on a first
  /// launch.
  Future<WhatsNewVersion?> lastLaunchedVersion();

  /// Records [version] as the version now running.
  Future<void> recordLaunch(WhatsNewVersion version);

  /// Forgets the launch record, so the next launch reads as a first install.
  Future<void> clearLaunchRecord();
}

/// The key a bundled store writes its launch record under.
///
/// Deliberately not `WhatsNewKit.<version>`: that namespace belongs to the
/// Swift package's format, and a store scanning it for presented versions must
/// not trip over this.
const String kWhatsNewLaunchRecordKey =
    'WhatsNewKitFlutter.lastLaunchedVersion';
