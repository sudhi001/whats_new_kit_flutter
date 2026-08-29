import '../models/whats_new.dart';

/// How a What's New surface was closed.
enum WhatsNewDismissal {
  /// The reader tapped the primary button.
  primaryAction,

  /// The surface was closed some other way — a swipe-down, a barrier tap, a
  /// system back gesture, a secondary action that popped the route, or
  /// navigation elsewhere in the app.
  ///
  /// These are deliberately not distinguished. A modal route reports that it
  /// popped, not why, and inferring a reason from that would be guesswork
  /// presented as data.
  dismissed,
}

/// Watches What's New surfaces come and go.
///
/// Release notes are the sort of thing product owners want numbers for — how
/// many readers saw the sheet, and how many read it rather than swiping it
/// away. The surface already knows both; before this it discarded them.
///
/// ```dart
/// WhatsNewController(
///   observer: WhatsNewObserver(
///     onPresented: (WhatsNew entry) =>
///         analytics.log('whats_new_shown', version: '${entry.version}'),
///     onDismissed: (WhatsNew entry, WhatsNewDismissal how) =>
///         analytics.log('whats_new_closed', acknowledged: how.isAcknowledged),
///   ),
/// )
/// ```
class WhatsNewObserver {
  /// Creates an observer. Every callback is optional.
  const WhatsNewObserver({this.onPresented, this.onDismissed});

  /// Called once the surface has been pushed.
  final void Function(WhatsNew whatsNew)? onPresented;

  /// Called once the surface has closed, with how it closed.
  ///
  /// Runs before the presented version is recorded, and runs even when
  /// recording fails.
  final void Function(WhatsNew whatsNew, WhatsNewDismissal dismissal)?
      onDismissed;
}

/// Convenience for reading a [WhatsNewDismissal].
extension WhatsNewDismissalX on WhatsNewDismissal {
  /// Whether the reader deliberately acknowledged the surface.
  bool get isAcknowledged => this == WhatsNewDismissal.primaryAction;
}
