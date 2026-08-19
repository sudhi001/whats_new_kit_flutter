import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// Fixed surfaces covering every padding branch and both arrangements.
const Map<String, Size> _surfaces = <String, Size>{
  'phone-portrait': Size(393, 852),
  'phone-landscape': Size(852, 393),
  'tablet-portrait': Size(1024, 1366),
  'tablet-landscape': Size(1366, 1024),
  'split-view-narrow': Size(507, 1024),
  'desktop': Size(1440, 900),
};

WhatsNew _sample() {
  return WhatsNew(
    version: const WhatsNewVersion(1, 0, 0),
    title: const WhatsNewText("What's New"),
    features: <WhatsNewFeature>[
      WhatsNewFeature(
        icon: Icons.star,
        title: 'Showcase your new App Features',
        subtitle: 'Present your new app features just like a native app.',
      ),
      WhatsNewFeature(
        icon: Icons.auto_awesome,
        title: 'Automatic Presentation',
        subtitle: 'Declare a WhatsNew per version and present it for you.',
      ),
      WhatsNewFeature(
        icon: Icons.settings,
        title: 'Configuration',
        subtitle: 'Adjust colors, strings, haptics and the whole layout.',
      ),
    ],
    secondaryAction: WhatsNewSecondaryAction(
      title: const WhatsNewText('Learn more'),
      onPressed: (WhatsNewActionContext action) {},
    ),
  );
}

ThemeData _theme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A84FF),
      brightness: brightness,
    ).copyWith(
      primary: const Color(0xFF0A84FF),
      onPrimary: Colors.white,
      surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      onSurface: isDark ? Colors.white : Colors.black,
      onSurfaceVariant:
          isDark ? const Color(0xFF98989F) : const Color(0xFF6C6C70),
    ),
    useMaterial3: true,
  );
}

void main() {
  for (final MapEntry<String, Size> surface in _surfaces.entries) {
    for (final Brightness brightness in Brightness.values) {
      testWidgets('${surface.key} ${brightness.name}',
          (WidgetTester tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = surface.value;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(
          theme: _theme(brightness),
          debugShowCheckedModeBanner: false,
          home: WhatsNewView(whatsNew: _sample()),
        ));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(WhatsNewView),
          matchesGoldenFile(
            'images/whats_new_view.${surface.key}.${brightness.name}.png',
          ),
        );
      });
    }
  }
}
