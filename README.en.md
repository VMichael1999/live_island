# live_island

[Español](README.md)

Live activities with **a single Dart API**:

- **iOS:** Live Activities in the Dynamic Island (compact, minimal and expanded), on the Lock Screen, StandBy, Apple Watch and CarPlay.
- **Android:** ongoing notifications that Android 16+ **promotes to a Live Update** (status-bar chip, top of the shade and lock screen).

You define your data and your design (texts, colors, icons or images, progress bar, the icon that travels along the bar, stages, buttons, the Android chip) **without writing Swift or Kotlin**. The native code lives inside the plugin; `dart run live_island:setup` adds what the Xcode project needs.

| Taxi | Parking | Delivery |
| --- | --- | --- |
| ![Taxi](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/taxi.gif) | ![Parking](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/estacionamiento.gif) | ![Delivery](https://raw.githubusercontent.com/VMichael1999/live_island/main/docs/assets/delivery.gif) |

*Flutter preview (`LiveIslandPreview`) of each preset: the compact island and the lock-screen card, with progress and countdown.*

> **Status:** pre-release (0.1.0, unpublished). The API may change until it is published. The in-code documentation and the `docs/` folder are in Spanish.

## Requirements

| | Minimum | Notes |
| --- | --- | --- |
| iOS | 16.1 (push-to-start: 17.2; buttons: 17) | Xcode 15+; with Xcode 27 the app's minimum target is iOS 15.0 |
| Android | API 26 (Live Update: API 36) | Below Android 16 an ongoing notification with a standard bar is shown |
| Flutter | 3.29 | |

## Installation

```bash
flutter pub add live_island
dart run live_island:setup
```

`setup` adds the Widget Extension, the App Group and `NSSupportsLiveActivities` to `ios/`, and can be re-run to update the renderer. The only manual step is picking your development team on the *Runner* and *LiveIslandExtension* targets in Xcode. `--push` also adds the push entitlement (see [docs/push.md](docs/push.md)).

On Android the plugin declares `POST_NOTIFICATIONS` and `POST_PROMOTED_NOTIFICATIONS`; ask for the notification permission with `LiveIsland.requestPermission()` before starting.

## Usage

Three levels, from fastest to most flexible. All of them end in the same `LiveLayout`.

### 1. A preset

Fifteen ready-made cases (taxi, delivery, parking, flight…), each with sample data:

```dart
final activity = await LiveIsland.start(
  layout: const ParkingPreset().build(),
  state: {
    'titulo': 'Estacionamiento activo',
    'subtitulo': 'Zona azul · Av. Larco 400',
    'nombre': 'Placa ABC-123',
    'llegaA': DateTime.now().add(const Duration(minutes: 45)),
    'progreso': 0.0,
  },
);

await activity.update({'progreso': 0.5}); // only what changes travels
await activity.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
```

Every preset takes its most common parameters: `accent`, `icon`, `appLogo`, `androidSmallIcon`, `lockBackground`, `buttons`, `chip` and, depending on the case, `stages`, `tracker`, `endIcon` or `avatarText`. The state keys the presets bind to are `titulo`, `subtitulo`, `nombre`, `progreso` and `destacado` (text) or `llegaA` (countdown date).

### 2. A preset with `.override`

Replace one region and keep the rest:

```dart
final layout = const TripPreset(
  accent: Color(0xFFD81B60),
  stages: ['Pedido', 'En camino', 'Llegó'],
).override(
  // The compact island shows the plate instead of the countdown.
  compactTrailing: LiveText.from(
    const LiveText(LiveBind('placa')),
    size: 15,
    weight: 600,
    accent: true,
  ),
);
```

`override` can also replace a single zone of the expanded island (`expandedLeading`, `expandedCenter`, `expandedTrailing`, `expandedBottom`) or the Android block (`android:`).

### 3. A layout from scratch

```dart
final layout = LiveLayout(
  theme: const LiveTheme(accent: Color(0xFF00897B)),
  compactLeading: const LiveIcon.symbol('timer', accent: true),
  compactTrailing: LiveText.from(
    LiveText.countdown(bind('termina')),
    size: 15, weight: 600, accent: true,
  ),
  minimal: const LiveIcon.symbol('timer', accent: true),
  expanded: LiveExpanded(
    leading: const LiveBox(
      child: LiveIcon.symbol('timer', accent: true),
      size: 46, radius: 14, tint: 0.22,
    ),
    center: const LiveColumn([
      LiveText(LiveBind('titulo'), size: 15, weight: 600),
      LiveText(LiveBind('detalle'), size: 13, muted: true),
    ]),
    trailing: LiveText.from(
      LiveText.countdown(bind('termina')),
      size: 22, weight: 700, accent: true,
    ),
    bottom: LiveProgress.bar(value: bind('progreso')),
  ),
  lockScreen: const LiveLockScreen.sameAsExpanded(),
  android: LiveAndroid(
    title: bind('titulo'),
    text: const LiveText.format('{detalle}'),
    chip: LiveChip.countdown(bind('termina')),
  ),
);
```

The **layout** travels once, when the activity starts; each update carries only the **state** (the data), which keeps it under iOS's 4 KB limit. Texts, counters and bars are tied to the state with `bind('field')`.

### Editable progress bar

Every part of the bar is optional and adjustable:

```dart
DeliveryPreset(
  showLabels: false,   // no stage labels
  showPoints: true,    // stage dots
  showTracker: true,   // moving icon
  showEndIcon: false,  // no end marker
  progressStyle: LiveProgressStyle(
    height: 12, color: Color(0xFFC62828), trackColor: Color(0xFF3A2A2A),
    gap: 2, pointSize: 16, trackerSize: 32,
  ),
);
```

Also available on `LiveProgress.bar(style: ...)` and `LiveSegments(style: ..., showLabels: ...)`. On Android only the bar and dot colors apply; the system decides the rest.

## Icons and images

Wherever an icon goes you can use a system one or your own image (app or client logo, photo, illustration):

```dart
LiveIcon.symbol('car.fill', android: 'assets/live/car.png') // SF Symbol on iOS, PNG on Android
LiveImage.asset('assets/logo.png', fit: LiveFit.cover, shape: LiveShape.rounded)
LiveImage.network(url, shape: LiveShape.circle)
```

Images are downscaled to the size they are shown at before being copied to the device, and are never distorted. Android paints the status-bar small icon as a single-color silhouette: pass `androidSmallIcon` with a silhouette version of your logo.

## Buttons

```dart
LiveIsland.onAction((id) { /* the id of the LiveButton that was tapped */ });
```

Buttons appear on the **lock-screen card** (iOS 17+, without opening the app) and in the **Android notification**. The expanded iOS island does not draw them: tapping the island always opens the app. If the app was closed, the action is delivered when you start listening to `onAction` again; recover live activities with `LiveIsland.activeActivities()`.

## Push

Updating and starting activities from your server, with APNs on iOS and FCM on Android: see [docs/push.md](docs/push.md).

## Try it without building the extension

`LiveIslandPreview` draws the same surfaces in Flutter (compact, minimal and expanded island, lock-screen card and Android notification):

```dart
LiveIslandPreview(layout: layout, state: state, appName: 'My app')
```

`LiveIsland.check(layout, state)` validates the layout with the same warnings as the prototype's validation panel (state size, long text in the compact island, Android chip, whether Android promotes it…).

## Presets

| Preset | Case |
| --- | --- |
| `TripPreset` | Taxi |
| `DeliveryPreset` | Food delivery |
| `CourierPreset` | Package on its way |
| `PickupPreset` | Order for pickup |
| `QueuePreset` | Bank queue ticket |
| `FlightPreset` | Flight |
| `ParkingPreset` | Parking |
| `EvChargingPreset` | EV charging |
| `WorkoutPreset` | Workout |
| `CookingTimerPreset` | Cooking timer |
| `UploadPreset` | File upload |
| `TechnicianPreset` | Home technician |
| `TransitPreset` | Public transit |
| `WaitingRoomPreset` | Medical waiting room |
| `ScorePreset` | Sports score |

The [`example/`](example) app has one screen per preset and an editor that starts from one of them.

## Out of scope

- Music (the system already uses *Now Playing* and `MediaSession`) and calls (CallKit and `CallStyle`).
- Drawing arbitrary Flutter widgets in the island: it is not possible; only the package's components.

## More documentation

- [`docs/contract/`](docs/contract): the JSON contract between Dart, Swift and Kotlin and its render rules.
- [`docs/design/DESVIACIONES.md`](docs/design/DESVIACIONES.md): how iOS and Android differ from the prototype.
- [`docs/push.md`](docs/push.md): APNs and FCM push formats.
