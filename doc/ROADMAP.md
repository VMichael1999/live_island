# Roadmap

What `live_island_kit` does not do yet, so you know before you design. Everything
else in the README is covered by tests on Dart, Swift and Kotlin and by integration
tests against the real platforms.

## Known limits (0.4.0)

- **Buttons.** They are drawn as capsules with a label (lock screen and Android
  notification). There is no round icon button, and the expanded iOS island never
  runs actions: a tap on it opens the app.
- **Images.** An image keeps its own shape (`square`, `rounded`, `circle`). It is not
  cropped to the island and cannot bleed to the edge of the card.
- **Android.** A card is not promoted to a Live Update and has no `stale` state. Its
  width is narrower than the iOS lock screen card, so check your design on both.
- **State keys.** The presets read `titulo`, `nombre`, `llegaA`… (Spanish identifiers,
  kept for compatibility). In your own layouts you choose any names.

## Not verified yet

- A physical iPhone with real signing (all iOS tests ran on the simulator).
- Swiping the activity away, on iOS and on Android.
- The `stale` state end to end (it has unit tests for the mapping only).

## Ideas for 0.5.0

1. Round icon buttons with an action, also in the expanded island.
2. Images that bleed to the edge of the card.
3. Built-in Kotlin (AGP 9) for the Android plugin; it raises the minimum Flutter
   version to 3.44.
4. `LiveSnapshot` (render a design to an image): it needs live counters and push
   with the app closed before it can ship.
