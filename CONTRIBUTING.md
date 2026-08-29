# Contributing

Issues and pull requests are welcome.

## Before opening a PR

```bash
dart format .
flutter analyze          # must be clean
flutter test             # must be green, goldens included
```

CI runs all three on every pull request, plus `dart pub publish --dry-run` and
a WebAssembly build of the example. It pins a specific Flutter version rather
than tracking `stable` — see below.

## Golden tests

`test/goldens/` holds twelve reference PNGs: six surfaces × light and dark.
They are host-rendered with no tolerance, so they are sensitive both to the
Flutter version and to the operating system that produced them — Linux and
macOS shape text differently enough to fail a pixel comparison.

Two things follow. CI pins `FLUTTER_VERSION` in `.github/workflows/ci.yml`; if
you upgrade Flutter, bump that pin and regenerate the goldens in the same
commit. And the goldens are tagged `golden` (see `dart_test.yaml`) so they run
on their own macOS job while everything else runs on Linux:

```bash
flutter test --exclude-tags golden   # what the Linux job runs
flutter test --tags golden           # what the macOS job runs
```

**The committed PNGs were generated on macOS.** If you regenerate them on
another platform, change `runs-on` for the `goldens` job to match, or CI will
disagree with you forever.

Regenerate with:

```bash
flutter test --update-goldens
```

**Review the diff rather than accepting it blindly.** A layout change should
move the pixels you expected it to move and nothing else. `flutter test` writes
`_masterImage`/`_testImage`/`_maskedDiff` triples into `test/goldens/failures/`
(gitignored) when a golden fails — look at those before regenerating.

## Testing what you change

The suite is organised by concern rather than by file:

| File | Covers |
| --- | --- |
| `whats_new_version_test.dart` | version parsing and ordering |
| `version_store_test.dart` | the three stores, including Swift key parity |
| `whats_new_controller_test.dart` | the presentation algorithm |
| `concurrency_test.dart` | concurrent load/present, disposal, store failures |
| `footer_occlusion_test.dart` | that content can always clear the pinned footer |
| `regression_test.dart` | fixed bugs, pinned so they stay fixed |
| `accessibility_test.dart` | the four Flutter guidelines, Dynamic Type, semantics |
| `rtl_test.dart` | mirroring, with real Arabic copy |
| `responsive_*_test.dart` | form factors, breakpoints, both arrangements |
| `lifecycle_test.dart` | gesture-recognizer ownership |

A behavioural fix should come with a test that fails without it. If you cannot
make one fail first, it is worth asking whether the bug is where you think.

## Layout changes

Every geometry constant lives on `WhatsNewLayout` and defaults to WhatsNewKit's
value. If you need a new one, add it there with a default rather than hard
coding it in a widget — the layout playground in the example app is wired to
these, and so are the responsive tests.

## Scope

This package is a port. When Flutter and WhatsNewKit disagree, the README's
"Migrating from WhatsNewKit" section records which way each call went and why.
A PR that changes one of those decisions should update that table too.
