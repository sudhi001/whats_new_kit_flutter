import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Which URLs a What's New surface is willing to open.
///
/// While release notes are compiled into the app, the URLs in them are as
/// trustworthy as the rest of the binary. The moment they come from anywhere
/// else — remote config, a CMS, a hosted changelog — they are untrusted input
/// being handed to the platform's URL opener, and `Uri.tryParse` accepts
/// `javascript:`, `file:`, `intent:` and `market:` just as happily as `https:`.
///
/// The default allows the three schemes release notes actually need.
@immutable
class WhatsNewLinkPolicy {
  /// Creates a policy allowing exactly [allowedSchemes], compared
  /// case-insensitively.
  const WhatsNewLinkPolicy({
    this.allowedSchemes = const <String>{'https', 'http', 'mailto'},
  });

  /// A policy that opens anything, restoring the pre-0.2.0 behaviour.
  ///
  /// Reasonable when every link is a literal in your own source. Not
  /// reasonable when any part of the content arrives over the network.
  const WhatsNewLinkPolicy.permissive() : allowedSchemes = const <String>{};

  /// The schemes this policy permits. Empty means "no restriction".
  final Set<String> allowedSchemes;

  /// Whether [url] may be opened.
  bool allows(Uri url) {
    if (allowedSchemes.isEmpty) {
      return true;
    }
    return allowedSchemes.contains(url.scheme.toLowerCase());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WhatsNewLinkPolicy &&
          setEquals(other.allowedSchemes, allowedSchemes);

  @override
  int get hashCode => Object.hashAll(allowedSchemes.toList()..sort());
}

/// Thrown to [WhatsNewLinkFailure] callbacks when a policy refuses a URL.
@immutable
class WhatsNewLinkRefused implements Exception {
  /// Records that [url] was refused by [policy].
  const WhatsNewLinkRefused(this.url, this.policy);

  /// The URL that was not opened.
  final Uri url;

  /// The policy that refused it.
  final WhatsNewLinkPolicy policy;

  @override
  String toString() => 'WhatsNewLinkRefused: the scheme "${url.scheme}" is not '
      'in ${policy.allowedSchemes}. Widen WhatsNewLinkPolicy.allowedSchemes if '
      'this URL is meant to open.';
}

/// Called when a link does not open.
///
/// [error] is a [WhatsNewLinkRefused] when a policy blocked it, the platform's
/// exception when the launch threw, and `null` when the platform simply
/// declined.
typedef WhatsNewLinkFailure = void Function(Uri url, Object? error);

/// Opens [url], reporting rather than swallowing every way that can fail.
///
/// Returns whether the platform accepted it.
///
/// Deliberately does not call `canLaunchUrl` first. That guard caused two
/// well-known failures and prevented neither:
///
/// * On Android 11+ it returns false for any scheme missing from the app's
///   `<queries>` manifest entry, so the link silently does nothing on a device
///   where it would have opened perfectly well.
/// * On web, awaiting it yields the event loop and loses the user-gesture
///   context, so the browser blocks the popup.
///
/// Attempting the launch and reporting the outcome is both more reliable and
/// more honest.
Future<bool> launchWhatsNewUrl(
  Uri url, {
  LaunchMode mode = LaunchMode.platformDefault,
  WhatsNewLinkPolicy policy = const WhatsNewLinkPolicy(),
  WhatsNewLinkFailure? onFailure,
}) async {
  if (!policy.allows(url)) {
    onFailure?.call(url, WhatsNewLinkRefused(url, policy));
    return false;
  }
  try {
    final bool opened = await launchUrl(url, mode: mode);
    if (!opened) {
      onFailure?.call(url, null);
    }
    return opened;
  } catch (error) {
    onFailure?.call(url, error);
    return false;
  }
}
