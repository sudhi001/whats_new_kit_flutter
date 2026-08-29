import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../models/whats_new.dart';
import '../models/whats_new_feature.dart';
import '../models/whats_new_image.dart';
import '../models/whats_new_primary_action.dart';
import '../models/whats_new_secondary_action.dart';
import '../models/whats_new_text.dart';
import '../models/whats_new_version.dart';
import '../text/link_policy.dart';
import 'whats_new_icons.dart';

/// Thrown when content cannot be read, naming where it went wrong.
class WhatsNewFormatException implements Exception {
  /// Records [message] at [path] within the document.
  WhatsNewFormatException(this.message, [this.path = '']);

  /// What was wrong.
  final String message;

  /// Where, as a dotted path — `entries[2].features[0].image`.
  final String path;

  @override
  String toString() =>
      'WhatsNewFormatException: $message${path.isEmpty ? '' : ' at $path'}';
}

/// Reads and writes [WhatsNew] entries as JSON.
///
/// Release notes are copy, and copy gets corrected after a build has shipped.
/// Compiled-in entries cannot be, so this exists to let the content come from
/// remote config, a CMS or a hosted file instead.
///
/// **Not everything round-trips, by construction.** Callbacks are code and
/// cannot be data, so [WhatsNewPrimaryAction.onPressed] and a custom
/// [WhatsNewSecondaryAction.onPressed] are dropped on encode; a serialized
/// secondary action is always an `openUrl`. [WhatsNewText.rich],
/// [WhatsNewText.builder] and [WhatsNewImage.widget] hold widgets and closures
/// and are refused outright rather than silently flattened. Icons go through
/// [WhatsNewIcons] — see the note there about tree-shaking.
///
/// ```dart
/// final List<WhatsNew> entries = WhatsNewCodec.decodeCollection(
///   jsonDecode(await remoteConfig.getString('whats_new')),
/// );
/// ```
///
/// Anything decoded here came from outside the binary. Links in it are
/// untrusted input, so a decoded secondary action carries a
/// [WhatsNewLinkPolicy] — the default one unless [decode] is given another.
abstract final class WhatsNewCodec {
  /// Decodes one entry.
  static WhatsNew decode(
    Map<String, Object?> json, {
    WhatsNewLinkPolicy linkPolicy = const WhatsNewLinkPolicy(),
    WhatsNewLinkFailure? onLinkFailure,
    String path = '',
  }) {
    final String version = _require<String>(json, 'version', path);
    final WhatsNewVersion parsed = WhatsNewVersion.tryParse(version) ??
        (throw WhatsNewFormatException(
            '"$version" is not a version', _join(path, 'version')));

    final Object? rawFeatures = json['features'];
    if (rawFeatures is! List) {
      throw WhatsNewFormatException(
          'features must be a list', _join(path, 'features'));
    }

    return WhatsNew(
      version: parsed,
      title: _text(json['title'], _join(path, 'title')),
      features: <WhatsNewFeature>[
        for (int i = 0; i < rawFeatures.length; i += 1)
          _feature(rawFeatures[i], '${_join(path, 'features')}[$i]'),
      ],
      primaryAction: json['primaryAction'] == null
          ? const WhatsNewPrimaryAction()
          : _primaryAction(json['primaryAction'], _join(path, 'primaryAction')),
      secondaryAction: json['secondaryAction'] == null
          ? null
          : _secondaryAction(
              json['secondaryAction'],
              _join(path, 'secondaryAction'),
              linkPolicy,
              onLinkFailure,
            ),
    );
  }

  /// Decodes a list of entries, or an object with an `entries` list.
  ///
  /// Accepts a JSON string as well as decoded structures, so a remote-config
  /// value can be passed straight through.
  static List<WhatsNew> decodeCollection(
    Object? json, {
    WhatsNewLinkPolicy linkPolicy = const WhatsNewLinkPolicy(),
    WhatsNewLinkFailure? onLinkFailure,
  }) {
    Object? source = json;
    if (source is String) {
      try {
        source = jsonDecode(source);
      } on FormatException catch (error) {
        throw WhatsNewFormatException('not valid JSON: ${error.message}');
      }
    }
    if (source is Map<String, Object?>) {
      source = source['entries'];
    }
    if (source is! List) {
      throw WhatsNewFormatException(
          'expected a list of entries, or an object with an "entries" list');
    }
    return <WhatsNew>[
      for (int i = 0; i < source.length; i += 1)
        decode(
          _asMap(source[i], 'entries[$i]'),
          linkPolicy: linkPolicy,
          onLinkFailure: onLinkFailure,
          path: 'entries[$i]',
        ),
    ];
  }

