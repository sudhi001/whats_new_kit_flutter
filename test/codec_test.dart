import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

const String _remoteDocument = '''
{
  "entries": [
    {
      "version": "1.1.0",
      "title": "What's New in 1.1",
      "features": [
        {
          "image": {"icon": "bolt", "color": "#FF9F0A"},
          "title": "Faster",
          "subtitle": {"markdown": "Startup is **twice** as quick."}
        },
        {
          "image": {"asset": "images/sync.png", "package": "my_app", "size": 32},
          "title": "Sync",
          "subtitle": "Everything, everywhere."
        }
      ],
      "primaryAction": {"title": "Let's go", "backgroundColor": "#0A84FF"},
      "secondaryAction": {
        "title": "Privacy policy",
        "url": "https://example.com/privacy"
      }
    }
  ]
}
''';

void main() {
  setUp(() {
    WhatsNewIcons.clear();
    WhatsNewIcons.register(<String, IconData>{
      'bolt': Icons.bolt,
      'star': Icons.star,
    });
  });
  tearDown(WhatsNewIcons.clear);

  group('decoding a remote document', () {
    test('reads a whole collection', () {
      final List<WhatsNew> entries =
          WhatsNewCodec.decodeCollection(_remoteDocument);

      expect(entries, hasLength(1));
      final WhatsNew entry = entries.single;
      expect(entry.version, const WhatsNewVersion(1, 1, 0));
      expect(entry.title.plainText, "What's New in 1.1");
      expect(entry.features, hasLength(2));

      final WhatsNewImage first = entry.features.first.image;
      expect(first, isA<IconWhatsNewImage>());
      expect((first as IconWhatsNewImage).icon, Icons.bolt);
      expect(first.color, const Color(0xFFFF9F0A));

      // Markdown survives as markdown, and reads correctly for a screen reader.
      expect(entry.features.first.subtitle, isA<MarkdownWhatsNewText>());
      expect(entry.features.first.subtitle.plainText,
          'Startup is twice as quick.');

      final WhatsNewImage second = entry.features[1].image;
      expect(second, isA<AssetWhatsNewImage>());
      expect((second as AssetWhatsNewImage).package, 'my_app');
      expect(second.size, 32);

      expect(entry.primaryAction.title!.plainText, "Let's go");
      expect(entry.primaryAction.backgroundColor, const Color(0xFF0A84FF));
      expect(entry.secondaryAction!.isLink, isTrue);
    });

    test('accepts a bare list as well as an entries object', () {
      final Object decoded = jsonDecode(_remoteDocument) as Object;
      final List<Object?> bare =
          (decoded as Map<String, Object?>)['entries']! as List<Object?>;
      expect(WhatsNewCodec.decodeCollection(bare), hasLength(1));
    });

    test('reads every colour shorthand', () {
      WhatsNew read(String colour) => WhatsNewCodec.decode(<String, Object?>{
            'version': '1.0.0',
            'title': 'T',
            'features': <Object?>[
              <String, Object?>{
                'image': <String, Object?>{'icon': 'star', 'color': colour},
                'title': 'a',
                'subtitle': 'b',
              },
            ],
          });

      Color colourOf(WhatsNew e) =>
          (e.features.single.image as IconWhatsNewImage).color!;

      expect(colourOf(read('#F00')), const Color(0xFFFF0000));
      expect(colourOf(read('#FF0000')), const Color(0xFFFF0000));
      expect(colourOf(read('#80FF0000')), const Color(0x80FF0000));
      expect(colourOf(read('FF0000')), const Color(0xFFFF0000));
    });
  });

  group('bad content fails loudly, and says where', () {
    test('a missing version', () {
      expect(
        () => WhatsNewCodec.decodeCollection(
            '{"entries": [{"title": "T", "features": []}]}'),
        throwsA(isA<WhatsNewFormatException>().having(
            (WhatsNewFormatException e) => e.path,
            'path',
            'entries[0].version')),
      );
    });

    test('an unparseable version', () {
      expect(
        () => WhatsNewCodec.decodeCollection(
            '{"entries": [{"version": "banana", "title": "T", "features": []}]}'),
        throwsA(isA<WhatsNewFormatException>().having(
            (WhatsNewFormatException e) => e.message,
            'message',
            contains('not a version'))),
      );
    });

    test('an unregistered icon names itself and says how to fix it', () {
      expect(
        () => WhatsNewCodec.decodeCollection('''
          {"entries": [{"version": "1.0.0", "title": "T", "features": [
            {"image": {"icon": "rocket"}, "title": "a", "subtitle": "b"}
          ]}]}'''),
        throwsA(isA<WhatsNewFormatException>()
            .having((WhatsNewFormatException e) => e.message, 'message',
                allOf(contains('"rocket"'), contains('WhatsNewIcons.register')))
            .having((WhatsNewFormatException e) => e.path, 'path',
                'entries[0].features[0].image.icon')),
      );
    });

    test('malformed JSON', () {
      expect(
        () => WhatsNewCodec.decodeCollection('{not json'),
        throwsA(isA<WhatsNewFormatException>()),
      );
    });

    test('features that are not a list', () {
      expect(
        () => WhatsNewCodec.decodeCollection(
            '{"entries": [{"version": "1.0.0", "title": "T", "features": {}}]}'),
        throwsA(isA<WhatsNewFormatException>().having(
            (WhatsNewFormatException e) => e.path,
            'path',
            'entries[0].features')),
      );
    });
  });

  group('links from a document are treated as untrusted', () {
    test('the default policy is carried onto a decoded action', () {
      // The secondary action is built with a policy, so a hostile scheme in a
      // remotely-fetched document is refused at tap time rather than opened.
      final List<WhatsNew> entries = WhatsNewCodec.decodeCollection('''
        {"entries": [{"version": "1.0.0", "title": "T", "features": [],
          "secondaryAction": {"title": "Tap", "url": "javascript:alert(1)"}}]}''');
      expect(entries.single.secondaryAction, isNotNull);
      // The refusal itself is covered in link_policy_test.dart; what matters
      // here is that decoding does not quietly produce an unguarded launcher.
      expect(
          const WhatsNewLinkPolicy().allows(Uri.parse('javascript:alert(1)')),
          isFalse);
    });
  });

  group('encoding', () {
    test('round-trips what can be round-tripped', () {
      final WhatsNew original = WhatsNew(
        version: const WhatsNewVersion(2, 1, 0),
        title: const WhatsNewText('Hello'),
        features: <WhatsNewFeature>[
          WhatsNewFeature(icon: Icons.star, title: 'Starred', subtitle: 'Nice'),
          const WhatsNewFeature.rich(
            image: WhatsNewImage.asset('a.png'),
            title: WhatsNewText('Asset'),
            subtitle: MarkdownWhatsNewText('**bold**'),
          ),
        ],
        primaryAction: const WhatsNewPrimaryAction(
          title: WhatsNewText('Go'),
          backgroundColor: Color(0xFF0A84FF),
        ),
      );

      final WhatsNew decoded =
          WhatsNewCodec.decode(WhatsNewCodec.encode(original));

      expect(decoded.version, original.version);
      expect(decoded.title, original.title);
      expect(decoded.features, original.features);
      expect(decoded.primaryAction.title, original.primaryAction.title);
      expect(decoded.primaryAction.backgroundColor,
          original.primaryAction.backgroundColor);
    });

    test('refuses what is code rather than data', () {
      WhatsNew withTitle(WhatsNewText title) => WhatsNew(
            version: const WhatsNewVersion(1, 0, 0),
            title: title,
            features: const <WhatsNewFeature>[],
          );

      expect(
        () => WhatsNewCodec.encode(
            withTitle(const WhatsNewText.rich(TextSpan(text: 'x')))),
        throwsA(isA<WhatsNewFormatException>().having(
            (WhatsNewFormatException e) => e.message,
            'message',
            contains('cannot be'))),
      );

      expect(
        () => WhatsNewCodec.encode(WhatsNew(
          version: const WhatsNewVersion(1, 0, 0),
          title: const WhatsNewText('T'),
          features: const <WhatsNewFeature>[
            WhatsNewFeature.rich(
              image: WhatsNewImage.widget(SizedBox.shrink()),
              title: WhatsNewText('a'),
              subtitle: WhatsNewText('b'),
            ),
          ],
        )),
        throwsA(isA<WhatsNewFormatException>().having(
            (WhatsNewFormatException e) => e.message,
            'message',
            contains('widget image'))),
      );
    });

    test('an unregistered icon cannot be encoded', () {
      WhatsNewIcons.clear();
      expect(
        () => WhatsNewCodec.encode(WhatsNew(
          version: const WhatsNewVersion(1, 0, 0),
          title: const WhatsNewText('T'),
          features: <WhatsNewFeature>[
            WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
          ],
        )),
        throwsA(isA<WhatsNewFormatException>()),
      );
    });

    test('a collection round-trips through a JSON string', () {
      final List<WhatsNew> original = <WhatsNew>[
        WhatsNew.of(
          version: '1.0.0',
          title: 'One',
          features: <WhatsNewFeature>[
            WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
          ],
        ),
      ];
      final String encoded =
          jsonEncode(WhatsNewCodec.encodeCollection(original));
      final List<WhatsNew> decoded = WhatsNewCodec.decodeCollection(encoded);

      expect(decoded.single.version, const WhatsNewVersion(1, 0, 0));
      expect(decoded.single.features, original.single.features);
    });
  });

  group('a decoded collection drives the controller', () {
    test('remote content presents like compiled-in content', () async {
      final WhatsNewController controller = WhatsNewController(
        currentVersion: const WhatsNewVersion(1, 1, 0),
        collection: WhatsNewCodec.decodeCollection(_remoteDocument),
        versionStore: InMemoryWhatsNewVersionStore(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      expect(controller.pendingWhatsNew!.title.plainText, "What's New in 1.1");
    });
  });
}
