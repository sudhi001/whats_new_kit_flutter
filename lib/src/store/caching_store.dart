import '../models/whats_new_version.dart';
import 'whats_new_version_store.dart';

/// Wraps another store and keeps its contents in memory.
///
/// The presentation algorithm needs to answer "has this been shown?" while
/// building a frame, which an asynchronous store cannot do. Preloading once at
/// startup lets [WhatsNewController] make that decision synchronously — and it
/// avoids re-reading the whole key set on every query, which is what the Swift
/// original does.
final class CachingWhatsNewVersionStore extends WhatsNewVersionStore
    implements WhatsNewLaunchRecordStore {
  /// Wraps [inner].
  CachingWhatsNewVersionStore(this.inner);

  /// The store being cached.
  final WhatsNewVersionStore inner;

  Set<WhatsNewVersion>? _cached;

  /// The cached versions, or `null` until [preload] has completed.
  Set<WhatsNewVersion>? get cached =>
      _cached == null ? null : Set<WhatsNewVersion>.unmodifiable(_cached!);

  /// Reads [inner] into memory. Safe to call more than once.
  Future<void> preload() async {
    _cached = (await inner.presentedVersions()).toSet();
  }

  @override
  Future<List<WhatsNewVersion>> presentedVersions() async {
    final Set<WhatsNewVersion>? cached = _cached;
    if (cached != null) {
      return cached.toList(growable: false);
    }
    await preload();
    return _cached!.toList(growable: false);
  }

  // Every write goes to [inner] first and only then to the cache. Updating the
  // cache optimistically would leave memory saying "presented" and disk saying
  // otherwise whenever a write failed — the sheet would stay suppressed for
  // the rest of the session and come back on the next launch.

  @override
  Future<void> save(WhatsNewVersion version) async {
    await inner.save(version);
    _cached?.add(version);
  }

  @override
  Future<void> remove(WhatsNewVersion version) async {
    await inner.remove(version);
    _cached?.remove(version);
  }

  @override
  Future<void> removeAll() async {
    await inner.removeAll();
    _cached?.clear();
  }

  // The launch record is read once per launch and written once, so there is
  // nothing worth caching. These forward when [inner] supports them and answer
  // "not supported" when it does not, so a custom store stays valid.

  /// Whether [inner] keeps a launch record.
  bool get supportsLaunchRecord => inner is WhatsNewLaunchRecordStore;

  // Typed as Object so the `is` check promotes: WhatsNewVersionStore is a
  // `base` class and WhatsNewLaunchRecordStore an `interface`, which the
  // analyzer will not promote between directly.
  WhatsNewLaunchRecordStore? get _launchRecord {
    final Object store = inner;
    return store is WhatsNewLaunchRecordStore ? store : null;
  }

  @override
  Future<WhatsNewVersion?> lastLaunchedVersion() async =>
      _launchRecord?.lastLaunchedVersion();

  @override
  Future<void> recordLaunch(WhatsNewVersion version) async =>
      _launchRecord?.recordLaunch(version);

  @override
  Future<void> clearLaunchRecord() async => _launchRecord?.clearLaunchRecord();
}
