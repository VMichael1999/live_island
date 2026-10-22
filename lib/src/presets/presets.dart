// Los 15 presets de la galería del HTML de prototipos
// (doc/design/live_island_prototipos.html), con sus datos de ejemplo.
//
// Cada uno es un `LivePreset`: `.build()` devuelve el `LiveLayout`,
// `.override(...)` reemplaza regiones y `.sampleState()` trae datos de prueba.
import 'dart:ui' show Color;

import '../components/actions.dart';
import '../components/progress.dart';
import '../components/visuals.dart';
import '../core/bind.dart';
import '../core/enums.dart';
import '../core/layout.dart';
import 'preset.dart';

/// The car seen from above that the package ships: it is the same one used by all
/// designs with a bar (`liveDesignCarTopAsset`), and [TripPreset] uses it as the moving icon.
const livePresetCarAsset =
    'packages/live_island_kit/assets/presets/car_top.png';

/// Taxi or similar ride: driver, arrival countdown and progress by stages with the image of a car.
///
/// Sample data: "Your driver is on the way".
final class TripPreset extends LivePreset {
  const TripPreset({
    this.accent = const Color(0xFF1F6FEB),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Assigned', 'On the way', 'Arrived'],
    this.showPoints = true,
    this.tracker,
    this.endIcon,
    this.avatarText = 'CM',
    this.avatarPhoto,
    this.showLabels = true,
    this.showTracker = true,
    this.showEndIcon = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Icon at the end of the bar.
  final LiveVisual? endIcon;

  /// Avatar initials.
  final String avatarText;

  /// Avatar photo (replaces the initials).
  final LiveImage? avatarPhoto;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Shows the marker at the end of the bar.
  final bool showEndIcon;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'taxi',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Ride Now',
    accent: accent,
    icon: icon ?? presetIcon('car.fill', 'car'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    avatarText: avatarPhoto == null ? avatarText : null,
    avatarPhoto: avatarPhoto,
    countdown: true,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker:
        !showTracker
            ? null
            : tracker ??
                LiveTracker(
                  LiveImage.asset(livePresetCarAsset, width: 212, height: 113),
                  background: LiveTrackerBackground.none,
                ),
    endIcon: !showEndIcon ? null : endIcon ?? presetIcon('mappin', 'mappin'),
    buttons:
        buttons ??
        [
          presetButton('Call', presetIcon('phone.fill', 'phone')),
          presetButton(
            'Share',
            presetIcon('square.and.arrow.up', 'share2'),
          ),
        ],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Your driver is on the way',
      subtitle: 'Gray sedan · ABC-123',
      name: 'Carlos M.',
      minutes: 6.0,
      progress: 0.45,
    ),
  );
}

/// Food delivery order: stages, countdown and courier.
///
/// Sample data: "Your order is on the way".
final class DeliveryPreset extends LivePreset {
  const DeliveryPreset({
    this.accent = const Color(0xFFE4572E),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Confirmed', 'Preparing', 'On the way', 'Delivered'],
    this.showPoints = true,
    this.tracker,
    this.endIcon,
    this.showLabels = true,
    this.showTracker = true,
    this.showEndIcon = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Icon at the end of the bar.
  final LiveVisual? endIcon;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Shows the marker at the end of the bar.
  final bool showEndIcon;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'delivery',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Eat Now',
    accent: accent,
    icon: icon ?? presetIcon('fork.knife', 'utensils'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: true,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker: !showTracker ? null : tracker ?? presetIcon('bicycle', 'bike'),
    endIcon: !showEndIcon ? null : endIcon ?? presetIcon('house.fill', 'house'),
    buttons:
        buttons ??
        [
          presetButton('Call', presetIcon('phone.fill', 'phone')),
          presetButton('View map', presetIcon('mappin', 'mappin')),
        ],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Your order is on the way',
      subtitle: 'La Brasa Chicken · 2 items',
      name: 'Luis, courier',
      minutes: 12.0,
      progress: 0.62,
    ),
  );
}

/// Package on its way: remaining stops and shipping stages.
///
/// Sample data: "Your package arrives today".
final class CourierPreset extends LivePreset {
  const CourierPreset({
    this.accent = const Color(0xFF6D4C41),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Warehouse', 'In transit', 'Nearby', 'Delivered'],
    this.showPoints = true,
    this.tracker,
    this.endIcon,
    this.showLabels = true,
    this.showTracker = true,
    this.showEndIcon = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Icon at the end of the bar.
  final LiveVisual? endIcon;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Shows the marker at the end of the bar.
  final bool showEndIcon;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'courier',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Fast Parcel',
    accent: accent,
    icon: icon ?? presetIcon('shippingbox.fill', 'package'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker:
        !showTracker ? null : tracker ?? presetIcon('truck.box.fill', 'truck'),
    endIcon: !showEndIcon ? null : endIcon ?? presetIcon('house.fill', 'house'),
    buttons:
        buttons ?? [presetButton('View route', presetIcon('mappin', 'mappin'))],
    chip: chip ?? const LiveChip.text('3 more'),
    sample: const PresetSample(
      title: 'Your package arrives today',
      subtitle: '3 stops before yours',
      name: 'Route 14',
      highlight: '3 stops',
      minutes: 5.0,
      progress: 0.4,
    ),
  );
}

/// Pickup order: stages and pickup code.
///
/// Sample data: "Your order is almost ready".
final class PickupPreset extends LivePreset {
  const PickupPreset({
    this.accent = const Color(0xFF8D5B3A),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Received', 'Preparing', 'Ready'],
    this.showPoints = true,
    this.showLabels = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Shows the stage labels.
  final bool showLabels;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'pickup',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Central Café',
    accent: accent,
    icon: icon ?? presetIcon('cup.and.saucer.fill', 'coffee'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    buttons:
        buttons ?? [presetButton('Show code', presetIcon('qrcode', 'qrcode'))],
    chip: chip ?? const LiveChip.text('#47'),
    sample: const PresetSample(
      title: 'Your order is almost ready',
      subtitle: 'Large latte · Pickup counter',
      name: 'Code 47',
      highlight: '#47',
      minutes: 5.0,
      progress: 0.5,
    ),
  );
}

/// Turn in a queue (bank, paperwork): position and ticket code.
///
/// Sample data: "Your turn is coming".
final class QueuePreset extends LivePreset {
  const QueuePreset({
    this.accent = const Color(0xFF00897B),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.tracker,
    this.showTracker = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'queue',
    progressStyle: progressStyle,
    appName: 'My Bank',
    accent: accent,
    icon: icon ?? presetIcon('building.columns.fill', 'landmark'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.bar,
    tracker: !showTracker ? null : tracker ?? presetIcon('person.fill', 'user'),
    buttons:
        buttons ?? [presetButton('Cancel ticket', presetIcon('xmark', 'x'))],
    chip: chip ?? const LiveChip.text('B-027'),
    sample: const PresetSample(
      title: 'Your turn is coming',
      subtitle: 'Miraflores branch · Platform',
      name: 'Ticket B-027',
      highlight: '4 ahead',
      minutes: 5.0,
      progress: 0.7,
    ),
  );
}

/// Flight: check-in, boarding and takeoff with a countdown.
///
/// Sample data: "Now boarding".
final class FlightPreset extends LivePreset {
  const FlightPreset({
    this.accent = const Color(0xFF2D5BD7),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Check-in', 'Boarding', 'Takeoff'],
    this.showPoints = true,
    this.tracker,
    this.showLabels = true,
    this.showTracker = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'flight',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Fly',
    accent: accent,
    icon: icon ?? presetIcon('airplane', 'plane'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: true,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker: !showTracker ? null : tracker ?? presetIcon('airplane', 'plane'),
    buttons:
        buttons ??
        [presetButton('Boarding pass', presetIcon('qrcode', 'qrcode'))],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Now boarding',
      subtitle: 'LIM → CUZ · Flight 2041',
      name: 'Gate 18',
      minutes: 25.0,
      progress: 0.35,
    ),
  );
}

/// Time-limited parking: ring and countdown, with buttons to extend or end.
///
/// Sample data: "Parking active".
final class ParkingPreset extends LivePreset {
  const ParkingPreset({
    this.accent = const Color(0xFF0277BD),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'parking',
    progressStyle: progressStyle,
    appName: 'Park',
    accent: accent,
    icon: icon ?? presetIcon('parkingsign.circle.fill', 'squareparking'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: true,
    progress: PresetProgress.ring,
    buttons:
        buttons ??
        [
          presetButton('+15 min', presetIcon('plus', 'plus')),
          presetButton('End', presetIcon('xmark', 'x')),
        ],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Parking active',
      subtitle: 'Blue zone · Av. Larco 400',
      name: 'Plate ABC-123',
      minutes: 45.0,
      progress: 0.35,
    ),
  );
}

/// Electric car charging: battery percentage and finish time.
///
/// Sample data: "Charging your car".
final class EvChargingPreset extends LivePreset {
  const EvChargingPreset({
    this.accent = const Color(0xFF2E7D32),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.tracker,
    this.showTracker = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'ev',
    progressStyle: progressStyle,
    appName: 'Easy Charge',
    accent: accent,
    icon: icon ?? presetIcon('bolt.car.fill', 'batterycharging'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.bar,
    tracker: !showTracker ? null : tracker ?? presetIcon('bolt.fill', 'zap'),
    buttons:
        buttons ?? [presetButton('Stop', presetIcon('pause.fill', 'pause'))],
    chip: chip ?? const LiveChip.text('68 %'),
    sample: const PresetSample(
      title: 'Charging your car',
      subtitle: 'Station 3 · 50 kW',
      name: 'Done 10:35',
      highlight: '68 %',
      minutes: 5.0,
      progress: 0.68,
    ),
  );
}

/// Rest between sets of a workout: countdown and set number.
///
/// Sample data: "Rest".
final class WorkoutPreset extends LivePreset {
  const WorkoutPreset({
    this.accent = const Color(0xFFD81B60),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['1', '2', '3', '4'],
    this.showPoints = false,
    this.showLabels = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Shows the stage labels.
  final bool showLabels;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'workout',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Gym Pro',
    accent: accent,
    icon: icon ?? presetIcon('dumbbell.fill', 'dumbbell'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: true,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    buttons:
        buttons ??
        [
          presetButton('+30 s', presetIcon('plus', 'plus')),
          presetButton('Skip', presetIcon('play.fill', 'play')),
        ],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Rest',
      subtitle: 'Bench press · Set 3 of 4',
      name: '60 kg × 10',
      minutes: 1.5,
      progress: 0.5,
    ),
  );
}

/// Kitchen timer: ring and countdown.
///
/// Sample data: "Rice cooking".
final class CookingTimerPreset extends LivePreset {
  const CookingTimerPreset({
    this.accent = const Color(0xFFF57C00),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'cooking',
    progressStyle: progressStyle,
    appName: 'Recipes',
    accent: accent,
    icon: icon ?? presetIcon('frying.pan.fill', 'cookingpot'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: true,
    progress: PresetProgress.ring,
    buttons:
        buttons ?? [presetButton('Pause', presetIcon('pause.fill', 'pause'))],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Rice cooking',
      subtitle: 'Step 3 of 5 · Lower the heat',
      name: 'Chicken rice',
      minutes: 15.0,
      progress: 0.4,
    ),
  );
}

/// File upload: percentage and time remaining.
///
/// Sample data: "Uploading video".
final class UploadPreset extends LivePreset {
  const UploadPreset({
    this.accent = const Color(0xFF5E35B1),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'upload',
    progressStyle: progressStyle,
    appName: 'Cloud',
    accent: accent,
    icon: icon ?? presetIcon('arrow.up.circle.fill', 'upload'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.bar,
    buttons: buttons ?? [presetButton('Cancel', presetIcon('xmark', 'x'))],
    chip: chip ?? const LiveChip.text('42 %'),
    sample: const PresetSample(
      title: 'Uploading video',
      subtitle: 'holiday.mp4 · 420 MB',
      name: '3 min left',
      highlight: '42 %',
      minutes: 5.0,
      progress: 0.42,
    ),
  );
}

/// Technician at home: avatar, countdown and service stages.
///
/// Sample data: "Your technician is on the way".
final class TechnicianPreset extends LivePreset {
  const TechnicianPreset({
    this.accent = const Color(0xFF00838F),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Assigned', 'On the way', 'Working', 'Ready'],
    this.showPoints = true,
    this.tracker,
    this.avatarText = 'JR',
    this.avatarPhoto,
    this.showLabels = true,
    this.showTracker = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Avatar initials.
  final String avatarText;

  /// Avatar photo (replaces the initials).
  final LiveImage? avatarPhoto;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'tech',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Home Easy',
    accent: accent,
    icon: icon ?? presetIcon('wrench.and.screwdriver.fill', 'wrench'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    avatarText: avatarPhoto == null ? avatarText : null,
    avatarPhoto: avatarPhoto,
    countdown: true,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker: !showTracker ? null : tracker ?? presetIcon('car.fill', 'car'),
    buttons:
        buttons ?? [presetButton('Call', presetIcon('phone.fill', 'phone'))],
    chip: chip ?? const LiveChip.countdown(LiveBind('llegaA')),
    sample: const PresetSample(
      title: 'Your technician is on the way',
      subtitle: 'Internet installation',
      name: 'Jorge R.',
      minutes: 20.0,
      progress: 0.3,
    ),
  );
}

/// Public transport: stops left and stages of the route.
///
/// Sample data: "Get off in 3 stops".
final class TransitPreset extends LivePreset {
  const TransitPreset({
    this.accent = const Color(0xFFC62828),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.stages = const ['Boarded', '2', '3', '4', 'Exit'],
    this.showPoints = true,
    this.tracker,
    this.endIcon,
    this.showLabels = true,
    this.showTracker = true,
    this.showEndIcon = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Stage labels.
  final List<String> stages;

  /// Marks each stage with a dot.
  final bool showPoints;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Icon at the end of the bar.
  final LiveVisual? endIcon;

  /// Shows the stage labels.
  final bool showLabels;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Shows the marker at the end of the bar.
  final bool showEndIcon;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'transit',
    showLabels: showLabels,
    progressStyle: progressStyle,
    appName: 'Lima Transit',
    accent: accent,
    icon: icon ?? presetIcon('bus.fill', 'bus'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.segments,
    stages: stages,
    showPoints: showPoints,
    tracker: !showTracker ? null : tracker ?? presetIcon('bus.fill', 'bus'),
    endIcon:
        !showEndIcon ? null : endIcon ?? presetIcon('flag.checkered', 'flag'),
    buttons: buttons ?? [],
    chip: chip ?? const LiveChip.text('3 stops'),
    sample: const PresetSample(
      title: 'Get off in 3 stops',
      subtitle: 'Line 201 · Javier Prado',
      name: 'Las Begonias stop',
      highlight: '3 stops',
      minutes: 5.0,
      progress: 0.55,
    ),
  );
}

/// Virtual waiting room: people before your turn.
///
/// Sample data: "Virtual waiting room".
final class WaitingRoomPreset extends LivePreset {
  const WaitingRoomPreset({
    this.accent = const Color(0xFF00796B),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
    this.tracker,
    this.showTracker = true,
    this.progressStyle,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  /// Icon or image that moves along the bar.
  final LiveTrackerSource? tracker;

  /// Shows the icon or image that moves along the bar.
  final bool showTracker;

  /// Thickness, colors, corners and sizes of the bar (or the ring).
  final LiveProgressStyle? progressStyle;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'clinic',
    progressStyle: progressStyle,
    appName: 'Online Health',
    accent: accent,
    icon: icon ?? presetIcon('stethoscope', 'stethoscope'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.bar,
    tracker: !showTracker ? null : tracker ?? presetIcon('person.fill', 'user'),
    buttons:
        buttons ?? [presetButton('Leave queue', presetIcon('xmark', 'x'))],
    chip: chip ?? const LiveChip.text('2 ahead'),
    sample: const PresetSample(
      title: 'Virtual waiting room',
      subtitle: 'Dr. Ríos · General medicine',
      name: 'Calling you soon',
      highlight: '2 ahead',
      minutes: 5.0,
      progress: 0.8,
    ),
  );
}

/// Sports score. Android does not promote it to a Live Update: the user did not start it as an activity with a start and an end.
///
/// Sample data: "Lima FC 2 – 1 Callao SC".
final class ScorePreset extends LivePreset {
  const ScorePreset({
    this.accent = const Color(0xFF1B5E20),
    this.icon,
    this.appLogo,
    this.androidSmallIcon,
    this.lockBackground = LiveBackground.system,
    this.buttons,
    this.chip,
  });

  /// Accent color.
  final Color accent;

  /// Main icon.
  final LiveIcon? icon;

  /// App logo (lock screen card and Android's large icon). Without it the main icon is used.
  final LiveVisual? appLogo;

  /// One-color silhouette for Android's status bar.
  final LiveVisual? androidSmallIcon;

  /// Background of the lock screen card.
  final LiveBackground lockBackground;

  /// Buttons (up to 2). They are shown on the lock screen card and on Android.
  final List<LiveButton>? buttons;

  /// Chip in Android's status bar.
  final LiveChip? chip;

  @override
  LivePresetSpec get spec => LivePresetSpec(
    id: 'score',
    appName: 'Live Football',
    accent: accent,
    icon: icon ?? presetIcon('trophy.fill', 'trophy'),
    appLogo: appLogo,
    androidSmallIcon: androidSmallIcon,
    lockBackground: lockBackground,
    countdown: false,
    progress: PresetProgress.none,
    buttons: buttons ?? [],
    chip: chip ?? const LiveChip.text('2–1'),
    androidPromotable: false,
    sample: const PresetSample(
      title: 'Lima FC 2 – 1 Callao SC',
      subtitle: 'Second half · Lima FC goal',
      name: 'Liga 1',
      highlight: '78\'',
      minutes: 5.0,
      progress: 0.4,
    ),
  );
}
