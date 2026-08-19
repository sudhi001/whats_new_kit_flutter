import 'package:flutter/widgets.dart';

import 'whats_new_controller.dart';

/// Makes a [WhatsNewController] available to the widgets below it.
///
/// ```dart
/// WhatsNewScope(
///   controller: controller,
///   child: MaterialApp(
///     builder: (BuildContext context, Widget? child) =>
///         WhatsNewAutoSheet(child: child!),
///     home: const HomePage(),
///   ),
/// )
/// ```
class WhatsNewScope extends InheritedNotifier<WhatsNewController> {
  /// Creates a scope around [controller].
  const WhatsNewScope({
    super.key,
    required WhatsNewController controller,
    required super.child,
  }) : super(notifier: controller);

  /// The nearest controller, or `null` if there is none.
  static WhatsNewController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WhatsNewScope>()
        ?.notifier;
  }

  /// The nearest controller.
  ///
  /// Throws if no [WhatsNewScope] encloses [context].
  static WhatsNewController of(BuildContext context) {
    final WhatsNewController? controller = maybeOf(context);
    assert(
      controller != null,
      'No WhatsNewScope found above this widget. Wrap your app in a '
      'WhatsNewScope, or pass a controller explicitly.',
    );
    return controller!;
  }
}
