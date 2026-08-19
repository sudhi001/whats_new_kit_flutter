/// A semantic `major.minor.patch` version.
///
/// This is a faithful port of `WhatsNew.Version` from
/// [WhatsNewKit](https://github.com/SvenTiigi/WhatsNewKit), with one deliberate
/// change to parsing — see [WhatsNewVersion.parse] and [WhatsNewVersion.parseCompat].
///
/// The type is pure Dart: it never touches a plugin, so it is cheap to construct
/// and trivial to unit test.
class WhatsNewVersion implements Comparable<WhatsNewVersion> {
  /// Creates a version from its individual components.
  const WhatsNewVersion(this.major, [this.minor = 0, this.patch = 0]);

  /// Parses [value] positionally.
  ///
  /// Any `+build` or `-prerelease` suffix is stripped first, so a Flutter
  /// pubspec version such as `1.2.3+45` parses to `1.2.3`.
  ///
  /// A component that is not a valid integer becomes `0` **in place**, and
  /// missing components default to `0`:
  ///
  /// * `'1'` becomes `1.0.0`
  /// * `''` becomes `0.0.0`
  /// * `'1.x.3'` becomes `1.0.3`
  ///
  /// The last case is where this differs from WhatsNewKit, which drops the bad
  /// component and shifts the remaining ones left (yielding `1.3.0`). Use
  /// [WhatsNewVersion.parseCompat] if you need that behaviour.
  factory WhatsNewVersion.parse(String value) {
    final List<String> components = _stripBuildMetadata(value).split('.');
    int componentAt(int index) {
      if (index >= components.length) {
        return 0;
      }
      return int.tryParse(components[index].trim()) ?? 0;
    }

    return WhatsNewVersion(componentAt(0), componentAt(1), componentAt(2));
  }

  /// Parses [value] exactly the way WhatsNewKit does.
  ///
  /// Components that are not valid integers are *dropped*, and the remaining
  /// ones shift left, so `'1.x.3'` becomes `1.3.0`. Provided for byte-exact
  /// parity when migrating an app from the Swift package.
  factory WhatsNewVersion.parseCompat(String value) {
    final List<int> components = value
        .split('.')
        .map((String component) => int.tryParse(component))
        .whereType<int>()
        .toList(growable: false);
    int componentAt(int index) =>
        index < components.length ? components[index] : 0;
    return WhatsNewVersion(componentAt(0), componentAt(1), componentAt(2));
  }

  /// Parses [value], returning `null` when no component could be read.
  ///
  /// Unlike [WhatsNewVersion.parse], which silently yields [zero] for garbage
  /// input, this reports failure so callers can react to it.
  static WhatsNewVersion? tryParse(String value) {
    final List<String> components = _stripBuildMetadata(value).split('.');
    if (components.isEmpty || int.tryParse(components.first.trim()) == null) {
      return null;
    }
    return WhatsNewVersion.parse(value);
  }

  /// The `0.0.0` version, used whenever a version cannot be determined.
  static const WhatsNewVersion zero = WhatsNewVersion(0, 0, 0);

  /// The prefix of every key written by a version store.
  ///
  /// Byte-identical to WhatsNewKit's, so an app migrating from the Swift
  /// package reads its existing records without a migration step.
  static const String storageKeyPrefix = 'WhatsNewKit';

  /// The major component.
  final int major;

  /// The minor component.
  final int minor;

  /// The patch component.
  final int patch;

  /// This version with its patch component reset to zero.
  ///
  /// The presentation algorithm falls back to this when no entry matches the
  /// running version exactly.
  WhatsNewVersion get minorRelease => WhatsNewVersion(major, minor, 0);

  /// The key under which this version is recorded by a version store, for
  /// example `WhatsNewKit.1.2.0`.
  String get storageKey => '$storageKeyPrefix.$this';

  static String _stripBuildMetadata(String value) {
    final int cut = value.indexOf(RegExp(r'[+\-]'));
    return cut == -1 ? value : value.substring(0, cut);
  }

  @override
  int compareTo(WhatsNewVersion other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    return patch.compareTo(other.patch);
  }

  /// Whether this version precedes [other].
  bool operator <(WhatsNewVersion other) => compareTo(other) < 0;

  /// Whether this version precedes or equals [other].
  bool operator <=(WhatsNewVersion other) => compareTo(other) <= 0;

  /// Whether this version follows [other].
  bool operator >(WhatsNewVersion other) => compareTo(other) > 0;

  /// Whether this version follows or equals [other].
  bool operator >=(WhatsNewVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewVersion &&
          other.major == major &&
          other.minor == minor &&
          other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
