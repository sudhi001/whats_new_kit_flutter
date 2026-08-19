import '../models/whats_new_version.dart';

/// Supplies the running app's version.
///
/// Reading the version is a policy decision — some apps want the marketing
/// version, some the build number, some a value from remote config — so this
/// package does not pick one for you, and takes no plugin dependency to do it.
///
/// You only need this when you let the package work out the version for
/// itself. Passing `version:` to `showWhatsNewSheet`, or `currentVersion:` to
/// [WhatsNewController], bypasses it entirely.
///
/// The usual wiring, once, in `main`:
///
/// ```dart
/// import 'package:package_info_plus/package_info_plus.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   WhatsNewAppVersion.resolver =
///       () async => (await PackageInfo.fromPlatform()).version;
///   runApp(const MyApp());
/// }
/// ```
///
/// The result is memoized, so [resolver] runs at most once per process.
abstract final class WhatsNewAppVersion {
  static WhatsNewVersion? _cached;

  /// Reads the running app's version string.
  ///
  /// Defaults to throwing a [StateError] explaining how to set it. Assign your
  /// own before the first sheet is presented.
  static Future<String> Function() resolver = _unconfigured;

  static Future<String> _unconfigured() {
    throw StateError(
      'whats_new_kit_flutter does not know the running app version.\n'
      '\n'
      'Do one of the following:\n'
      '  • pass version: to showWhatsNewSheet, or currentVersion: to '
      'WhatsNewController; or\n'
      '  • set the version once at startup:\n'
      '        WhatsNewAppVersion.overrideCurrent(const WhatsNewVersion(1, 2, 0));\n'
      '    or read it from the bundle with package_info_plus:\n'
      '        WhatsNewAppVersion.resolver =\n'
      '            () async => (await PackageInfo.fromPlatform()).version;',
    );
  }

  /// The running app's version, resolving it through [resolver] on first use.
  static Future<WhatsNewVersion> current() async {
    return _cached ??= WhatsNewVersion.parse(await resolver());
  }

  /// The resolved version, or `null` if [current] has not completed yet.
  static WhatsNewVersion? get currentOrNull => _cached;

  /// Sets the version directly, bypassing [resolver].
  static void overrideCurrent(WhatsNewVersion version) => _cached = version;

  /// Clears the memoized version and restores the default [resolver].
  ///
  /// Intended for tests, so one test's configuration cannot leak into another.
  static void reset() {
    _cached = null;
    resolver = _unconfigured;
  }
}
