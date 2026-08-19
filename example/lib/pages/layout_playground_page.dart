import 'package:flutter/material.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

import '../examples.dart';

/// Drives every geometry constant live, so the layout can be compared against
/// the WhatsNewKit screenshots without editing code.
class LayoutPlaygroundPage extends StatefulWidget {
  /// Creates the playground.
  const LayoutPlaygroundPage({super.key});

  @override
  State<LayoutPlaygroundPage> createState() => _LayoutPlaygroundPageState();
}

class _LayoutPlaygroundPageState extends State<LayoutPlaygroundPage> {
  double _contentTopPadding = 65;
  double _contentSpacing = 60;
  double _featureListSpacing = 25;
  double _featureImageWidth = 40;
  double _cornerRadius = 14;
  double _blurBleed = 10;
  WhatsNewFooterBackground _footerBackground = WhatsNewFooterBackground.blur;

  WhatsNewLayout get _layout => WhatsNewLayout(
    contentPadding: EdgeInsets.only(top: _contentTopPadding),
    contentSpacing: _contentSpacing,
    featureListSpacing: _featureListSpacing,
    featureImageWidth: _featureImageWidth,
    footerPrimaryButtonCornerRadius: _cornerRadius,
    footerBlurBleed: _blurBleed,
    footerBackground: _footerBackground,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layout playground')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FilledButton(
            onPressed: () => WhatsNewSheet.show(
              context,
              whatsNew: Examples.whatsNewKit,
              layout: _layout,
            ),
            child: const Text('Present with these values'),
          ),
          const SizedBox(height: 8),
          _slider(
            'contentPadding.top',
            _contentTopPadding,
            0,
            160,
            (double v) => setState(() => _contentTopPadding = v),
          ),
          _slider(
            'contentSpacing',
            _contentSpacing,
            0,
            160,
            (double v) => setState(() => _contentSpacing = v),
          ),
          _slider(
            'featureListSpacing',
            _featureListSpacing,
            0,
            80,
            (double v) => setState(() => _featureListSpacing = v),
          ),
          _slider(
            'featureImageWidth',
            _featureImageWidth,
            20,
            120,
            (double v) => setState(() => _featureImageWidth = v),
          ),
          _slider(
            'button corner radius',
            _cornerRadius,
            0,
            40,
            (double v) => setState(() => _cornerRadius = v),
          ),
          _slider(
            'footer blur bleed',
            _blurBleed,
            0,
            60,
            (double v) => setState(() => _blurBleed = v),
          ),
          const SizedBox(height: 8),
          SegmentedButton<WhatsNewFooterBackground>(
            segments: const <ButtonSegment<WhatsNewFooterBackground>>[
              ButtonSegment<WhatsNewFooterBackground>(
                value: WhatsNewFooterBackground.blur,
                label: Text('Blur'),
              ),
              ButtonSegment<WhatsNewFooterBackground>(
                value: WhatsNewFooterBackground.solid,
                label: Text('Solid'),
              ),
              ButtonSegment<WhatsNewFooterBackground>(
                value: WhatsNewFooterBackground.none,
                label: Text('None'),
              ),
            ],
            selected: <WhatsNewFooterBackground>{_footerBackground},
            onSelectionChanged: (Set<WhatsNewFooterBackground> selection) =>
                setState(() => _footerBackground = selection.first),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label — ${value.toStringAsFixed(0)}'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
