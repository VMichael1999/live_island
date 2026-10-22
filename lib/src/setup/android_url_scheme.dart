/// Adds an intent filter for the URL scheme [scheme] to the app's main activity,
/// so a tap on a live activity (`deepLink: 'myapp://orders/42'`) opens the app.
///
/// [manifest] is the text of `AndroidManifest.xml`. Returns the new text, or `null`
/// when nothing had to change (the scheme is already there, or no launcher activity
/// was found).
String? addAndroidUrlScheme(String manifest, String scheme) {
  if (manifest.contains('android:scheme="$scheme"')) return null;
  for (final m in RegExp(
    r'<activity\b[\s\S]*?</activity>',
  ).allMatches(manifest)) {
    final activity = m.group(0)!;
    if (!activity.contains('android.intent.action.MAIN')) continue;
    final close = m.start + activity.lastIndexOf('</activity>');
    const indent = '            ';
    final filter = '''
$indent<intent-filter>
$indent    <action android:name="android.intent.action.VIEW" />
$indent    <category android:name="android.intent.category.DEFAULT" />
$indent    <category android:name="android.intent.category.BROWSABLE" />
$indent    <data android:scheme="$scheme" />
$indent</intent-filter>
        ''';
    return manifest.replaceRange(close, close, filter);
  }
  return null;
}
