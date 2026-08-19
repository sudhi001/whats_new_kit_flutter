## 0.1.0

Initial release — a Flutter port of
[WhatsNewKit](https://github.com/SvenTiigi/WhatsNewKit).

### Presenting

- `showWhatsNewSheet` for the common case, `WhatsNewSheet.show` for a full
  model, and `WhatsNewView` to embed the content in a page of your own.
- `WhatsNewPresentation` picks a bottom sheet, dialog or full page, and adapts
  between them by window size.
- Secondary actions: `openUrl`, `dismiss`, `present`, or your own callback.
  Haptics on either action.

### Deciding what to show

- `WhatsNewController`, `WhatsNewScope` and `WhatsNewAutoSheet` show one sheet
  per release, once — WhatsNewKit's algorithm ported exactly, including the
  `major.minor.0` fallback and recording a swipe-down as seen.
- `WhatsNewVersion` with positional parsing, `+build` / `-prerelease`
  stripping, and storage keys byte-identical to the Swift package's, so a
  migrating app keeps its history.
- Version stores backed by `shared_preferences` or memory, a caching decorator
  for synchronous decisions, and a base class to back it with anything else.

### Looking right

- Every geometry constant from `WhatsNew.Layout`, the pinned blur-backed footer
  with its 10pt overhang, and the size-class padding branches mapped onto
  Flutter breakpoints. Verified against the original to the pixel on a phone.
- Responsive beyond the original: the content column is capped and centred so
  tablet text keeps a readable line length, and a wide, short surface — a
  landscape phone, a landscape tablet — splits into a title column beside a
  scrolling feature column. Both are configurable, and
  `maxContentWidth: double.infinity` with
  `contentLayout: WhatsNewContentLayout.single` restores WhatsNewKit exactly.
- Sizing is measured from the surface, not the screen, so split views, resized
  desktop windows and embedded use all lay out correctly.
- All colours derived from `ColorScheme`, overridable per call or app-wide via
  a `WhatsNewTheme` extension.
- Rich text through inline Markdown or explicit spans, with recognizer
  lifetimes managed so links do not leak.

### Notes

- No required plugin dependencies; WASM-compatible; all six Flutter platforms.
- Supply the app version yourself — see `WhatsNewAppVersion`. The package takes
  no `package_info_plus` dependency.
