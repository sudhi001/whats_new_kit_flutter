import 'package:flutter/widgets.dart';

import '../models/whats_new_feature.dart';
import '../theme/whats_new_resolved_theme.dart';
import 'whats_new_text_view.dart';

/// One feature row: a fixed-width artwork column, a gap, then title and
/// subtitle.
class WhatsNewFeatureRow extends StatelessWidget {
  /// Creates a feature row.
  const WhatsNewFeatureRow({
    super.key,
    required this.feature,
    required this.theme,
  });

  /// The feature to render.
  final WhatsNewFeature feature;

  /// The resolved styling.
  final WhatsNewResolvedTheme theme;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      crossAxisAlignment: theme.layout.featureCrossAxisAlignment,
      children: <Widget>[
        SizedBox(
          width: theme.layout.featureImageWidth,
          child: Center(child: feature.image.build(context, theme)),
        ),
        SizedBox(width: theme.layout.featureHorizontalSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              WhatsNewTextView(
                text: feature.title,
                style: theme.featureTitleStyle,
              ),
              SizedBox(height: theme.layout.featureVerticalSpacing),
              WhatsNewTextView(
                text: feature.subtitle,
                style: theme.featureSubtitleStyle,
              ),
            ],
          ),
        ),
      ],
    );

    // WhatsNewKit combines each row into a single accessibility element.
    return Semantics(
      label: '${feature.title.plainText}. ${feature.subtitle.plainText}',
      container: true,
      child: ExcludeSemantics(child: row),
    );
  }
}
