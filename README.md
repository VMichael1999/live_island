# live_island_kit

<p align="center"><img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/banner.png" alt="live_island_kit: iOS Live Activities and Android Live Updates, 100 % in Dart" width="100%"></p>

[Español](README.es.md)

**iOS Live Activities and Android Live Updates with a single Dart API, 100 % editable from Dart.** You define the data and the design of the Dynamic Island, the Lock Screen and the Android notification (texts, colors, icons or images, bars, charts, buttons…) **without writing Swift or Kotlin**: the native code lives inside the plugin.

- **iOS:** Dynamic Island (compact, minimal and expanded), Lock Screen, StandBy, Apple Watch and CarPlay.
- **Android:** ongoing notifications that Android 16+ **promotes to a Live Update** (status-bar chip, top of the shade and lock screen).

| Ride pickup | Match score | Stock quote |
| --- | --- | --- |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/recogida_clara.png" width="300" alt="Ride pickup"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/marcador.png" width="300" alt="Match score"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/bolsa.png" width="300" alt="Stock quote"> |
| **Store pickup** | **Medical waiting room** | **EV charging** |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/tienda.png" width="300" alt="Store pickup"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/sala_medica.png" width="300" alt="Medical waiting room"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/carga.png" width="300" alt="Charging with glowing cable"> |
| **Flight with curved route** | **Trip start with PIN** | **Delivery order** |
| <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/vuelo.png" width="300" alt="Flight"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/pin.png" width="300" alt="Trip start with PIN"> | <img src="https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/galeria/pedido.png" width="300" alt="Delivery order"> |

*Each image shows the compact island, the expanded island and the Lock Screen card. They are the Flutter preview (`LiveIslandPreview`), except charging, which is an iOS Simulator capture (the preview does not draw the glow). All are example designs with made-up names and images; every text, color and image can be changed from Dart. The sample texts are in Spanish.*

## Why live_island_kit

- **One API.** `LiveIsland.start / update / end` does the same on iOS and Android.
- **Design in Dart.** A design is a tree of components (`LiveText`, `LiveRow`, `LiveProgress`, `LiveSparkline`…) bound to your data with `bind('field')`. SwiftUI draws it on iOS and `Notification.ProgressStyle` on Android.
- **Presets and example designs.** 15 ready presets and 10 more elaborate designs (the ones above) as a starting point: use them as they are or change them.
- **Preview without building.** `LiveIslandPreview` draws the same surfaces inside your Flutter app, and `LiveIsland.check()` warns about what does not fit or does not work on each platform.
- **Light data.** The design travels once; each update only carries the state (under 4 KB, the iOS limit).
- **Push.** Update and start activities from your server with APNs and FCM.

> **Status:** 0.1.0, first release. The API may evolve before 1.0. The in-code documentation and the `doc/` folder are in Spanish.

## Requirements

| | Minimum | Notes |
| --- | --- | --- |
| iOS | 16.1 (push-to-start: 17.2; buttons: 17) | Xcode 15+; with Xcode 27 the app's minimum target is iOS 15.0 |
| Android | API 26 (Live Update: API 36) | Below Android 16 an ongoing notification with a standard bar is shown |
| Flutter | 3.29 | iOS with CocoaPods or Swift Package Manager (tested on 3.29, 3.41 and 3.47) |

## Installation

```bash
flutter pub add live_island_kit
dart run live_island_kit:setup
```

`setup` adds the Widget Extension, the App Group and `NSSupportsLiveActivities` to `ios/`, and can be re-run to update the renderer. The only manual step is picking your development team on the *Runner* and *LiveIslandExtension* targets in Xcode. `--push` also adds the push entitlement (see [doc/push.md](doc/push.md)).

On Android the plugin declares `POST_NOTIFICATIONS` and `POST_PROMOTED_NOTIFICATIONS`; ask for the notification permission with `LiveIsland.requestPermission()` before starting.

## Usage

Three levels, from fastest to most flexible. All of them end in the same `LiveLayout`.

### 1. A preset

