import 'package:flutter/material.dart';
import 'package:whats_new_kit_flutter/whats_new_kit_flutter.dart';

/// Rebuilds of the sheets shipped in WhatsNewKit's own example app, so the
/// Flutter port can be compared against the reference screenshots side by side.
abstract final class Examples {
  /// The package's own sheet: four features and a "Learn more" link.
  static WhatsNew get whatsNewKit => WhatsNew(
    version: const WhatsNewVersion(1, 0, 0),
    title: const WhatsNewText('WhatsNewKit'),
    features: <WhatsNewFeature>[
      WhatsNewFeature(
        icon: Icons.star,
        iconColor: const Color(0xFFFF9500),
        title: 'Showcase your new App Features',
        subtitle:
            'Present your new app features just like a native app from '
            'Apple.',
      ),
      const WhatsNewFeature.rich(
        image: WhatsNewImage.icon(Icons.auto_awesome, color: Color(0xFF32ADE6)),
        title: WhatsNewText('Automatic Presentation'),
        subtitle: WhatsNewText.markdown(
          'Simply declare a WhatsNew per Version and present it '
          'automatically by using the `WhatsNewAutoSheet` widget.',
        ),
      ),
      WhatsNewFeature(
        icon: Icons.settings,
        iconColor: const Color(0xFF8E8E93),
        title: 'Configuration',
        subtitle:
            'Easily adjust colors, strings, haptic feedback, '
            'behaviours and the layout of the presented sheet to your '
            'needs.',
      ),
      WhatsNewFeature(
        icon: Icons.flutter_dash,
        iconColor: const Color(0xFF54C5F8),
        title: 'Pub Package',
        subtitle:
            'Add whats_new_kit_flutter to your pubspec and you are '
            'done.',
      ),
    ],
    primaryAction: const WhatsNewPrimaryAction(
      haptic: WhatsNewHaptic.notification(),
    ),
    secondaryAction: WhatsNewSecondaryAction.openUrl(
      title: 'Learn more',
      url: Uri.parse('https://github.com/SvenTiigi/WhatsNewKit'),
      haptic: const WhatsNewHaptic.selection(),
    ),
  );

