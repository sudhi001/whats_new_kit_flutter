import 'package:flutter/widgets.dart';

import '../models/whats_new.dart';
import '../models/whats_new_layout.dart';
import '../models/whats_new_version.dart';
import '../presentation/whats_new_presentation.dart';
import '../presentation/whats_new_sheet.dart';
import '../store/caching_store.dart';
import '../store/shared_preferences_store.dart';
import '../store/whats_new_version_store.dart';
import '../theme/whats_new_theme.dart';
import '../util/app_version.dart';

/// Decides which What's New entry, if any, the reader should see.
///
/// This is the port of WhatsNewKit's `WhatsNewEnvironment`. Give it one entry
/// per release and it works out — from the running app version and the
/// versions already recorded — whether to present anything.
class WhatsNewController extends ChangeNotifier {
  /// Creates a controller.
  ///
  /// Leave [currentVersion] unset to take the version from
  /// [WhatsNewAppVersion], which you configure once at startup. Leave
  /// [versionStore] unset for a `shared_preferences`-backed store.
  WhatsNewController({
    List<WhatsNew> collection = const <WhatsNew>[],
    WhatsNewVersion? currentVersion,
    WhatsNewVersionStore? versionStore,
    this.layout,
    this.theme,
  })  : _collection = List<WhatsNew>.unmodifiable(collection),
        _currentVersion = currentVersion,
        _store = CachingWhatsNewVersionStore(
          versionStore ?? SharedPreferencesWhatsNewVersionStore(),
        );

  final CachingWhatsNewVersionStore _store;

  List<WhatsNew> _collection;
  WhatsNewVersion? _currentVersion;
  bool _isLoaded = false;
  bool _isLoading = false;
  Object? _loadError;
  bool _presentedThisSession = false;

  /// Overrides the geometry of every surface this controller presents.
  final WhatsNewLayout? layout;

  /// Overrides the styling of every surface this controller presents.
  final WhatsNewTheme? theme;

  /// The entries this app ships with, one per release.
  List<WhatsNew> get collection => _collection;

  set collection(List<WhatsNew> value) {
    _collection = List<WhatsNew>.unmodifiable(value);
    notifyListeners();
  }

  /// The version the app is running, once resolved.
  WhatsNewVersion? get currentVersion => _currentVersion;

  /// Whether [load] has completed.
  bool get isLoaded => _isLoaded;

  /// Why [load] failed, if it did.
  Object? get loadError => _loadError;

  /// The store backing this controller.
  WhatsNewVersionStore get versionStore => _store;

  /// The versions recorded as presented, as of the last load or save.
  Set<WhatsNewVersion> get presentedVersions =>
      _store.cached ?? const <WhatsNewVersion>{};

  /// Resolves the app version and reads the store into memory.
  ///
  /// Idempotent, and safe to call from `initState`. Once it completes,
  /// [pendingWhatsNew] can answer synchronously while building a frame.
  Future<void> load() async {
    if (_isLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    try {
      _currentVersion ??= await WhatsNewAppVersion.current();
      await _store.preload();
      _loadError = null;
      _isLoaded = true;
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The entry that should be presented, or `null` if none should be.
  ///
  /// This is WhatsNewKit's algorithm exactly:
  ///
  /// 1. If the running version has already been presented, show nothing.
  /// 2. Otherwise show the entry whose version matches it exactly.
  /// 3. Failing that, fall back to the `major.minor.0` entry — so declaring
  ///    `1.2.0` covers a reader running `1.2.7` — unless that has already been
  ///    presented.
  ///
  /// Note that versions are only ever compared for equality. A reader who
  /// upgrades from `1.0.0` straight to `1.3.0` sees the `1.3.x` entry, not
  /// every entry they skipped.
  ///
  /// Returns `null` until [load] has completed.
  WhatsNew? get pendingWhatsNew {
    final WhatsNewVersion? current = _currentVersion;
    if (!_isLoaded || current == null) {
      return null;
    }
    final Set<WhatsNewVersion> presented = presentedVersions;

    if (presented.contains(current)) {
      return null;
    }
    for (final WhatsNew whatsNew in _collection) {
      if (whatsNew.version == current) {
        return whatsNew;
      }
    }
    final WhatsNewVersion minorRelease = current.minorRelease;
    if (presented.contains(minorRelease)) {
      return null;
    }
    for (final WhatsNew whatsNew in _collection) {
      if (whatsNew.version == minorRelease) {
        return whatsNew;
      }
    }
    return null;
  }

  /// Loads if needed, then returns [pendingWhatsNew].
  Future<WhatsNew?> resolvePending() async {
    await load();
    return pendingWhatsNew;
  }

  /// Records [version] as presented.
  Future<void> markPresented(WhatsNewVersion version) async {
    await _store.save(version);
    notifyListeners();
  }

  /// Forgets every presented version, so the sheet can be replayed.
  Future<void> resetPresentedVersions() async {
    await _store.removeAll();
    _presentedThisSession = false;
    notifyListeners();
  }

  /// Presents [pendingWhatsNew] if there is one, at most once per session.
  ///
  /// Returns whether a sheet was shown. The session guard mirrors the local
  /// state WhatsNewKit keeps in its sheet modifier: the store write happens as
  /// the sheet closes, which is too late to stop the very next rebuild from
  /// presenting it again.
  Future<bool> presentIfNeeded(
    BuildContext context, {
    WhatsNewLayout? layout,
    WhatsNewTheme? theme,
    WhatsNewPresentation presentation = WhatsNewPresentation.adaptive,
    WhatsNewMarkPresented markPresented = WhatsNewMarkPresented.anyDismissal,
    bool useRootNavigator = true,
    bool isDismissible = true,
    VoidCallback? onDismiss,
  }) async {
    if (_presentedThisSession) {
      return false;
    }
    final WhatsNew? whatsNew = await resolvePending();
    if (whatsNew == null || !context.mounted) {
      return false;
    }
    _presentedThisSession = true;

    await WhatsNewSheet.show(
      context,
      whatsNew: whatsNew,
      versionStore: _store,
      layout: layout ?? this.layout,
      theme: theme ?? this.theme,
      // resolvePending already checked the store; checking again would only
      // re-read it.
      skipIfAlreadyPresented: false,
      presentation: presentation,
      markPresented: markPresented,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      onDismiss: onDismiss,
    );
    notifyListeners();
    return true;
  }
}
