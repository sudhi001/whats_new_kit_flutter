## 0.2.1

Documentation only. No code changed, so there is nothing to upgrade for unless
you read the README on pub.dev, which serves it from the published archive and
so still showed 0.1.0's account of several things 0.2.0 replaced.

### Fixed

- The FAQ and the "how it decides what to show" notes both said the package
  deliberately does not merge entries, and told the reader to build a combined
  sheet themselves. `WhatsNewPresentationPolicy.allMissedSince` and
  `mergeMissedEntries` have done that since 0.2.0.
- Quick start said the returned future completes when the sheet is dismissed.
  It completes with a `WhatsNewDismissal`.
- `scrollBottomContentInset` was documented as the inset. It is a floor — the
  footer's real height is measured and wins when larger, so lowering it below
  that height does nothing.
- `WhatsNewVersion.parseCompat` was described as reproducing WhatsNewKit
  exactly, without the trap that comes with it: it does not strip `+build`, so
  `'1.2.3+45'` parses to `1.2.0`.

### Added

- `minTapTargetSize`, `respectHighContrast` and `showDragHandle`, three
  `WhatsNewLayout` properties missing from the layout table.
- The `textDirection` override, `onError` and `reportWhatsNewError`,
  `WhatsNewLaunchRecordStore`, and `WhatsNewController.innerVersionStore`.
- An FAQ entry for the `MaterialLocalizations` error a `CupertinoApp` hits,
  with the delegates taken from the package's own `ErrorHint`.

## 0.2.0

Bug fixes, a release gate, and the things a shipping app needed that the
package could not do: localize its copy, take content from a server, tell an
upgrader from a first-time installer, show what a reader missed across skipped
releases, and report any of it to analytics.

### Fixed

- **Content could sit permanently behind the pinned footer.** The scroll body
  reserved a fixed 150pt for a footer whose height was never measured. A
  compact phone with a secondary action needs 197pt, so the last 47pt of
  content could not be scrolled clear — 241pt at 300% text scale, and more
  again with `WhatsNewSafeAreaBehavior.add`. The footer is now measured, and
  `WhatsNewLayout.scrollBottomContentInset` is a floor rather than the inset.
- **A concurrent `load()` silently suppressed the sheet.** The second caller
  returned early with `isLoaded` still false, so `pendingWhatsNew` answered
  null and nothing was presented. Concurrent callers now join the in-flight
  load.
- **`presentIfNeeded` could present twice.** The once-per-session guard was set
  after an await, so two callers could both pass it. This was masked by the
  `load()` bug above — fixing that alone would have exposed it.
- **Disposing a controller mid-flight threw.** `notifyListeners()` ran after
  awaits with no disposal guard, so disposing while a sheet was open crashed
  with `used after being disposed`.
- **Store failures were swallowed or escaped into the zone.** A failed write no
  longer eats `onDismiss`, an unreadable store presents the sheet rather than
  silently withholding it, and the fire-and-forget write in
  `WhatsNewView.dispose` is caught. All of it routes through a new `onError`
  hook, defaulting to `FlutterError.reportError`.
- **The cache could disagree with disk.** `CachingWhatsNewVersionStore` updated
  memory before writing, so a failed write left the sheet suppressed for the
  session and back on the next launch.
- **`WhatsNewTheme` had no `==`, despite being a `ThemeExtension`.** Any rebuild
  constructing a fresh instance made the whole `ThemeData` unequal and
  invalidated every `Theme.of` dependent. Value equality added there and on
  `WhatsNew`, `WhatsNewLayout`, both action types, `WhatsNewResolvedTheme` and
  `InlineMarkdownStyle`.
- **`WhatsNewAutoSheet.enabled` was read once.** Flipping it false-to-true — the
  usual "wait until login finishes" pattern — never presented anything.
- **A custom primary-button background could render an invisible label.** Setting
  only `backgroundColor` kept the theme's `onPrimary` label colour; the
  foreground is now derived from the background it actually sits on.
- **`WhatsNewVersion.tryParse` only validated the first component,** so a stray
  `WhatsNewKit.1.zz` preference key read back as `1.0.0` presented and
  permanently suppressed that sheet. Every component is checked, and more than
  three is rejected.
- **`stripInlineMarkdown` disagreed with the renderer.** Screen readers heard
  `"2 * 3 * 4"` as `"2  3  4"` and lost backslash escapes. It is now built on
  the parser rather than on `replaceAll`.
- **Links failed silently.** Both launch sites guarded with `canLaunchUrl`,
  which returns false on Android 11+ for any scheme missing from the app's
  `<queries>` entry and loses the user-gesture context on web. The guard is
  gone, the launch is attempted and every failure is reported.
- **Haptics could crash the zone on Windows and Linux,** where `HapticFeedback`
  is unimplemented and the returned future rejects.

### Added

- **Localization.** Leave `WhatsNewPrimaryAction.title` unset and the button
  says "Continue" in the reader's language, taken from `MaterialLocalizations`
  — no `.arb` files needed for the one string the package owns. Set
  `WhatsNewController.collectionBuilder` to supply entries per `Locale`.
