import 'package:flutter/material.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

import '../examples.dart';
import 'auto_page.dart';
import 'layout_playground_page.dart';

/// The example app's index.
class HomePage extends StatelessWidget {
  /// Creates the index page.
  const HomePage({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
  });

  /// The theme mode currently in force.
  final ThemeMode themeMode;

  /// The seed the app's color scheme is built from.
  final Color seedColor;

  /// Called when the reader flips the theme.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Called when the reader picks a different seed color.
  final ValueChanged<Color> onSeedColorChanged;

  static const List<Color> _seeds = <Color>[
    Color(0xFF0A84FF),
    Color(0xFFFF3B30),
    Color(0xFF32ADE6),
    Color(0xFF34C759),
    Color(0xFFAF52DE),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New Kit"),
        actions: <Widget>[
          IconButton(
            tooltip: isDark ? 'Switch to light' : 'Switch to dark',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                onThemeModeChanged(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          const _SectionHeader('The one-liner'),
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('showWhatsNewSheet'),
            subtitle: const Text('Icons and strings, no model types'),
            onTap: () => showWhatsNewSheet(
              context,
              version: '1.0.0',
              title: "What's New",
              features: <WhatsNewFeature>[
                WhatsNewFeature(
                  icon: Icons.history,
                  title: 'Time Machine',
                  subtitle: 'Travel back in time.',
                ),
                WhatsNewFeature(
                  icon: Icons.bolt,
                  title: 'Faster Everything',
                  subtitle: 'Twice the speed, half the battery.',
                ),
              ],
              onContinue: () {},
            ),
          ),
          const _SectionHeader('Reference sheets'),
          _ExampleTile(
            icon: Icons.auto_awesome,
            title: 'WhatsNewKit',
            subtitle: 'Four features, secondary link, haptics',
            whatsNew: Examples.whatsNewKit,
          ),
          _ExampleTile(
            icon: Icons.calendar_today,
            title: 'Calendar',
            subtitle: 'Red accent, no secondary action',
            whatsNew: Examples.calendar,
          ),
          _ExampleTile(
            icon: Icons.map_outlined,
            title: 'Maps',
            subtitle: 'Mixed icon colors, privacy link',
            whatsNew: Examples.maps,
          ),
          _ExampleTile(
            icon: Icons.translate,
            title: 'Translate',
            subtitle: 'Two-tone title built from spans',
            whatsNew: Examples.translate,
          ),
          const _SectionHeader('Behaviour'),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Automatic presentation'),
            subtitle: const Text('Version picker, store inspector, reset'),
            onTap: () => Navigator.of(context).pushNamed(AutoPage.routeName),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Layout playground'),
            subtitle: const Text('Every geometry constant, live'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const LayoutPlaygroundPage(),
              ),
            ),
          ),
          const _SectionHeader('Accent color'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Wrap(
              spacing: 12,
              children: <Widget>[
                for (final Color seed in _seeds)
                  GestureDetector(
                    onTap: () => onSeedColorChanged(seed),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: seed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: seed == seedColor
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.whatsNew,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WhatsNew whatsNew;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => WhatsNewSheet.show(context, whatsNew: whatsNew),
    );
  }
}
