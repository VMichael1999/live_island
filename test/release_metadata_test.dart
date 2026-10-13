import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardas de publicación: que el podspec y el manifiesto de privacidad no se
/// queden atrás del paquete.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final podspec = File('ios/live_island.podspec').readAsStringSync();

  test('el podspec tiene la misma versión que el pubspec', () {
    final pub = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    final pod = RegExp(
      r"s\.version\s*=\s*'([^']+)'",
    ).firstMatch(podspec)!.group(1);
    expect(pod, pub);
  });

  test('el manifiesto de privacidad declara el UserDefaults del App Group', () {
    final xml = File('ios/Resources/PrivacyInfo.xcprivacy').readAsStringSync();
    expect(xml, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(xml, contains('1C8F.1'));
    expect(xml, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
  });

  test('el podspec empaqueta el manifiesto (no está comentado)', () {
    final active = podspec
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('#'))
        .join('\n');
    expect(active, contains("Resources/PrivacyInfo.xcprivacy"));
  });

  test('la extensión recibe su propio manifiesto al ejecutar setup', () {
    final rb = File('bin/setup_ios.rb').readAsStringSync();
    expect(rb, contains('PrivacyInfo.xcprivacy'));
    expect(rb, contains('resources_build_phase'));
  });
}