  /// Encodes [whatsNew].
  ///
  /// Throws [WhatsNewFormatException] for anything that is code rather than
  /// data — see the class documentation.
  static Map<String, Object?> encode(WhatsNew whatsNew) {
    return <String, Object?>{
      'version': whatsNew.version.toString(),
      'title': _encodeText(whatsNew.title, 'title'),
      'features': <Object?>[
        for (int i = 0; i < whatsNew.features.length; i += 1)
          _encodeFeature(whatsNew.features[i], 'features[$i]'),
      ],
      if (whatsNew.primaryAction.title != null)
        'primaryAction': <String, Object?>{
          'title': _encodeText(whatsNew.primaryAction.title!, 'primaryAction'),
          if (whatsNew.primaryAction.backgroundColor != null)
            'backgroundColor':
                _encodeColor(whatsNew.primaryAction.backgroundColor!),
          if (whatsNew.primaryAction.foregroundColor != null)
            'foregroundColor':
                _encodeColor(whatsNew.primaryAction.foregroundColor!),
        },
    };
  }

  /// Encodes [entries] as `{"entries": [...]}`.
  static Map<String, Object?> encodeCollection(List<WhatsNew> entries) =>
      <String, Object?>{
        'entries': <Object?>[for (final WhatsNew e in entries) encode(e)],
      };

  // ---------------------------------------------------------------- decoding

  static WhatsNewFeature _feature(Object? raw, String path) {
    final Map<String, Object?> json = _asMap(raw, path);
    return WhatsNewFeature.rich(
      image: _image(json['image'], _join(path, 'image')),
      title: _text(json['title'], _join(path, 'title')),
      subtitle: _text(json['subtitle'], _join(path, 'subtitle')),
    );
  }

  /// Reads text as either a bare string or `{"markdown": "..."}`.
  static WhatsNewText _text(Object? raw, String path) {
    if (raw is String) {
      return WhatsNewText(raw);
    }
    if (raw is Map<String, Object?>) {
      final Object? markdown = raw['markdown'];
      if (markdown is String) {
        return WhatsNewText.markdown(markdown);
      }
      final Object? plain = raw['text'];
      if (plain is String) {
        return WhatsNewText(plain);
      }
    }
    throw WhatsNewFormatException(
        'expected a string, {"text": ...} or {"markdown": ...}', path);
  }

  static WhatsNewImage _image(Object? raw, String path) {
    final Map<String, Object?> json = _asMap(raw, path);
    final Color? color = _color(json['color'], _join(path, 'color'));
    final double? size = _double(json['size'], _join(path, 'size'));

    final Object? icon = json['icon'];
    if (icon is String) {
      final IconData? resolved = WhatsNewIcons.resolve(icon);
      if (resolved == null) {
        throw WhatsNewFormatException(
          'no icon is registered as "$icon". Register it with '
          'WhatsNewIcons.register before decoding.',
          _join(path, 'icon'),
        );
      }
      return WhatsNewImage.icon(resolved, color: color, size: size);
    }

    final Object? asset = json['asset'];
    if (asset is String) {
      return WhatsNewImage.asset(
        asset,
        package: json['package'] as String?,
        color: color,
        size: size,
      );
    }

    throw WhatsNewFormatException('expected an "icon" or "asset" key', path);
  }

  static WhatsNewPrimaryAction _primaryAction(Object? raw, String path) {
    final Map<String, Object?> json = _asMap(raw, path);
    return WhatsNewPrimaryAction(
      title: json['title'] == null
          ? null
          : _text(json['title'], _join(path, 'title')),
      backgroundColor:
          _color(json['backgroundColor'], _join(path, 'backgroundColor')),
      foregroundColor:
          _color(json['foregroundColor'], _join(path, 'foregroundColor')),
    );
  }

