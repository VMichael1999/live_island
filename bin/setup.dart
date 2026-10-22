import 'dart:io';
import 'dart:isolate';

import 'package:live_island_kit/src/setup/android_min_sdk.dart';
import 'package:live_island_kit/src/setup/android_url_scheme.dart';

/// Configures a Flutter app to use live_island_kit:
///
///     dart run live_island_kit:setup [--app-group group.com.myapp] [--extension LiveIslandExtension]
///
/// Android: raises the app's `minSdk` to 26, which the plugin needs.
/// iOS: adds the Widget Extension to the Xcode project, the App Group and
/// `NSSupportsLiveActivities` (with `--push`, also the push permission), and
/// raises the Podfile to iOS 15. It can be run again to update the renderer.
Future<void> main(List<String> args) async {
  String? group;
  var extension = 'LiveIslandExtension';
  var push = false;
  String? urlScheme;
  String project = '.';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--app-group':
        group = args[++i];
      case '--extension':
        extension = args[++i];
      case '--push':
        push = true;
      case '--url-scheme':
        urlScheme = args[++i];
      case '--project':
        project = args[++i];
      case '-h':
      case '--help':
        _usage();
        return;
      default:
        stderr.writeln('Unknown option: ${args[i]}');
        _usage();
        exitCode = 64;
        return;
    }
  }

  final iosDir = Directory('$project/ios');
  if (!File('$project/pubspec.yaml').existsSync()) {
    stderr.writeln('Run this command at the root of a Flutter app.');
    exitCode = 66;
    return;
  }
  _configureAndroid(project, urlScheme);

  if (!Directory('${iosDir.path}/Runner.xcodeproj').existsSync()) {
    stdout.writeln('iOS: skipped (this app has no ios/ folder).');
    return;
  }

  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:live_island_kit/live_island_kit.dart'),
  );
  if (uri == null) {
    stderr.writeln(
      'The live_island_kit package was not found. Is it in your pubspec.yaml?',
    );
    exitCode = 66;
    return;
  }
  final root = File.fromUri(uri).parent.parent.path;

  if (!Platform.isMacOS) {
    stdout.writeln('iOS: skipped (Xcode only exists on macOS).');
    return;
  }

  stdout.writeln('Configuring iOS…');
  final result = await Process.run('ruby', [
    '$root/bin/setup_ios.rb',
    iosDir.path,
    '$root/ios/LiveIslandExtension',
    group ?? '-',
    extension,
    push ? 'push' : '-',
    urlScheme ?? '-',
  ]);
  stdout.write(result.stdout);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    stderr.writeln(
      '\nCould not configure iOS. You need Ruby and the xcodeproj gem '
      '(it comes with CocoaPods: `sudo gem install cocoapods`).',
    );
    exitCode = result.exitCode;
    return;
  }

  stdout.writeln('''

Done. One thing is left, once, in Xcode (ios/Runner.xcworkspace):
  1. Select your development team on the Runner and $extension targets.
  2. On a real device, turn on Live Activities for the app (Settings).
Then: flutter run''');
}

/// Raises `minSdk` in the app's `android/app/build.gradle(.kts)` to 26.
void _configureAndroid(String project, String? urlScheme) {
  for (final name in ['build.gradle.kts', 'build.gradle']) {
    final file = File('$project/android/app/$name');
    if (!file.existsSync()) continue;
    final updated = raiseAndroidMinSdk(file.readAsStringSync());
    if (updated != null) {
      file.writeAsStringSync(updated);
      stdout.writeln('Android: minSdk raised to 26 in android/app/$name.');
    }
    break;
  }
  if (urlScheme == null) return;
  final manifest = File('$project/android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) return;
  final updated = addAndroidUrlScheme(manifest.readAsStringSync(), urlScheme);
  if (updated != null) {
    manifest.writeAsStringSync(updated);
    stdout.writeln(
      'Android: URL scheme $urlScheme:// added to AndroidManifest.xml.',
    );
  }
}

void _usage() {
  stdout.writeln('''
Usage: dart run live_island_kit:setup [options]

  --app-group <id>     App Group (default group.<bundle id>.liveisland)
  --push               Adds the push permission (aps-environment) to update
                       or start activities through APNs; it needs a developer
                       account with the Push Notifications capability
  --url-scheme <name>  URL scheme of your app (for example myapp): registers it
                       on iOS and Android so that a tap on an activity started
                       with deepLink: 'myapp://orders/42' opens the app
  --extension <name>   Name of the Widget Extension (LiveIslandExtension)
  --project <dir>      Folder of the Flutter app (default .)
''');
}
