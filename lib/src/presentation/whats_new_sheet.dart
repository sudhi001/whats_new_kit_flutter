import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/whats_new.dart';
import '../models/whats_new_layout.dart';
import '../store/whats_new_version_store.dart';
import '../theme/whats_new_form_factor.dart';
import '../theme/whats_new_theme.dart';
import '../view/whats_new_view.dart';
import 'whats_new_presentation.dart';

/// Presents a [WhatsNew] entry.
abstract final class WhatsNewSheet {
  /// Shows [whatsNew] and completes once it has been dismissed.
  ///
  /// When [versionStore] is given, the entry's version is recorded on *any*
  /// dismissal — the primary button, a swipe-down, a barrier tap or a system
  /// back gesture — matching WhatsNewKit, which saves in `onDisappear`. Set
  /// [markPresented] to [WhatsNewMarkPresented.primaryActionOnly] to record
  /// only a deliberate acknowledgement.
  ///
  /// With [skipIfAlreadyPresented] left on, nothing is pushed at all when the
  /// store already holds this version.
  ///
  /// Pass [textDirection] to render one sheet in a specific direction — useful
  /// when its copy is in a different script from the rest of the app.
  /// Otherwise the ambient [Directionality] applies.
  static Future<void> show(
    BuildContext context, {
    required WhatsNew whatsNew,
    WhatsNewVersionStore? versionStore,
    WhatsNewLayout? layout,
    WhatsNewTheme? theme,
    bool skipIfAlreadyPresented = true,
    WhatsNewPresentation presentation = WhatsNewPresentation.adaptive,
    WhatsNewMarkPresented markPresented = WhatsNewMarkPresented.anyDismissal,
    bool useRootNavigator = true,
    bool isDismissible = true,
    TextDirection? textDirection,
    VoidCallback? onDismiss,
  }) async {
    if (skipIfAlreadyPresented &&
        versionStore != null &&
        await versionStore.hasPresented(whatsNew.version)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    bool acknowledged = false;
    Widget buildContent(BuildContext sheetContext) {
      final Widget view = WhatsNewView(
        whatsNew: whatsNew,
        layout: layout,
        theme: theme,
        autofocusPrimaryAction:
            isDesktopPlatform(Theme.of(sheetContext).platform),
        onDismissRequested: () {
          acknowledged = true;
          final NavigatorState navigator = Navigator.of(sheetContext);
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      );
      if (textDirection == null) {
        return view;
      }
      return Directionality(textDirection: textDirection, child: view);
    }

    final WhatsNewResolvedTheme resolved =
        WhatsNewTheme.resolve(context, theme);
    final WhatsNewLayout resolvedLayout = layout ?? resolved.layout;

    await _push(
      context,
      presentation: _resolve(presentation, context, resolvedLayout),
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      builder: buildContent,
      backgroundColor: resolved.sheetBackgroundColor,
      layout: resolvedLayout,
    );

    final bool shouldRecord =
        markPresented == WhatsNewMarkPresented.anyDismissal
            ? true
            : acknowledged;
    if (versionStore != null && shouldRecord) {
      await versionStore.save(whatsNew.version);
    }
    onDismiss?.call();
  }

  static Future<void> _push(
    BuildContext context, {
    required WhatsNewPresentation presentation,
    required bool useRootNavigator,
    required bool isDismissible,
    required WidgetBuilder builder,
    required Color backgroundColor,
    required WhatsNewLayout layout,
  }) {
    switch (presentation) {
      case WhatsNewPresentation.dialog:
        return showDialog<void>(
          context: context,
          useRootNavigator: useRootNavigator,
          barrierDismissible: isDismissible,
          builder: (BuildContext dialogContext) => Dialog(
            clipBehavior: Clip.antiAlias,
            backgroundColor: backgroundColor,
            insetPadding: layout.dialogInsetPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: layout.dialogMaxWidth,
                maxHeight: layout.dialogMaxHeight,
              ),
              child: SizedBox.expand(child: builder(dialogContext)),
            ),
          ),
        );
      case WhatsNewPresentation.page:
        return Navigator.of(context, rootNavigator: useRootNavigator)
            .push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext pageContext) => Scaffold(
              backgroundColor: backgroundColor,
              body: builder(pageContext),
            ),
          ),
        );
      case WhatsNewPresentation.bottomSheet:
      case WhatsNewPresentation.adaptive:
        return showModalBottomSheet<void>(
          context: context,
          useRootNavigator: useRootNavigator,
          isScrollControlled: true,
          // Respects the top, left and right insets but not the bottom — the
          // same split WhatsNewKit gets from `edgesIgnoringSafeArea(.bottom)`,
          // so the footer's bottom padding absorbs the home indicator.
          useSafeArea: true,
          isDismissible: isDismissible,
          enableDrag: isDismissible,
          backgroundColor: backgroundColor,
          showDragHandle: layout.showDragHandle,
          clipBehavior: Clip.antiAlias,
          constraints: const BoxConstraints.expand(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(layout.sheetTopCornerRadius),
            ),
          ),
          builder: builder,
        );
    }
  }

  /// Turns [WhatsNewPresentation.adaptive] into a concrete presentation.
  ///
  /// A dialog reads better than a bottom sheet on a wide desktop or web
  /// window; everything else gets the sheet. The width threshold is
  /// `WhatsNewBreakpoints.desktopMinWidth`.
  static WhatsNewPresentation _resolve(
    WhatsNewPresentation presentation,
    BuildContext context,
    WhatsNewLayout layout,
  ) {
    if (presentation != WhatsNewPresentation.adaptive) {
      return presentation;
    }
    final TargetPlatform platform = Theme.of(context).platform;
    final bool wide =
        MediaQuery.sizeOf(context).width >= layout.breakpoints.desktopMinWidth;
    return wide && (isDesktopPlatform(platform) || kIsWeb)
        ? WhatsNewPresentation.dialog
        : WhatsNewPresentation.bottomSheet;
  }
}

/// When a presented version is recorded.
enum WhatsNewMarkPresented {
  /// On any dismissal, including a swipe-down. WhatsNewKit's behaviour, and the
  /// default: without it, a reader who swipes the sheet away sees it forever.
  anyDismissal,

  /// Only when the primary button is tapped.
  primaryActionOnly,
}
