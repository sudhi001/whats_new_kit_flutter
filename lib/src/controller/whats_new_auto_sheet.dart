import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/whats_new_layout.dart';
import '../presentation/whats_new_presentation.dart';
import '../presentation/whats_new_sheet.dart';
import '../theme/whats_new_theme.dart';
import 'whats_new_controller.dart';
import 'whats_new_scope.dart';

/// Presents the pending What's New entry, if any, when the app starts.
///
/// This is the port of WhatsNewKit's `.whatsNewSheet()` modifier. Wrap your
/// first page with it, the same way the Swift original attaches to a root
/// content view:
///
/// ```dart
/// MaterialApp(
///   home: WhatsNewAutoSheet(child: HomePage()),
/// )
/// ```
///
/// It presents through the enclosing [Navigator], so it has to sit below one.
/// `MaterialApp.builder` runs *above* the navigator it builds, so if you would
/// rather install it there, give the app a [GlobalKey] and hand the same key to
/// [navigatorKey]:
///
/// ```dart
/// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
///
/// MaterialApp(
///   navigatorKey: navigatorKey,
///   builder: (BuildContext context, Widget? child) =>
///       WhatsNewAutoSheet(navigatorKey: navigatorKey, child: child!),
///   home: const HomePage(),
/// )
/// ```
///
/// While the app version and the version store are still resolving, [child] is
/// rendered untouched — there is no loading state and no flash. If resolution
/// fails, nothing is presented and the error is left on
/// [WhatsNewController.loadError].
class WhatsNewAutoSheet extends StatefulWidget {
  /// Wraps [child] with automatic presentation.
  const WhatsNewAutoSheet({
    super.key,
    required this.child,
    this.enabled = true,
    this.controller,
    this.navigatorKey,
    this.layout,
    this.theme,
    this.presentation = WhatsNewPresentation.adaptive,
    this.markPresented = WhatsNewMarkPresented.anyDismissal,
    this.delay = Duration.zero,
    this.onDismiss,
  });

  /// The app content.
  final Widget child;

  /// Whether to present at all. Set false to suppress it conditionally.
  final bool enabled;

  /// The controller to consult. Defaults to the enclosing [WhatsNewScope].
  final WhatsNewController? controller;

  /// The navigator to present through.
  ///
  /// Only needed when this widget sits above the navigator — see the class
  /// documentation. Left null, the enclosing [Navigator] is used.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Overrides the surface geometry.
  final WhatsNewLayout? layout;

  /// Overrides the styling.
  final WhatsNewTheme? theme;

  /// How the surface is presented.
  final WhatsNewPresentation presentation;

  /// When a presented version is recorded.
  final WhatsNewMarkPresented markPresented;

  /// How long to wait after the first frame before presenting.
  ///
  /// A short delay lets an opening animation or splash screen settle first.
  final Duration delay;

  /// Called once the surface has been dismissed.
  final VoidCallback? onDismiss;

  @override
  State<WhatsNewAutoSheet> createState() => _WhatsNewAutoSheetState();
}

class _WhatsNewAutoSheetState extends State<WhatsNewAutoSheet> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scheduled && widget.enabled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        unawaited(_present());
      });
    }
  }

  Future<void> _present() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (!mounted) {
      return;
    }
    final WhatsNewController? controller =
        widget.controller ?? WhatsNewScope.maybeOf(context);
    if (controller == null) {
      return;
    }
    final BuildContext presentContext =
        widget.navigatorKey?.currentContext ?? context;
    if (!presentContext.mounted) {
      return;
    }
    await controller.presentIfNeeded(
      presentContext,
      layout: widget.layout,
      theme: widget.theme,
      presentation: widget.presentation,
      markPresented: widget.markPresented,
      onDismiss: widget.onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
