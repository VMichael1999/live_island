/// How an image fits in its space. It is never distorted.
enum LiveFit { contain, cover }

/// Shape of an image's crop.
enum LiveShape { rounded, circle, square }

/// Background of the lock screen card.
enum LiveBackground { system, light, accent }

/// Alignment of children in rows, columns and texts.
enum LiveAlign { start, center, end }

/// How the Android notification is drawn.
enum LiveAndroidStyle {
  /// Native style (`Notification.ProgressStyle`): title, text, bar, large image
  /// and chip. Android 16+ promotes it to a Live Update.
  liveUpdate,

  /// Card with your own design (`RemoteViews`): two images, a big score, any
  /// composition. Android does NOT promote it to a Live Update, so there is no
  /// chip in the status bar. It needs Android 12 (API 31) or later; on earlier
  /// versions [liveUpdate] is used.
  card,
}

/// Shape of a bar's stage dots.
enum LivePointShape {
  circle,
  square,
  rounded,

  /// Soft circle with a dot inside, like a map marker.
  ring,

  /// Thick ring with an empty center (the destination "dot").
  target,

  /// Thick square with soft corners and an empty center.
  targetSquare,
}

/// Background of the icon that moves along the bar.
enum LiveTrackerBackground { accentCircle, none }

/// Looks up a value in [values] by name; if it does not exist returns [fallback].
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
