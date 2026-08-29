import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// Replaces the url_launcher platform implementation, so the launch path
/// itself is tested rather than only the theme override wrapped around it.
class _LauncherSpy extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  final List<String> launched = <String>[];
  bool succeed = true;
  Object? throwOnLaunch;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    if (throwOnLaunch != null) {
      throw throwOnLaunch!;
    }
    launched.add(url);
    return succeed;
  }

  void install() => UrlLauncherPlatform.instance = this;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsNewLinkPolicy', () {
    const WhatsNewLinkPolicy standard = WhatsNewLinkPolicy();

    test('permits the schemes release notes actually use', () {
      expect(standard.allows(Uri.parse('https://example.com')), isTrue);
      expect(standard.allows(Uri.parse('http://example.com')), isTrue);
      expect(standard.allows(Uri.parse('mailto:a@example.com')), isTrue);
    });

    test('refuses the ones remote content could smuggle in', () {
      expect(standard.allows(Uri.parse('javascript:alert(1)')), isFalse);
      expect(standard.allows(Uri.parse('file:///etc/passwd')), isFalse);
      expect(standard.allows(Uri.parse('intent://scan#Intent;end')), isFalse);
      expect(standard.allows(Uri.parse('market://details?id=x')), isFalse);
    });

    test('scheme comparison is case-insensitive', () {
      expect(standard.allows(Uri.parse('HTTPS://example.com')), isTrue);
      expect(standard.allows(Uri.parse('JavaScript:alert(1)')), isFalse);
    });

    test('a custom set replaces the default outright', () {
      const WhatsNewLinkPolicy telOnly =
          WhatsNewLinkPolicy(allowedSchemes: <String>{'tel'});
      expect(telOnly.allows(Uri.parse('tel:+15551234')), isTrue);
      expect(telOnly.allows(Uri.parse('https://example.com')), isFalse);
    });

    test('permissive allows anything', () {
      const WhatsNewLinkPolicy any = WhatsNewLinkPolicy.permissive();
      expect(any.allows(Uri.parse('javascript:alert(1)')), isTrue);
      expect(any.allows(Uri.parse('https://example.com')), isTrue);
    });

    test('compares by value', () {
      expect(const WhatsNewLinkPolicy(), const WhatsNewLinkPolicy());
      expect(const WhatsNewLinkPolicy().hashCode,
          const WhatsNewLinkPolicy().hashCode);
      expect(const WhatsNewLinkPolicy(),
          isNot(const WhatsNewLinkPolicy.permissive()));
    });
  });

  group('launchWhatsNewUrl', () {
    late _LauncherSpy spy;

    setUp(() {
      spy = _LauncherSpy()..install();
    });

    test('opens an allowed URL', () async {
      expect(await launchWhatsNewUrl(Uri.parse('https://example.com')), isTrue);
      expect(spy.launched, <String>['https://example.com']);
    });

    test('a refused URL never reaches the platform', () async {
      Object? reported;
      final bool opened = await launchWhatsNewUrl(
        Uri.parse('javascript:alert(1)'),
        onFailure: (Uri _, Object? error) => reported = error,
      );

      expect(opened, isFalse);
      expect(spy.launched, isEmpty, reason: 'it must not be handed to the OS');
      expect(reported, isA<WhatsNewLinkRefused>());
      expect(reported.toString(), contains('javascript'));
    });

    test('a platform that declines is reported, not swallowed', () async {
      spy.succeed = false;
      Uri? failed;
      final bool opened = await launchWhatsNewUrl(
        Uri.parse('https://example.com'),
        onFailure: (Uri url, Object? _) => failed = url,
      );

      expect(opened, isFalse);
      expect(failed, Uri.parse('https://example.com'));
    });

    test('a throwing platform is caught and reported', () async {
      spy.throwOnLaunch = PlatformException(code: 'ACTIVITY_NOT_FOUND');
      Object? reported;
      final bool opened = await launchWhatsNewUrl(
        Uri.parse('https://example.com'),
        onFailure: (Uri _, Object? error) => reported = error,
      );

      expect(opened, isFalse,
          reason: 'a missing handler must not become an unhandled async error');
      expect(reported, isA<PlatformException>());
    });
  });

  group('WhatsNewSecondaryAction.openUrl', () {
    late _LauncherSpy spy;

    setUp(() {
      spy = _LauncherSpy()..install();
    });

    testWidgets('tapping the link opens it', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew(
            version: const WhatsNewVersion(1, 0, 0),
            title: const WhatsNewText("What's New"),
            features: <WhatsNewFeature>[
              WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
            ],
            secondaryAction: WhatsNewSecondaryAction.openUrl(
              title: 'Privacy policy',
              url: Uri.parse('https://example.com/privacy'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();

      expect(spy.launched, <String>['https://example.com/privacy']);
    });

    testWidgets('a refused scheme reports instead of doing nothing',
        (WidgetTester tester) async {
      Object? reported;
      await tester.pumpWidget(MaterialApp(
        home: WhatsNewView(
          whatsNew: WhatsNew(
            version: const WhatsNewVersion(1, 0, 0),
            title: const WhatsNewText("What's New"),
            features: <WhatsNewFeature>[
              WhatsNewFeature(icon: Icons.star, title: 'a', subtitle: 'b'),
            ],
            secondaryAction: WhatsNewSecondaryAction.openUrl(
              title: 'Open',
              url: Uri.parse('javascript:alert(1)'),
              onFailure: (Uri _, Object? error) => reported = error,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(spy.launched, isEmpty);
      expect(reported, isA<WhatsNewLinkRefused>());
    });
  });
}
