/// Raises the app's `minSdk` to [minimum] in the text of its `build.gradle(.kts)`.
///
/// A new Flutter app uses `flutter.minSdkVersion` (24 today) and the plugin needs
/// 26, so the first Android build fails with "minSdkVersion 24 cannot be smaller
/// than version 26". The value is never lowered: a bigger number, or Flutter's own
/// when it is bigger, stays. Returns the new text, or `null` when nothing had to
/// change (or no `minSdk` line was found).
String? raiseAndroidMinSdk(String gradle, {int minimum = 26}) {
  final line = RegExp(
    r'^([ \t]*)(minSdk(?:Version)?)([ \t]*=?[ \t]*)(flutter\.minSdkVersion|\d+)([ \t]*)$',
    multiLine: true,
  );
  final m = line.firstMatch(gradle);
  if (m == null) return null;
  final value = m[4]!;
  final isKotlin = m[3]!.contains('=');
  final String replacement;
  if (value == 'flutter.minSdkVersion') {
    replacement =
        isKotlin
            ? 'maxOf(flutter.minSdkVersion, $minimum)'
            : 'Math.max(flutter.minSdkVersion, $minimum)';
  } else if (int.parse(value) < minimum) {
    replacement = '$minimum';
  } else {
    return null;
  }
  return gradle.replaceRange(
    m.start,
    m.end,
    '${m[1]}${m[2]}${m[3]}$replacement${m[5]}',
  );
}