  /// Apple's Calendar sheet: red throughout, no secondary action.
  static WhatsNew get calendar {
    const Color red = Color(0xFFFF3B30);
    return WhatsNew(
      version: const WhatsNewVersion(2, 0, 0),
      title: const WhatsNewText("What's New\nin Calendar"),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.mail_outline,
          iconColor: red,
          title: 'Found Events',
          subtitle:
              'Siri suggests events found in Mail, Messages, and Safari, '
              'so you can add them easily, such as flight reservations and '
              'hotel bookings.',
        ),
        WhatsNewFeature(
          icon: Icons.schedule,
          iconColor: red,
          title: 'Time to Leave',
          subtitle:
              'Calendar uses Apple Maps to look up locations, traffic '
              "conditions, and transit options to tell you when it's time to "
              'leave.',
        ),
        WhatsNewFeature(
          icon: Icons.near_me_outlined,
          iconColor: red,
          title: 'Location Suggestions',
          subtitle:
              'Calendar suggests locations based on your past events and '
              'significant locations.',
        ),
      ],
      primaryAction: const WhatsNewPrimaryAction(backgroundColor: red),
    );
  }

  /// Apple's Maps sheet: mixed icon colors and a privacy link.
  static WhatsNew get maps {
    const Color blue = Color(0xFF007AFF);
    return WhatsNew(
      version: const WhatsNewVersion(2, 1, 0),
      title: const WhatsNewText("What's New in Maps"),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.map,
          iconColor: const Color(0xFF34C759),
          title: 'Updated Map Style',
          subtitle:
              'An improved design makes it easier to navigate and '
              'explore the map.',
        ),
        WhatsNewFeature(
          icon: Icons.location_on,
          iconColor: const Color(0xFFFF2D55),
          title: 'All-New Place Cards',
          subtitle:
              'Completely redesigned place cards make it easier to learn '
              'about and interact with places.',
        ),
        WhatsNewFeature(
          icon: Icons.search,
          iconColor: blue,
          title: 'Improved Search',
          subtitle:
              'Finding places is now easier with filters and automatic '
              'updates when you are browsing results on the map.',
        ),
      ],
      primaryAction: const WhatsNewPrimaryAction(backgroundColor: blue),
      secondaryAction: WhatsNewSecondaryAction.openUrl(
        title: 'About Apple Maps & Privacy',
        url: Uri.parse('https://www.apple.com/legal/privacy/'),
        foregroundColor: blue,
      ),
    );
  }

  /// Apple's Translate sheet, whose title is two-tone — the case WhatsNewKit
  /// covers with an `AttributedString`.
  static WhatsNew get translate {
    const Color cyan = Color(0xFF32ADE6);
    return WhatsNew(
      version: const WhatsNewVersion(2, 2, 0),
      title: const WhatsNewText.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: "What's New\nin "),
            TextSpan(
              text: 'Translate',
              style: TextStyle(color: cyan),
            ),
          ],
        ),
        semanticsLabel: "What's New in Translate",
      ),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.chat_bubble_outline,
          iconColor: cyan,
          title: 'Conversation Views',
          subtitle: 'Choose a side-by-side or face-to-face conversation view.',
        ),
        WhatsNewFeature(
          icon: Icons.mic_none,
          iconColor: cyan,
          title: 'Auto Translate',
          subtitle:
              'Respond in conversations without tapping the microphone '
              'button.',
        ),
        WhatsNewFeature(
          icon: Icons.phone_iphone,
          iconColor: cyan,
          title: 'System-Wide Translation',
          subtitle: 'Translate selected text anywhere on your iPhone.',
        ),
      ],
      primaryAction: const WhatsNewPrimaryAction(backgroundColor: cyan),
      secondaryAction: WhatsNewSecondaryAction.openUrl(
        title: 'About Translation & Privacy',
        url: Uri.parse('https://www.apple.com/legal/privacy/'),
        foregroundColor: cyan,
      ),
    );
  }

  /// An Arabic sheet, to show the layout mirroring for right-to-left scripts.
  static WhatsNew get arabic {
    const Color teal = Color(0xFF30D158);
    return WhatsNew(
      version: const WhatsNewVersion(2, 3, 0),
      title: const WhatsNewText('ما الجديد'),
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.star,
          iconColor: teal,
          title: 'ميزات جديدة',
          subtitle: 'اعرض ميزات تطبيقك الجديدة تمامًا مثل تطبيقات أبل.',
        ),
        WhatsNewFeature(
          icon: Icons.auto_awesome,
          iconColor: teal,
          title: 'عرض تلقائي',
          subtitle: 'أعلن عن إصدار جديد وسيُعرض تلقائيًا مرة واحدة فقط.',
        ),
        WhatsNewFeature(
          icon: Icons.settings,
          iconColor: teal,
          title: 'قابل للتخصيص',
          subtitle: 'عدّل الألوان والنصوص والتخطيط بالكامل حسب احتياجك.',
        ),
      ],
      primaryAction: const WhatsNewPrimaryAction(
        title: WhatsNewText('متابعة'),
        backgroundColor: teal,
      ),
      secondaryAction: WhatsNewSecondaryAction.openUrl(
        title: 'اعرف المزيد',
        url: Uri.parse('https://github.com/sudhi001/whats_new_kit_flutter'),
        foregroundColor: teal,
      ),
    );
  }

  /// The release history used by the automatic-presentation demo.
  static List<WhatsNew> get collection => <WhatsNew>[
    WhatsNew.of(
      version: '1.0.0',
      title: 'Welcome',
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.waving_hand_outlined,
          title: 'Hello',
          subtitle: 'This is the sheet a first-time reader sees.',
        ),
      ],
    ),
    WhatsNew.of(
      version: '1.1.0',
      title: "What's New in 1.1",
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.speed,
          title: 'Faster',
          subtitle: 'Shown to anyone running 1.1.x who has not seen it.',
        ),
      ],
    ),
    WhatsNew.of(
      version: '2.0.0',
      title: "What's New in 2.0",
      features: <WhatsNewFeature>[
        WhatsNewFeature(
          icon: Icons.rocket_launch_outlined,
          title: 'Rebuilt',
          subtitle: 'A major release with its own sheet.',
        ),
      ],
    ),
  ];
}
