import 'package:flutter/widgets.dart';

import '../models/whats_new.dart';
import '../models/whats_new_feature.dart';
import '../models/whats_new_layout.dart';
import '../models/whats_new_version.dart';
import '../presentation/whats_new_observer.dart';
import '../presentation/whats_new_presentation.dart';
import '../presentation/whats_new_sheet.dart';
import '../store/caching_store.dart';
import '../store/shared_preferences_store.dart';
import '../store/whats_new_version_store.dart';
import '../theme/whats_new_theme.dart';
import '../util/app_version.dart';
import '../util/error_reporter.dart';

/// Builds the entries to offer for a given locale.
///
/// See [WhatsNewController.collectionBuilder].
typedef WhatsNewCollectionBuilder = List<WhatsNew> Function(Locale locale);

/// Combines several releases' entries into the one surface to present.
///
/// See [WhatsNewController.mergeMissedEntries].
typedef WhatsNewMerge = WhatsNew Function(List<WhatsNew> missed);

/// How [WhatsNewController] chooses what to present.
enum WhatsNewPresentationPolicy {
  /// WhatsNewKit's rule, and the default: the entry matching the running
  /// version exactly, or failing that the `major.minor.0` one.
  ///
  /// Only equality is considered, so a reader who goes from `1.0.0` straight
  /// to `1.4.0` sees the `1.4` entry and nothing of `1.1` through `1.3`.
  exactThenMinor,

  /// Every entry released since the reader was last here, merged into one
  /// surface.
  ///
  /// Needs a store that implements [WhatsNewLaunchRecordStore] — without a
  /// record of where the reader started there is nothing to measure "since"
  /// from, and this falls back to [exactThenMinor].
  ///
  /// Merged copy usually wants rewriting rather than concatenating, so supply
  /// [WhatsNewController.mergeMissedEntries] to control the result. The
  /// default keeps the newest entry's title and actions and concatenates the
  /// features oldest-first.
  allMissedSince,