Fifteen ready-made cases (taxi, delivery, parking, flight…) and ten more elaborate designs (see [Presets](#presets)), each with sample data:

```dart
final activity = await LiveIsland.start(
  layout: const ParkingPreset().build(),
  state: {
    'titulo': 'Parking active',
    'subtitulo': 'Blue zone · Av. Larco 400',
    'nombre': 'Plate ABC-123',
    'llegaA': DateTime.now().add(const Duration(minutes: 45)),
    'progreso': 0.0,
  },
);

await activity.update({'progreso': 0.5}); // only what changes travels
await activity.end(dismiss: const LiveDismiss.after(Duration(minutes: 5)));
```

Every preset takes its most common parameters: `accent`, `icon`, `appLogo`, `androidSmallIcon`, `lockBackground`, `buttons`, `chip` and, depending on the case, `stages`, `tracker`, `endIcon` or `avatarText`. The state keys the presets bind to are `titulo`, `subtitulo`, `nombre`, `progreso` and `destacado` (text) or `llegaA` (countdown date). These key names are just identifiers (they date from the first Spanish version): in your own layouts you choose any names, and each preset documents the keys it reads.

### 2. A preset with `.override`

Replace one region and keep the rest:

```dart
final layout = const TripPreset(
  accent: Color(0xFFD81B60),
  stages: ['Order', 'On the way', 'Arrived'],
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

### Activities with your own id

Give each activity an id from your app and forget the platform's id:

```dart
// Creates the activity; if one with that id is alive, it updates it instead.
final trip = await LiveIsland.start(
  customId: 'trip-42',
  layout: layout,
  state: state,
);

// After reopening the app (even if the process died):
final a = await LiveIsland.activity('trip-42'); // null if it already ended
await a?.update({'progreso': 0.8});

// Sign out, switch account…
await LiveIsland.endAll();
```

The id is yours and may be reused once an activity has ended. `LiveIsland.activeActivities()` lists live ones with their `customId`.

### Several activities at once

iOS shows **one** activity in the island: the one with the highest `relevance` (the oldest on a tie). The rest stay on the Lock Screen. So if you start a new case while another is alive, the island keeps showing the old one. Give the one you want to see more `relevance`, or end the previous one:

```dart
await LiveIsland.start(layout: layout, state: state, relevance: 100);
await LiveIsland.endAll(); // or end only those no longer needed
```

The example app ends the others when you start a case, so each one shows up in the island.

### End at a given time

```dart
// Disappears at 18:30; the card keeps this last state until then.
await activity.scheduleEnd(
  DateTime(2026, 10, 12, 18, 30),
  state: {'estado': 'delivered'},
);

// Or end now and dismiss at a time (instead of after a delay):
await activity.end(dismiss: LiveDismiss.at(DateTime(2026, 10, 12, 18, 30)));
```

It differs per platform, because ActivityKit cannot «end later» a live activity:

| | `scheduleEnd(at)` |
| --- | --- |
| iOS | Ends **now** (leaves the island, no more updates); the Lock Screen card stays until `at` (iOS removes it at most 4 h later) |
| Android | Stays **alive and updatable**; the system removes it at `at` even if the app is closed |

If `at` is in the past it ends immediately.

### Open a screen when the activity is tapped

Start the activity with a `deepLink` and a tap on the card (lock screen, island or notification) opens your app on that link; if the app was closed, it starts there:

```dart
await LiveIsland.start(
  layout: layout,
  state: state,
  deepLink: 'myapp://orders/42',
);

// Later, the courier is on the way: the same card now opens the map.
await activity.update({'progreso': 0.6}, deepLink: 'myapp://map/42');
```

Your app receives the link like any other deep link, so it works with the routing you already have (`go_router`, `app_links`, `onGenerateRoute`…). Register the URL scheme once with `dart run live_island_kit:setup --url-scheme myapp`: it adds `CFBundleURLTypes` on iOS and an intent filter on Android, and can be re-run. With the plain `Navigator` the link arrives as the route name; read it with `Uri.parse(name).path`, because on Android a cold start delivers the whole link and on iOS only its path. A push can change the destination too: send the reserved key `$url` in the state ([doc/push.md](doc/push.md), in Spanish).

### Know what happened to an activity

`LiveIsland.stateChanges` reports every change in the life of your activities, and `activity.states` the ones of a single activity:

```dart
LiveIsland.stateChanges.listen((c) {
  // c.id, c.customId, c.state
  if (c.state == LiveActivityState.dismissed) {
    // The user swiped the card away (or it was removed): stop following the driver.
  }
});
```

| State | Meaning | iOS | Android |
| --- | --- | --- | --- |
| `active` | Showing and accepting updates | Yes | Yes |
| `stale` | `staleAfter` passed without an update | Yes | No |
| `ended` | The app or the server ended it (it may still be on screen with its last state) | Yes | Yes |
| `dismissed` | It left the screen: the user swiped it away, or the system or the dismissal time removed it | Yes | Yes |

Events arrive while you listen, also for activities started by a push or before the app opened (iOS); to know which ones are alive right now use `LiveIsland.activeActivities()`.

### Alerts and stale state

```dart
// Grab attention: the island expands and plays a sound (iOS); on Android it
// sounds and shows as a heads-up notification.
await activity.update(
  {'estado': 'arrived'},
  alert: const LiveAlert(title: 'Your driver arrived', body: 'Toyota Yaris · ABC-123'),
);

// After the date, the system redraws the activity with `stale` true — no push,
// no update — so you can show the final state there.
final activity = await LiveIsland.start(
  layout: layout,                   // with LiveIf(LiveBind.stale.isTrue, ...)
  state: state,
  staleAfter: const Duration(minutes: 15),
);
```

`LiveBind.stale` exists on iOS 16.2+ and in the preview (`LiveIslandPreview(stale: true)`). On Android it is always `false`: update the state with `update` instead.

## Charts and effects

Besides texts, icons and bars, a design supports charts and effects. They all travel in the same JSON contract and render the same on iOS and in the preview. On Android they degrade as the [compatibility](#compatibility) table shows.

```dart
// Line chart: the series travels in the state as text ("212,214.5,213").
LiveSparkline(series: bind('series'), height: 44, color: Color(0xFF30D158));
update({'series': liveSeries([212, 214.5, 213.2, 219.4])});

// Arc gauge with a dot that advances (an orbit, a parking meter…).
LiveGauge(value: bind('progress'), size: 96, sweep: 180);

// Curved route with an icon that advances (a flight, a shipment).
LiveFlightPath(value: bind('progress'), tracker: LiveIcon.symbol('airplane'));

// Bar split into colored parts, proportional to state values.
LiveSplitBar([
  LiveSplitPart(bind('base'), Color(0xFFFFFFFF)),
  LiveSplitPart(bind('tip'), Color(0xFF30D158)),
]);

// Glowing cable, markers and dashed line on a bar.
LiveProgress.bar(
  value: bind('progress'),
  style: LiveProgressStyle(
    glow: 10, dashed: true, markers: [.6, 1], pointShape: LivePointShape.ring,
  ),
);

// Glowing border and italics.
LiveBox(border: Color(0xFF30D158), glow: 10, child: LiveText.literal('Run', italic: true));
```

### Your own images

The example designs use drawings that ship with the package. Use yours (logo, driver photo, car, crests…) with `LiveImage.asset(...)`:

```dart
RidePickupPreset(
  brand: 'My app',
  // A wide image without background (driver + car): fixed height, width from its aspect ratio.
  headerImage: LiveImage.asset('assets/driver_and_car.png', width: 760, height: 308, fixedHeight: 40),
  driverPhoto: LiveImage.asset('assets/photo.png', size: 34, shape: LiveShape.circle),
  trackerImage: LiveImage.asset('assets/top_car.png', width: 88, height: 46),
);
```

Every image is drawn in a square of `size` unless you use `fixedHeight` (or `withHeight(n)`), which fixes the height and leaves the width free. Use PNGs with a transparent background so no box shows.

### Lock Screen card size

iOS limits the Lock Screen card to about **160 pt tall** including the system padding, so your design has roughly 125 pt: anything beyond is clipped. Reduce margins and sizes before adding rows, and check the result on a device or simulator as well as in the preview. In the compact island use one-word texts.

## Icons and images

Wherever an icon goes you can use a system one or your own image (app or client logo, photo, illustration):

```dart
LiveIcon.symbol('car.fill', android: 'assets/live/car.png') // SF Symbol on iOS, PNG on Android
LiveImage.asset('assets/logo.png', fit: LiveFit.cover, shape: LiveShape.rounded)
LiveImage.network(url, shape: LiveShape.circle)
```

Images are downscaled to the size they are shown at before being copied to the device, and are never distorted. Android paints the status-bar small icon as a single-color silhouette: pass `androidSmallIcon` with a silhouette version of your logo.

### Island animation (drop)

`LiveIslandMorph` draws the island dropping a blob that opens into a card holding your layout. Use it in the preview or as an in-app banner; the real island is drawn by the system and cannot be animated this way.

![Drop](https://raw.githubusercontent.com/VMichael1999/live_island_kit/main/doc/assets/gota.gif)

```dart
LiveIslandMorph.preview(
  LivePreviewConfig(layout: layout, state: state),
  visible: show,
  onTap: () => openTrip(),
  onDismissed: () => setState(() => show = false),
);
```

Swiping up dismisses it; `blur`, `gain`, `threshold`, `dropSize` and `timeScale` tune how liquid it looks and its speed.

## Buttons

```dart
LiveIsland.onAction((id) { /* the id of the LiveButton that was tapped */ });
```

Buttons appear on the **lock-screen card** (iOS 17+, without opening the app) and in the **Android notification**. The expanded iOS island does not draw them: tapping the island always opens the app. If the app was closed, the action is delivered when you start listening to `onAction` again; recover live activities with `LiveIsland.activeActivities()`.

## Push

Updating and starting activities from your server, with APNs on iOS and FCM on Android: see [doc/push.md](doc/push.md).

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

### Example designs

More elaborate than the presets, with their own island and Lock Screen card; used the same way (`.build()`, `.sampleState()`, `.override(...)`):

| Design | What it shows | Most customised |
| --- | --- | --- |
| `RidePickupPreset` | Ride pickup, light or dark card | `brand`, `headerImage`, `driverPhoto`, `trackerImage`, `compactIcon`, `bar` (`RideBar.dotted` or `.line`) |
| `RideArrivalPreset` | Arrival time, fare and the car with its plate | `brand`, `carImage`, `accent` |
| `RideTripPreset` | Trip with phase, destination, category, fare and bar | `brand`, `driverPhoto`, `accent` |
| `DeliveryOrderPreset` | Delivery order in four stages with icons | `brand`, `accent` |
| `RidePinPreset` | Trip start with the PIN code, driver photo and bar | `brand`, `driverPhoto`, `accent` |
| `RideStopPreset` | Driver with a numbered stop before pickup, car with plate | `brand`, `stopAt`, `carImage` |
| `RideDestinationPreset` | On the way to the destination: time, address and bar with a square end | `brand`, `accent` |
| `TrainPreset` | Train line with stations and the train on the bar | `stages`, `trainImage`, `accent` |
| `StorePickupPreset` | Order pickup, with three steps | `store`, `brandLogo`, `stepColor` |
| `RunPreset` | Run: distance, time and goal | `brand`, `unit`, `timeLabel` |
| `MatchPreset` | A match score | `homeCrest`, `awayCrest`, `homeLabel`, `link` |
| `StockPreset` | Quote with a line chart | `brandLogo`, `accent` |
| `FlightPathPreset` | Flight with the curved route | `carrier`, `accent` |
| `OrbitPreset` | Arc with a dot that advances | `sweep`, `accent` |
| `ChargePreset` | Charging with a glowing cable | `glow`, `accent` |
| `FareSplitPreset` | Fare split into base, service and tip | `brand`, `accent` |

The [`example/`](example) app has one screen per preset and design, and an editor that starts from one of them.

### Android: Live Update or card

The example designs use the **card** by default so Android draws the same thing as iOS; pass `androidStyle: LiveAndroidStyle.liveUpdate` to go back to the native style. That style (`LiveAndroidStyle.liveUpdate`, the default of `LiveAndroid`): title, text, bar, one large image and the status-bar chip, and Android 16 **promotes it to a Live Update**. If you need more freedom (two crests face to face, a big score, a chart), ask for the **card**: it is drawn with your design, but Android **does not promote it or show a chip**.

```dart
LiveAndroid(
  style: LiveAndroidStyle.card,   // default: LiveAndroidStyle.liveUpdate
  card: myCard,                   // optional: falls back to the custom Lock Screen card
  title: const LiveText.literal('Score'),
)
// or with a preset:
MatchPreset(androidStyle: LiveAndroidStyle.liveUpdate)
```

The card needs Android 12 or later (the native style is used before that). Details in [`doc/design/DESVIACIONES.md`](doc/design/DESVIACIONES.md) (in Spanish).

## Troubleshooting

**Nothing shows on iPhone.** Check, in order: `await LiveIsland.areEnabled()` is `true` (the user can turn Live Activities off per app in Settings); both the *Runner* and *LiveIslandExtension* targets have the **same** App Group; `NSSupportsLiveActivities` is `YES` in `ios/Runner/Info.plist`; the extension is embedded in the app and has a development team; and `LiveIsland.check(layout, state)` reports no errors. Re-running `dart run live_island_kit:setup` repairs the first three.

**`pod install` says "requires a higher minimum iOS deployment version".** The plugin needs iOS 15. `setup` raises `platform :ios` in the `Podfile` and the Xcode project to 15.0; if you edit the `Podfile` yourself, set `platform :ios, '15.0'` and run `pod install` again.

**Android build fails with "minSdkVersion 24 cannot be smaller than version 26".** The plugin needs API 26. `setup` raises `minSdk` in `android/app/build.gradle(.kts)` to 26 (and never lowers a bigger value); you can also set it yourself.

**Flutter warns that `live_island_kit` "applies Kotlin Gradle Plugin".** It is only a warning for now: the build works.

**`LiveIslandException` codes.** `disabled`: the user turned Live Activities (iOS) or notifications (Android) off; on Android call `LiveIsland.requestPermission()` first. `unsupported`: the device has no Live Activities (iOS earlier than 16.1, iPad, Mac). `not_found`: the activity already ended or the id is unknown. `not_configured`: the App Group is missing; run `dart run live_island_kit:setup` and build again. `start_failed`: the system refused to start it; the exception message has the reason. `LiveIsland.check()` warns beforehand about a state over 4,096 bytes.

**The activity freezes at an old value.** iOS limits how often an activity can update and ends it after eight hours. Set `staleAfter` so the card shows it is old, and update through push ([doc/push.md](doc/push.md)).

**The Live Update chip does not appear on Android.** It needs Android 16 and the user must allow promoted notifications for the app: `LiveIsland.openPromotionSettings()` opens that screen. Below Android 16 a standard notification with a bar is shown.

## Compatibility

| | iOS | Android 16+ |
| --- | --- | --- |
| Dynamic Island (compact, minimal, expanded) | Yes | Does not exist |
| Custom Lock Screen design | Yes (`LiveLockScreen.custom`) | Standard notification |
| Text, icons and images | Yes | Title, text, chip and icons |
| Bar, stages and points | Yes, fully styled | Color and markers; the system decides thickness |
| Dashed line, glowing cable, glowing border | Yes | Ignored |
| Ring and arc gauge | Yes | Shown as a bar |
| Curved route | Yes | Bar with the same icon |
| Line chart and split bar | Yes | Omitted |
| Full custom design | Yes | With `style: card` (no chip or Live Update) |
| Buttons | Lock Screen (iOS 17+); the island opens the app | In the notification |
| Stale state | iOS 16.2+ | Always `false` |

If something cannot be shown on Android, `LiveIsland.check()` tells you before you ship.

## Out of scope

- Music (the system already uses *Now Playing* and `MediaSession`) and calls (CallKit and `CallStyle`).
- Drawing arbitrary Flutter widgets in the island: it is not possible; only the package's components.

## More documentation

- [Roadmap](doc/ROADMAP.md): known limits and what is not verified yet.
- [`doc/contract/`](doc/contract): the JSON contract between Dart, Swift and Kotlin and its render rules.
- [`doc/design/DESVIACIONES.md`](doc/design/DESVIACIONES.md): how iOS and Android differ from the prototype.
- [`doc/push.md`](doc/push.md): APNs and FCM push formats.

### Live bar: follow the driver's signal

The bar reads `progreso` from the state, so updating it is enough. `LiveRoute` turns a position into progress and `follow` keeps the activity current without flooding the system:

```dart
final route = LiveRoute.straight(origin, destination); // or LiveRoute([a, b, c, ...])

activity.follow(
  driverPositions, // Stream<LiveLatLng> from your map, socket or server
  (p) => {'progreso': route.progressAt(p), 'etapa': route.stageAt(p, 4)},
  minInterval: const Duration(seconds: 5), // at most one update every 5 s
);
```

Stage points are yours too: how many (`stages`, with or without text: `''`), their shape (`LiveProgressStyle(pointShape: LivePointShape.square)`) and size. For events (order confirmed, arrived) use the same `follow` or `activity.update({...})`.
