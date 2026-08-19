import 'package:flutter/material.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// Demonstrates automatic presentation, and every branch of the algorithm that
/// decides whether to present.
class AutoPage extends StatefulWidget {
  /// Creates the automatic-presentation demo.
  const AutoPage({super.key});

  /// This page's route name.
  static const String routeName = '/auto';

  @override
  State<AutoPage> createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  static const List<WhatsNewVersion> _versions = <WhatsNewVersion>[
    WhatsNewVersion(1, 0, 0),
    WhatsNewVersion(1, 1, 0),
    WhatsNewVersion(1, 1, 1),
    WhatsNewVersion(1, 2, 0),
    WhatsNewVersion(2, 0, 0),
  ];

  WhatsNewVersion _pretendVersion = const WhatsNewVersion(1, 1, 1);

  /// A fresh controller per pretend-version, since the running version is fixed
  /// for a controller's lifetime.
  WhatsNewController _makeController(WhatsNewVersion version) {
    final WhatsNewController parent = WhatsNewScope.of(context);
    return WhatsNewController(
      currentVersion: version,
      collection: parent.collection,
      versionStore: parent.versionStore,
    );
  }

  Future<void> _present() async {
    final WhatsNewController controller = _makeController(_pretendVersion);
    final WhatsNew? pending = await controller.resolvePending();
    if (!mounted) {
      return;
    }
    if (pending == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nothing to present for $_pretendVersion — either it was already '
            'shown, or no entry matches it.',
          ),
        ),
      );
      return;
    }
    await controller.presentIfNeeded(context);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final WhatsNewController controller = WhatsNewScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Automatic presentation')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pick a version to pretend the app is running, then present. '
              'Declared entries are 1.0.0, 1.1.0 and 2.0.0 — so 1.1.1 falls '
              'back to the 1.1.0 sheet, and 1.2.0 matches nothing.',
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                for (final WhatsNewVersion version in _versions)
                  ChoiceChip(
                    label: Text(version.toString()),
                    selected: version == _pretendVersion,
                    onSelected: (bool _) =>
                        setState(() => _pretendVersion = version),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: _present,
              child: const Text('Present if needed'),
            ),
          ),
          const Divider(height: 40),
          ListTile(
            title: const Text('Recorded as presented'),
            subtitle: Text(
              controller.presentedVersions.isEmpty
                  ? 'Nothing yet'
                  : (controller.presentedVersions.toList()..sort()).join(', '),
            ),
            trailing: TextButton(
              onPressed: () async {
                await controller.resetPresentedVersions();
                if (context.mounted) {
                  setState(() {});
                }
              },
              child: const Text('Reset'),
            ),
          ),
        ],
      ),
    );
  }
}