- **Remote content.** `WhatsNewCodec` reads and writes entries as JSON, so
  release notes can come from remote config, a CMS or a hosted file instead of
  being compiled into the binary. Icons resolve through a `WhatsNewIcons`
  registry, which keeps them referenced from Dart and safe from tree-shaking.
  Anything that is code rather than data — `WhatsNewText.rich`,
  `WhatsNewText.builder`, `WhatsNewImage.widget`, callbacks — is refused with a
  message naming the path, rather than silently flattened.
- **`WhatsNewLinkPolicy`,** restricting which URL schemes may open. Defaults to
  `https`, `http` and `mailto`; `javascript:`, `file:`, `intent:` and `market:`
  are refused. This matters the moment content comes from anywhere but your own
  source, and `WhatsNewLinkFailure` reports every refusal and platform failure.
- **Presentation policies.** `WhatsNewPresentationPolicy.allMissedSince` merges
  every release a reader skipped into one surface — the "everything you missed"
  case, which previously had no primitive to build it from.
  `latestOnly` covers a running version no entry matches. `exactThenMinor`
  remains the default and is unchanged. `WhatsNewController.entriesSince` is
  public for building your own summary, and is the first thing in the package
  to use `WhatsNewVersion`'s comparison operators rather than equality.
- **First-install suppression.** `suppressOnFirstInstall` presents nothing to a
  reader who has never been here — "what's new" implies a "before", and a fresh
  installer has none. Needs a store implementing the new
  `WhatsNewLaunchRecordStore`, which records the version at last launch; the
  bundled stores all do.
- **`WhatsNewObserver` and `WhatsNewDismissal`.** `WhatsNewSheet.show` and
  `showWhatsNewSheet` now complete with *how* the surface closed, and the
  observer reports open and close. The information always existed; it was
  discarded.
- **`CompactWhatsNewVersionStore`,** keeping every presented version under one
  preference key instead of one per release. The bundled default reproduces
  WhatsNewKit's format, which means calling `getKeys()` — materialising every
  preference the host app owns — and growing a key per release forever. Existing
  records are imported on first run, once.
- **`WhatsNewController.innerVersionStore`,** for handing your own store to a
  second controller without wrapping the cache in another cache, and
  `isDisposed`.
- A clear error when a sheet or dialog is presented without
  `MaterialLocalizations` — a `CupertinoApp` needs
  `DefaultMaterialLocalizations.delegate` added, and Flutter's own assertion
  never says so. Everything else works inside a `CupertinoApp` already,
  including dark mode.

### Changed

- `showWhatsNewSheet` and `WhatsNewSheet.show` return
  `Future<WhatsNewDismissal>` rather than `Future<void>`. Existing `await` calls
  keep working.
- `WhatsNewPrimaryAction.title` is now nullable, defaulting to the localized
  label. `showWhatsNewSheet`'s `continueLabel` is likewise `String?`.
- `WhatsNewVersion.parseCompat` is unchanged, but now documents the trap it
  always had: it does not strip `+build` or `-prerelease`, because WhatsNewKit
  does not either, so `'1.2.3+45'` parses to `1.2.0` and `'2.0.0-beta.1'` to
  `2.0.1`. Use `WhatsNewVersion.parse` for anything the running app supplies.
- CI runs format, analyze, test and a WebAssembly build of the example on every
  pull request, and the publish workflow will not release a tag that fails them
  or whose version disagrees with the pubspec. Golden files are tagged `golden`
  and run on their own macOS job, because they only match on the platform that
  generated them.
- The published archive drops tests and the example's platform scaffolding,
  167 files down to 54.
- The example app gained a web target, so the WebAssembly claim is something a
  machine checks.

### Test suite

165 tests to 271, including the first coverage of `url_launcher` (through its
platform interface), the dialog and page presentations, and every new surface
above.

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

### Accessibility and internationalisation

- Every control clears 48pt, so Apple's 44pt minimum, Material's 48dp and
  WCAG 2.2 target size all pass. The bare text link is padded out without
  changing how it looks.
- Screen readers get one element per feature, a heading that names the route,
  and buttons announced once with the correct traits — a URL action carries the
  link trait, an in-app action does not.
- Dynamic Type is tested to 300%, Bold Text thickens every weight, and a high
  contrast preference replaces the footer blur with an opaque fill.
- The suite asserts all four of Flutter's accessibility guidelines.
- Right-to-left works without configuration: the icon column, the feature text
  and the two-column arrangement all mirror. `showWhatsNewSheet` and
  `WhatsNewSheet.show` take an optional `textDirection` for a single sheet
  whose copy is in a different script from the rest of the app.

### Notes

- Two plugin dependencies, `shared_preferences` and `url_launcher`, neither of
  whose behaviour is required — supply your own store and link handler and
  nothing calls them. WASM-compatible; all six Flutter platforms.
- Supply the app version yourself — see `WhatsNewAppVersion`. The package takes
  no `package_info_plus` dependency.
