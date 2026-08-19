/// How a What's New surface is presented.
enum WhatsNewPresentation {
  /// A modal sheet rising from the bottom edge, matching iOS.
  bottomSheet,

  /// A centered dialog, which reads better on a wide desktop window.
  dialog,

  /// A full page pushed onto the navigator.
  page,

  /// [bottomSheet] on phones and tablets, [dialog] on desktop and wide web.
  adaptive,
}
