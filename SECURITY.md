# Security Policy

## Supported versions

The latest published version on [pub.dev](https://pub.dev/packages/whats_new_kit_flutter)
is the only supported one.

## Reporting a vulnerability

Please report privately through
[GitHub's security advisories](https://github.com/sudhi001/whats_new_kit_flutter/security/advisories/new)
rather than opening a public issue. You can expect an acknowledgement within a
week.

## Scope

This is a UI package with no network layer, no credential handling and no
platform code of its own. The parts worth scrutiny are:

- **Link handling.** `WhatsNewSecondaryAction.openUrl` and inline-Markdown
  `[label](url)` links open URLs through `url_launcher`. The URLs come from
  whatever content you pass in. If you ever drive that content from a server,
  a CMS or remote config, treat the URLs as untrusted input — the package does
  not currently restrict the scheme, so validate before handing them over, or
  replace the handler with `WhatsNewTheme.onMarkdownLinkTap`.
- **Version storage.** The bundled store writes to `shared_preferences`, which
  is not encrypted on any platform. It holds only version numbers already
  visible in the app bundle.
