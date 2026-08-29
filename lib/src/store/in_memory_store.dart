import '../models/whats_new_version.dart';
import 'whats_new_version_store.dart';

/// A version store that forgets everything when the process exits.
///
/// Useful in tests, and in an example app where the sheet should reappear on
/// every launch.
final class InMemoryWhatsNewVersionStore extends WhatsNewVersionStore
    implements WhatsNewLaunchRecordStore {
  /// Creates an in-memory store, optionally pre-seeded with [seed].
  InMemoryWhatsNewVersionStore([Set<WhatsNewVersion>? seed])
      : _versions = <WhatsNewVersion>{...?seed};

  /// A store shared across the whole process.
  static final InMemoryWhatsNewVersionStore shared =
      InMemoryWhatsNewVersionStore();

  final Set<WhatsNewVersion> _versions;

  /// The versions currently recorded.
  Set<WhatsNewVersion> get versions =>
      Set<WhatsNewVersion>.unmodifiable(_versions);

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

  WhatsNewVersion? _lastLaunched;

  @override
  Future<WhatsNewVersion?> lastLaunchedVersion() async => _lastLaunched;

  @override
  Future<void> recordLaunch(WhatsNewVersion version) async =>
      _lastLaunched = version;

  @override
  Future<void> clearLaunchRecord() async => _lastLaunched = null;
}
