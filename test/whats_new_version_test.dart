import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

void main() {
  group('WhatsNewVersion.parse', () {
    test('round-trips a well-formed version', () {
      expect(WhatsNewVersion.parse('9.9.9').toString(), '9.9.9');
    });

    test('defaults missing components to zero', () {
      expect(WhatsNewVersion.parse('1'), const WhatsNewVersion(1, 0, 0));
      expect(WhatsNewVersion.parse('1.2'), const WhatsNewVersion(1, 2, 0));
      expect(WhatsNewVersion.parse(''), WhatsNewVersion.zero);
    });

    test('yields 0.0.0 for garbage, as WhatsNewKit does', () {
      expect(
        WhatsNewVersion.parse('E621E1F8-C36C-495A-93FC-0C247A3E6E5F'),
        WhatsNewVersion.zero,
      );
    });

    test('strips build metadata and pre-release suffixes', () {
      expect(WhatsNewVersion.parse('1.2.3+45'), const WhatsNewVersion(1, 2, 3));
      expect(
        WhatsNewVersion.parse('2.0.0-beta.1'),
        const WhatsNewVersion(2, 0, 0),
      );
    });

    test('keeps bad components in place rather than shifting them', () {
      // WhatsNewKit drops the bad component and shifts, yielding 1.3.0.
      expect(WhatsNewVersion.parse('1.x.3'), const WhatsNewVersion(1, 0, 3));
    });

    test('ignores components beyond the third', () {
      expect(WhatsNewVersion.parse('1.2.3.4'), const WhatsNewVersion(1, 2, 3));
    });
  });

  group('WhatsNewVersion.parseCompat', () {
    test('shifts components left, matching WhatsNewKit exactly', () {
      expect(
        WhatsNewVersion.parseCompat('1.x.3'),
        const WhatsNewVersion(1, 3, 0),
      );
    });

    test('agrees with parse on well-formed input', () {
      for (final String value in <String>['1.2.3', '0.0.1', '10.20.30']) {
        expect(
            WhatsNewVersion.parseCompat(value), WhatsNewVersion.parse(value));
      }
    });
  });

  group('WhatsNewVersion.tryParse', () {
    test('returns null for unparseable input', () {
      expect(WhatsNewVersion.tryParse(''), isNull);
      expect(WhatsNewVersion.tryParse('nope'), isNull);
    });

    test('parses valid input', () {
      expect(WhatsNewVersion.tryParse('1.2.3'), const WhatsNewVersion(1, 2, 3));
    });
  });

  group('ordering', () {
    test('sorts by major, then minor, then patch', () {
      const List<WhatsNewVersion> sorted = <WhatsNewVersion>[
        WhatsNewVersion(1, 0, 0),
        WhatsNewVersion(1, 0, 1),
        WhatsNewVersion(1, 1, 1),
        WhatsNewVersion(1, 1, 2),
        WhatsNewVersion(1, 2, 0),
        WhatsNewVersion(2, 0, 0),
        WhatsNewVersion(2, 0, 1),
        WhatsNewVersion(2, 1, 0),
      ];
      final List<WhatsNewVersion> shuffled = sorted.toList()..shuffle();
      expect(shuffled..sort(), sorted);
    });

    test('compares multi-digit components numerically', () {
      expect(
        const WhatsNewVersion(1, 10, 0) > const WhatsNewVersion(1, 9, 0),
        isTrue,
      );
    });

    test('supports the comparison operators', () {
      const WhatsNewVersion a = WhatsNewVersion(1, 0, 0);
      const WhatsNewVersion b = WhatsNewVersion(1, 0, 1);
      expect(a < b, isTrue);
      expect(a <= a, isTrue);
      expect(b > a, isTrue);
      expect(b >= b, isTrue);
    });
  });

  group('storage keys', () {
    test('uses WhatsNewKit as the prefix', () {
      expect(WhatsNewVersion.storageKeyPrefix, 'WhatsNewKit');
    });

    test('is byte-identical to WhatsNewKit', () {
      expect(const WhatsNewVersion(1, 2, 0).storageKey, 'WhatsNewKit.1.2.0');
    });
  });

  test('minorRelease resets the patch component', () {
    expect(
      const WhatsNewVersion(1, 2, 7).minorRelease,
      const WhatsNewVersion(1, 2, 0),
    );
  });
}
