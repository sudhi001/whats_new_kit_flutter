import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../models/whats_new_text.dart';

/// Renders a [WhatsNewText] and owns the lifetime of any gesture recognizers
/// its spans carry.
///
/// A [TextSpan] recognizer is a [GestureRecognizer], which registers with the
/// gesture arena and must be disposed. Building spans inline in `build` would
/// leak one recognizer per link per rebuild, so span construction is cached
/// here and the previous recognizers are disposed whenever it is redone.
class WhatsNewTextView extends StatefulWidget {
  /// Renders [text] using [style].
  const WhatsNewTextView({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  /// The text to render.
  final WhatsNewText text;

  /// The style the span is built from.
  final TextStyle style;

  /// How the text aligns within its box.
  final TextAlign textAlign;

  @override
  State<WhatsNewTextView> createState() => _WhatsNewTextViewState();
}

class _WhatsNewTextViewState extends State<WhatsNewTextView> {
  InlineSpan? _span;
  List<GestureRecognizer> _recognizers = const <GestureRecognizer>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The span may depend on inherited state, so it is rebuilt here rather
    // than in initState.
    _buildSpan();
  }

  @override
  void didUpdateWidget(WhatsNewTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.style != oldWidget.style) {
      _buildSpan();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _buildSpan() {
    _disposeRecognizers();
    final InlineSpan span = widget.text.toSpan(context, widget.style);
    _span = span;
    _recognizers = collectSpanRecognizers(span);
  }

  void _disposeRecognizers() {
    for (final GestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = const <GestureRecognizer>[];
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _span ?? widget.text.toSpan(context, widget.style),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

/// Collects every [GestureRecognizer] attached to [span] or its children.
///
/// Exposed so callers building their own spans can dispose them correctly.
List<GestureRecognizer> collectSpanRecognizers(InlineSpan span) {
  final List<GestureRecognizer> recognizers = <GestureRecognizer>[];
  span.visitChildren((InlineSpan child) {
    if (child is TextSpan) {
      final GestureRecognizer? recognizer = child.recognizer;
      if (recognizer != null) {
        recognizers.add(recognizer);
      }
    }
    return true;
  });
  return recognizers;
}