  static WhatsNewSecondaryAction _secondaryAction(
    Object? raw,
    String path,
    WhatsNewLinkPolicy policy,
    WhatsNewLinkFailure? onFailure,
  ) {
    final Map<String, Object?> json = _asMap(raw, path);
    final String url = _require<String>(json, 'url', path);
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      throw WhatsNewFormatException('"$url" is not a URL', _join(path, 'url'));
    }
    return WhatsNewSecondaryAction.openUrl(
      title: _text(json['title'], _join(path, 'title')).plainText,
      url: parsed,
      foregroundColor:
          _color(json['foregroundColor'], _join(path, 'foregroundColor')),
      policy: policy,
      onFailure: onFailure,
    );
  }

  // ---------------------------------------------------------------- encoding

  static Object _encodeText(WhatsNewText text, String path) {
    return switch (text) {
      PlainWhatsNewText(:final String value) => value,
      MarkdownWhatsNewText(:final String markdown) => <String, Object?>{
          'markdown': markdown,
        },
      RichWhatsNewText() ||
      BuilderWhatsNewText() =>
        throw WhatsNewFormatException(
          '${text.runtimeType} holds spans built in Dart and cannot be '
          'encoded. Use a plain or Markdown text instead.',
          path,
        ),
    };
  }

  static Object _encodeFeature(WhatsNewFeature feature, String path) {
    return <String, Object?>{
      'image': _encodeImage(feature.image, _join(path, 'image')),
      'title': _encodeText(feature.title, _join(path, 'title')),
      'subtitle': _encodeText(feature.subtitle, _join(path, 'subtitle')),
    };
  }

  static Object _encodeImage(WhatsNewImage image, String path) {
    switch (image) {
      case IconWhatsNewImage(
          :final IconData icon,
          :final Color? color,
          :final double? size
        ):
        final String? name = WhatsNewIcons.nameOf(icon);
        if (name == null) {
          throw WhatsNewFormatException(
            'this icon is not registered, so it has no name to encode. '
            'Register it with WhatsNewIcons.register.',
            path,
          );
        }
        return <String, Object?>{
          'icon': name,
          if (color != null) 'color': _encodeColor(color),
          if (size != null) 'size': size,
        };
      case AssetWhatsNewImage(
          :final String name,
          :final String? package,
          :final Color? color,
          :final double? size
        ):
        return <String, Object?>{
          'asset': name,
          if (package != null) 'package': package,
          if (color != null) 'color': _encodeColor(color),
          if (size != null) 'size': size,
        };
      case WidgetWhatsNewImage():
        throw WhatsNewFormatException(
          'a widget image cannot be encoded. Use an icon or an asset.',
          path,
        );
    }
  }

  static String _encodeColor(Color color) {
    int channel(double v) => (v * 255).round().clamp(0, 255);
    final String hex = <int>[
      channel(color.a),
      channel(color.r),
      channel(color.g),
      channel(color.b),
    ].map((int c) => c.toRadixString(16).padLeft(2, '0')).join();
    return '#${hex.toUpperCase()}';
  }

  // ----------------------------------------------------------------- helpers

  static Map<String, Object?> _asMap(Object? raw, String path) {
    if (raw is Map<String, Object?>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, Object?>();
    }
    throw WhatsNewFormatException('expected an object', path);
  }

  static T _require<T>(Map<String, Object?> json, String key, String path) {
    final Object? value = json[key];
    if (value is T) {
      return value;
    }
    throw WhatsNewFormatException(
      value == null ? 'missing "$key"' : '"$key" must be a $T',
      _join(path, key),
    );
  }

  /// Reads `#RGB`, `#RRGGBB` or `#AARRGGBB`, with or without the hash.
  static Color? _color(Object? raw, String path) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return Color(raw);
    }
    if (raw is! String) {
      throw WhatsNewFormatException('expected a colour string', path);
    }
    String hex = raw.trim().replaceFirst('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((String c) => '$c$c').join();
    }
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    final int? value = hex.length == 8 ? int.tryParse(hex, radix: 16) : null;
    if (value == null) {
      throw WhatsNewFormatException(
          '"$raw" is not a colour; expected #RGB, #RRGGBB or #AARRGGBB', path);
    }
    return Color(value);
  }

  static double? _double(Object? raw, String path) {
    if (raw == null) {
      return null;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    throw WhatsNewFormatException('expected a number', path);
  }

  static String _join(String path, String key) =>
      path.isEmpty ? key : '$path.$key';
}