  /// The newest declared entry at or below the running version, if it has not
  /// been presented.
  ///
  /// Useful when entries are declared for marketing releases but the running
  /// version is a build number that will never match one exactly.
  latestOnly,
}

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
  ///
  /// [onError] receives failures the controller absorbs rather than throws —
  /// a store that cannot be read or written. It defaults to
  /// [reportWhatsNewError].
  WhatsNewController({
    List<WhatsNew> collection = const <WhatsNew>[],
    this.collectionBuilder,
    WhatsNewVersion? currentVersion,
    WhatsNewVersionStore? versionStore,
    this.layout,
    this.theme,
    this.observer,
    this.presentationPolicy = WhatsNewPresentationPolicy.exactThenMinor,
    this.suppressOnFirstInstall = false,
    this.mergeMissedEntries,
    WhatsNewErrorReporter? onError,
  })  : _collection = List<WhatsNew>.unmodifiable(collection),
        _currentVersion = currentVersion,
        _onError = onError ?? reportWhatsNewError,
        _store = CachingWhatsNewVersionStore(
          versionStore ?? SharedPreferencesWhatsNewVersionStore(),
        );

  final CachingWhatsNewVersionStore _store;
  final WhatsNewErrorReporter _onError;

  List<WhatsNew> _collection;
  WhatsNewVersion? _currentVersion;
  bool _isLoaded = false;
  Future<void>? _loading;
  Object? _loadError;
  bool _presentedThisSession = false;
  bool _disposed = false;
  Locale? _locale;
  WhatsNewVersion? _lastLaunchedVersion;
  bool _isFirstLaunch = false;
  bool _hasLaunchRecord = false;

  /// Supplies the entries for the reader's locale.
  ///
  /// Release notes are copy, and copy needs translating. Set this to return
  /// the entries for a given [Locale] and they are rebuilt whenever the locale
  /// changes:
  ///
  /// ```dart
  /// WhatsNewController(
  ///   collectionBuilder: (Locale locale) => switch (locale.languageCode) {
  ///     'de' => germanReleases,
  ///     'ar' => arabicReleases,
  ///     _ => englishReleases,
  ///   },
  /// )
  /// ```
  ///
  /// Leave it unset and [collection] is used as given. The locale is read from
  /// the [BuildContext] passed to [presentIfNeeded]; call [updateLocale] to set
  /// it yourself.
  final WhatsNewCollectionBuilder? collectionBuilder;

  /// Overrides the geometry of every surface this controller presents.
  final WhatsNewLayout? layout;

  /// Overrides the styling of every surface this controller presents.
  final WhatsNewTheme? theme;

  /// Told when a surface this controller presents opens and closes.
  final WhatsNewObserver? observer;

  /// How to choose what to present. Defaults to WhatsNewKit's rule.
  final WhatsNewPresentationPolicy presentationPolicy;

  /// Whether to present nothing to a reader who has just installed the app.
  ///
  /// "What's new" implies a "before". Someone opening the app for the first
  /// time has none, so by default they meet the same sheet an upgrader does.
  /// Set this true to skip it for them — which needs a store implementing
  /// [WhatsNewLaunchRecordStore], since nothing else distinguishes the two.
  ///
  /// The first launch is still recorded, so the *next* release presents
  /// normally.
  final bool suppressOnFirstInstall;

  /// Combines the entries a reader missed into the one surface they see.
  ///
  /// Only consulted under [WhatsNewPresentationPolicy.allMissedSince].
  final WhatsNewMerge? mergeMissedEntries;

  /// The entries this app ships with, one per release.
  List<WhatsNew> get collection => _collection;

  set collection(List<WhatsNew> value) {
    _collection = List<WhatsNew>.unmodifiable(value);
    _safeNotify();
  }

  /// The version the app is running, once resolved.
  WhatsNewVersion? get currentVersion => _currentVersion;

  /// Whether [load] has completed.
  bool get isLoaded => _isLoaded;

  /// Why [load] failed, if it did.
  Object? get loadError => _loadError;

  /// The store backing this controller.
  ///
  /// This is the caching decorator wrapping whatever was passed to the
  /// constructor, not that instance itself. Read [innerVersionStore] for the
  /// store you supplied.
  WhatsNewVersionStore get versionStore => _store;

  /// The store passed to the constructor, unwrapped.
  ///
  /// Handing [versionStore] to a second controller would wrap the cache in
  /// another cache; pass this instead.
  WhatsNewVersionStore get innerVersionStore => _store.inner;

  /// The versions recorded as presented, as of the last load or save.
  Set<WhatsNewVersion> get presentedVersions =>
      _store.cached ?? const <WhatsNewVersion>{};

  /// Whether this controller has been disposed.
  bool get isDisposed => _disposed;

  /// The locale [collectionBuilder] last built for.
  Locale? get locale => _locale;

  /// The version the reader was running last time, if the store records it.
  ///
  /// `null` on a first launch, and on any store that does not implement
  /// [WhatsNewLaunchRecordStore].
  WhatsNewVersion? get lastLaunchedVersion => _lastLaunchedVersion;

  /// Whether this looks like the reader's first launch of the app.
  ///
  /// Always false until [load] completes, and always false on a store that
  /// keeps no launch record.
  bool get isFirstLaunch => _isFirstLaunch;

  /// Every declared entry released after [since] and no later than the running
  /// version, oldest first.
  ///
  /// This is what [WhatsNewPresentationPolicy.allMissedSince] merges, and it
  /// is public so an app can build its own summary instead. It is also the
  /// first thing in the package to use [WhatsNewVersion]'s comparison
  /// operators rather than equality.
  List<WhatsNew> entriesSince(WhatsNewVersion since) {
    final WhatsNewVersion? current = _currentVersion;
    if (current == null) {
      return const <WhatsNew>[];
    }
    final List<WhatsNew> missed = _collection
        .where((WhatsNew entry) =>
            entry.version > since && entry.version <= current)
        .toList();
    missed.sort((WhatsNew a, WhatsNew b) => a.version.compareTo(b.version));
    return List<WhatsNew>.unmodifiable(missed);
  }

  /// Rebuilds [collection] from [collectionBuilder] for [locale].
  ///
  /// A no-op when there is no builder, or when the locale has not changed.
  /// [presentIfNeeded] calls this for you.
  void updateLocale(Locale locale) {
    final WhatsNewCollectionBuilder? builder = collectionBuilder;
    if (builder == null || _locale == locale) {
      return;
    }
    _locale = locale;
    _collection = List<WhatsNew>.unmodifiable(builder(locale));
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifies listeners unless this controller has been disposed.
  ///
  /// Every notification here follows an `await`, and the widget that owns a
  /// controller is free to dispose it while a sheet is still open. Without
  /// this guard that is a `used after being disposed` crash.
  void _safeNotify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  /// Resolves the app version and reads the store into memory.
  ///
  /// Idempotent, and safe to call from `initState`. Concurrent callers join
  /// the in-flight load rather than returning early, so every one of them sees
  /// [isLoaded] set when their future completes. Once it does,
  /// [pendingWhatsNew] can answer synchronously while building a frame.
  Future<void> load() {
    if (_isLoaded) {
      return Future<void>.value();
    }
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      _currentVersion ??= await WhatsNewAppVersion.current();
      await _store.preload();
      await _readLaunchRecord();
      _loadError = null;
      _isLoaded = true;
    } catch (error, stackTrace) {
      _loadError = error;
      _onError(error, stackTrace);
    } finally {
      // Cleared so a failed load can be retried; a successful one is short
      // circuited by _isLoaded before it gets here.
      _loading = null;
      _safeNotify();
    }
  }

  /// Reads, then updates, the store's record of the running version.
  ///
  /// Order matters: the previous value is what says whether this is a first
  /// install and what the reader missed, so it is read before being
  /// overwritten. A store that keeps no record leaves everything at its
  /// default and the controller behaves exactly as it did before.
  Future<void> _readLaunchRecord() async {
    if (!_store.supportsLaunchRecord) {
      return;
    }
    _hasLaunchRecord = true;
    _lastLaunchedVersion = await _store.lastLaunchedVersion();
    // A store holding presented versions but no launch record is an app that
    // upgraded into this feature, not a fresh install.
    _isFirstLaunch = _lastLaunchedVersion == null && presentedVersions.isEmpty;
    final WhatsNewVersion? current = _currentVersion;
    if (current != null) {
      await _store.recordLaunch(current);
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
    if (suppressOnFirstInstall && _isFirstLaunch) {
      return null;
    }
    return switch (presentationPolicy) {
      WhatsNewPresentationPolicy.exactThenMinor => _exactThenMinor(current),
      WhatsNewPresentationPolicy.allMissedSince => _allMissedSince(current),
      WhatsNewPresentationPolicy.latestOnly => _latestOnly(current),
    };
  }

  WhatsNew? _exactThenMinor(WhatsNewVersion current) {
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

  WhatsNew? _latestOnly(WhatsNewVersion current) {
    final Set<WhatsNewVersion> presented = presentedVersions;
    WhatsNew? best;
    for (final WhatsNew entry in _collection) {
      if (entry.version <= current &&
          !presented.contains(entry.version) &&
          (best == null || entry.version > best.version)) {
        best = entry;
      }
    }
    return best;
  }

  WhatsNew? _allMissedSince(WhatsNewVersion current) {
    // Without a launch record there is no "since" to measure from, so this
    // degrades to the default rule rather than guessing.
    if (!_hasLaunchRecord) {
      return _exactThenMinor(current);
    }
    final List<WhatsNew> missed = entriesSince(
      _lastLaunchedVersion ?? WhatsNewVersion.zero,
    );
    final Set<WhatsNewVersion> presented = presentedVersions;
    final List<WhatsNew> unseen = missed
        .where((WhatsNew entry) => !presented.contains(entry.version))
        .toList(growable: false);
    if (unseen.isEmpty) {
      return null;
    }
    if (unseen.length == 1) {
      return unseen.single;
    }
    final WhatsNewMerge merge = mergeMissedEntries ?? _defaultMerge;
    return merge(unseen);
  }

  /// Concatenates features oldest-first under the newest entry's title.
  ///
  /// Deliberately plain. Merged release notes usually read better rewritten
  /// than concatenated, which is why [mergeMissedEntries] exists.
  static WhatsNew _defaultMerge(List<WhatsNew> missed) {
    final WhatsNew newest = missed.last;
    return newest.copyWith(
      features: <WhatsNewFeature>[
        for (final WhatsNew entry in missed) ...entry.features,
      ],
    );
  }

  /// Loads if needed, then returns [pendingWhatsNew].
  Future<WhatsNew?> resolvePending() async {
    await load();
    return pendingWhatsNew;
  }

  /// Records [version] as presented.
  Future<void> markPresented(WhatsNewVersion version) async {
    try {
      await _store.save(version);
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    } finally {
      _safeNotify();
    }
  }

  /// Forgets every presented version, so the sheet can be replayed.
  ///
  /// Also clears the launch record, so the next load reads as a first install
  /// — otherwise replaying under [WhatsNewPresentationPolicy.allMissedSince]
  /// would find nothing missed.
  Future<void> resetPresentedVersions() async {
    try {
      await _store.removeAll();
      await _store.clearLaunchRecord();
      _lastLaunchedVersion = null;
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    } finally {
      _presentedThisSession = false;
      _safeNotify();
    }
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
    final Locale? locale = Localizations.maybeLocaleOf(context);
    if (locale != null) {
      updateLocale(locale);
    }
    // Claimed before the first await. Two concurrent callers — an auto-sheet
    // in MaterialApp.builder and another around home, say — would otherwise
    // both pass the check above and both push a modal.
    _presentedThisSession = true;

    WhatsNew? whatsNew;
    try {
      whatsNew = await resolvePending();
    } catch (error, stackTrace) {
      _presentedThisSession = false;
      _onError(error, stackTrace);
      return false;
    }
    if (whatsNew == null || !context.mounted) {
      _presentedThisSession = false;
      return false;
    }

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
      onError: _onError,
      observer: observer,
      onDismiss: onDismiss,
    );
    _safeNotify();
    return true;
  }
}
