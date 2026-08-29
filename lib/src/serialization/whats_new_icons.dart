import 'package:flutter/widgets.dart';

/// Maps names to icons, so serialized content can refer to one.
///
/// An [IconData] cannot be safely reconstructed from a raw code point: Flutter
/// tree-shakes icon fonts by tracking which `IconData` constants a build
/// actually references, and a code point read from JSON references none of
/// them. The glyph is stripped and the icon renders as a blank box.
///
/// Registering the icons your release notes may use keeps them referenced from
/// Dart, so they survive tree-shaking, and gives content authors a stable name
/// rather than a number:
///
/// ```dart
/// WhatsNewIcons.register(<String, IconData>{
///   'sparkle': Icons.auto_awesome,
///   'bolt': Icons.bolt,
///   'lock': Icons.lock_outline,
/// });
/// ```
///
/// The alternative — building with `--no-tree-shake-icons` and constructing
/// `IconData` from code points — ships the entire icon font, several hundred
/// kilobytes of it, and is only worth it if content authors genuinely need the
/// whole set.
abstract final class WhatsNewIcons {
  static final Map<String, IconData> _registry = <String, IconData>{};

  /// Every registered name.
  static Iterable<String> get names => _registry.keys;

  /// Registers [icons], replacing any name already present.
  static void register(Map<String, IconData> icons) => _registry.addAll(icons);

  /// The icon registered as [name], or `null`.
  static IconData? resolve(String name) => _registry[name];

  /// The name [icon] was registered under, or `null`.
  static String? nameOf(IconData icon) {
    for (final MapEntry<String, IconData> entry in _registry.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }
    return null;
  }

  /// Empties the registry. Intended for tests.
  static void clear() => _registry.clear();
}
