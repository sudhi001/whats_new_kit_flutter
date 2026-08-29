import 'package:flutter/foundation.dart';

/// Called when a What's New surface hits an error it cannot act on.
///
/// The package never throws these at the caller — a failed store write or a
/// link that will not open must not take the app down — so without a reporter
/// they would be invisible. See [reportWhatsNewError] for the default.
typedef WhatsNewErrorReporter = void Function(
  Object error,
  StackTrace stackTrace,
);

/// The default [WhatsNewErrorReporter].
///
/// Routes to [FlutterError.reportError], so the failure reaches the same place
/// as every other framework error — the console in debug, and whatever
/// `FlutterError.onError` is wired to in release.
void reportWhatsNewError(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'whats_new_kit_flutter',
      context: ErrorDescription('while presenting a What\'s New surface'),
    ),
  );
}
