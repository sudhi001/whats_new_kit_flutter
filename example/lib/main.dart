import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

import 'examples.dart';
import 'pages/auto_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // How a real app supplies its version: read it from the bundle once, here.
  // The package itself takes no plugin dependency for this.
  WhatsNewAppVersion.resolver = () async =>
      (await PackageInfo.fromPlatform()).version;

  // The demo then overrides it, so every branch of the presentation algorithm
  // can be exercised by hand. Delete this line in a real app.
  WhatsNewAppVersion.overrideCurrent(const WhatsNewVersion(1, 1, 1));

  runApp(const ExampleApp());
}

/// The example app. Dark by default, with a toggle so the theme-derived colors
/// can be seen adapting.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = const Color(0xFF0A84FF);
  late final WhatsNewController _controller = WhatsNewController(
    collection: Examples.collection,
    versionStore: InMemoryWhatsNewVersionStore(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    // The sheet takes every colour from the scheme, so matching Apple's system
    // palette here is all it takes to reproduce the WhatsNewKit screenshots.
    // Material 3 would otherwise remap the seed to a tonal shade.
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: brightness,
        ).copyWith(
          primary: _seedColor,
          onPrimary: Colors.white,
          surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          onSurface: isDark ? Colors.white : Colors.black,
          onSurfaceVariant: isDark
              ? const Color(0xFF98989F)
              : const Color(0xFF6C6C70),
        );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      // Resolves the system font to SF on Apple platforms, so the type matches
      // the WhatsNewKit screenshots.
      typography: Typography.material2021(platform: TargetPlatform.iOS),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WhatsNewScope(
      controller: _controller,
      child: MaterialApp(
        title: 'WhatsNewKit for Flutter',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _themeMode,
        home: HomePage(
          themeMode: _themeMode,
          seedColor: _seedColor,
          onThemeModeChanged: (ThemeMode mode) =>
              setState(() => _themeMode = mode),
          onSeedColorChanged: (Color color) =>
              setState(() => _seedColor = color),
        ),
        routes: <String, WidgetBuilder>{
          AutoPage.routeName: (BuildContext context) => const AutoPage(),
        },
      ),
    );
  }
}
