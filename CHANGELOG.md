## Unreleased

* iOS: the privacy manifest (App Group `UserDefaults`, reason `1C8F.1`) was checked against the compiled binaries of the plugin and the extension: they use no other required-reason API. A new test fails if one is added without declaring it.
* Cross-platform conformance: `doc/contract/conformance.json` holds 52 cases (`{field}` templates, conditions and the countdown) that Dart, Swift and Kotlin run with their real logic (`tool/conformidad.sh`). The rules are now written in the contract.
* Differences the suite found are fixed: the preview wrote `5.0` where the device writes `5`; `eq` and the numeric operators treat a number and a numeric string the same on all three platforms; `truthy: false` inverts the condition; the text `"false"` is truthy; a boolean is not a number; and on iOS `{ x }` or `{}` no longer disappear from a template.
* The README is now in English (Spanish version: `README.es.md`), and so are the pub.dev description and screenshot captions.

## 0.2.0

* iOS: the right zone of the expanded island has a 4 pt margin, so the island's curve does not clip the "78'" of the sports score.
* iOS: in the expanded island, a one-line text shrinks down to 65 % before being cut with "…" (Public transport, Waiting room and File upload no longer lose "3 stops", "We'll call you soon" or "3 min left").
* iOS: fixes an app crash when starting an activity (a data race while watching ActivityKit push tokens).
* New "Run" designs: `RideArrivalPreset` (arrival, with a sedan and its plate), `RideTripPreset` (trip with phase, destination and fare), `RidePinPreset` (trip start with the PIN code), `RideStopPreset` (driver with a stop before pickup), `RideDestinationPreset` (on the way to the destination), `TrainPreset` (train line with stations in Lima) and `DeliveryOrderPreset` (delivery order in four stages with icons). They ship their own images: a car with a plate, a car and a train seen from above, and the order icons.
* Bar: `LiveProgressStyle.endMarker` attaches a ring or a square to the end of the bar, with the car on top; `LiveSegments.stageIcons` puts an icon on each stage (gray until reached, colored after); and `LiveProgressStyle.markerLabels` writes text inside a marker (a numbered stop).
* Lock screen: if the root is a box with an opaque color, that color is the background of the whole card (a single container) on iOS and in the preview.
* `tool/sincronizar_swift.sh` and `swift_sincronizado_test` keep the example's copy of the iOS renderer identical to the source.
* The preview cuts long text next to a spacer with "…", like SwiftUI.
* Android: the card paints the theme background (`accent` and `light`), like the iOS one.
* Android: every example design uses the card (`LiveAndroidStyle.card`) by default, so Android draws the same design as iOS from the same JSON. With `androidStyle: LiveAndroidStyle.liveUpdate` you go back to the native template (and to the Live Update promotion).
* The README gallery changes: "Trip start with PIN" and "Delivery order" replace "Trip with details" and "Fare and tip".
* `RideDriverPreset` (trip as the driver sees it) is removed: the new designs replace it.

## 0.1.1

* No analyzer warnings on Flutter 3.47 (`dart:ui` imports flagged as unnecessary).
* The repository is renamed `live_island_kit`: `repository`, `issue_tracker` and the README image links are updated.

## 0.1.0

First published version.

* A single Dart API (`LiveIsland.start/update/end`) for iOS Live Activities and Android 16+ Live Updates.
* JSON contract v1 (design once, state ≤ 4,096 bytes) shared by Dart, Swift and Kotlin.
* iOS: a generic SwiftUI Widget Extension (compact, expanded and minimal island, lock screen, StandBy), buttons with `LiveActivityIntent` (iOS 17+), push tokens and push-to-start (iOS 17.2).
* Android: `Notification.ProgressStyle`, chip, Live Update promotion, buttons, action queue and FCM push entry point.
* `dart run live_island_kit:setup` configures the Xcode project (`--push` for APNs).
* Components: text, countdowns, icons and images, avatar, bar, ring, stages, tracker, buttons.
* Editable progress bar: color, thickness, dots, labels, moving icon and end marker (`LiveProgressStyle`).
* Stage dots to taste: count, with or without text, and shape (`LivePointShape`: circle, square, rounded).
* Live bar: `LiveRoute` turns a position into progress and `LiveActivity.follow` keeps the activity up to date from a `Stream`, spacing out the updates.
* `LiveIslandMorph`: the island drops a blob that opens into a card (preview and in-app notice), dismissible by gesture.
* iOS: a privacy manifest that declares the App Group `UserDefaults` use (reason `1C8F.1`), packaged with the plugin and copied into the extension by `dart run live_island_kit:setup`; the podspec takes the package version.
* Activities with your own id: `start(customId:)` creates or updates, `LiveIsland.activity(customId)` finds them after reopening the app, `LiveIsland.endAll()` ends them and `activeActivities()` returns their `customId`. Android pushes accept `customId` in `start` and as `id` in `update`/`end`.
* Alerts: `update(alert: LiveAlert(...))` expands the island and plays a sound on iOS; on Android it uses a channel with sound and shows as a heads-up. The Android push accepts `"alert": true`.
* Stale state: `LiveBind.stale` (reserved field `$stale`) changes the design once `staleAfter` passes without a push (iOS 16.2+).
* Example: starting a case ends the previous one and uses `relevance: 100`, so the island always shows the one just started (iOS shows only one activity in the island).
* Scheduled end: `LiveActivity.scheduleEnd(at)` and `LiveDismiss.at(DateTime)`. On Android the notification stays alive and the system removes it at that time; on iOS it ends now and the card stays until then.
* iOS: Swift Package Manager support (`ios/live_island_kit/Package.swift`) as well as CocoaPods; both use the same sources. Tested with Flutter 3.29, 3.41 and 3.47.
* Reference designs with their own names and images, in Spanish: `RidePickupPreset` (light and dark, `RideBar.dotted` or `RideBar.line` bar), `RideDriverPreset` (driver view), `StorePickupPreset`, `RunPreset`, `MatchPreset`, and a train line built with `TransitPreset`.
* `LiveProgressStyle.dashed` (the remainder as a dashed stroke), `LiveProgressStyle.markers` (markers on the bar), `LivePointShape.ring`, `LiveImage.withSize` and `LiveImage.withHeight` (fixed height for wide images).
* `LiveIsland.check()` validates the design and the state with the same warnings as the prototype HTML.
* `LiveIslandPreview`: a Flutter preview of the island, the lock screen and the Android notification.
* 15 ready-made presets (`TripPreset`, `DeliveryPreset`, `CourierPreset`…) and an example app.
* Android: card mode (`LiveAndroidStyle.card`): your whole design with `RemoteViews` (two crests, a big score, a chart), with no chip or Live Update; `MatchPreset` and `StockPreset` use it by default.
* Android: `LiveAndroid(largeIcon, subText)`, a split bar as colored segments and markers as `ProgressStyle` points; the example designs set their own image, subtext and texts.
* Effects: `LiveProgressStyle.glow` (glowing cable), `LiveBox(border, borderWidth, glow)` (glowing border), `LiveSplitBar` (proportional colored segments) and `LiveText(italic: true)`; with `ChargePreset` and `FareSplitPreset`.
* Charts: `LiveSparkline` (line with area and end dot), `LiveGauge` (arc with a moving dot) and `LiveFlightPath` (curved route with a moving icon); with `StockPreset`, `FlightPathPreset` and `OrbitPreset`. On Android the arc and the route are a bar and the line is omitted.

Known limitations: on Android the bar's thickness, spacing and labels are decided by the system; buttons are not drawn in the expanded iOS island; no SwiftUI snapshot tests.
