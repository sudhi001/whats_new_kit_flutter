import '../models/whats_new_version.dart';
import 'whats_new_version_store.dart';

/// Wraps another store and keeps its contents in memory.
///
/// The presentation algorithm needs to answer "has this been shown?" while
/// building a frame, which an asynchronous store cannot do. Preloading once at
/// startup lets [WhatsNewController] make that decision synchronously — and it
/// avoids re-reading the whole key set on every query, which is what the Swift
/// original does.
final class CachingWhatsNewVersionStore extends WhatsNewVersionStore {
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

  @override
  Future<void> save(WhatsNewVersion version) async {
    _cached?.add(version);
    await inner.save(version);
  }

  @override
  Future<void> remove(WhatsNewVersion version) async {
    _cached?.remove(version);
    await inner.remove(version);
  }

  @override
  Future<void> removeAll() async {
    _cached?.clear();
    await inner.removeAll();
  }
}
