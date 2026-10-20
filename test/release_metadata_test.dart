import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardas de publicación: que el podspec y el manifiesto de privacidad no se
/// queden atrás del paquete.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final podspec = File('ios/live_island_kit.podspec').readAsStringSync();

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
    final xml =
        File(
          'ios/live_island_kit/Sources/live_island_kit/PrivacyInfo.xcprivacy',
        ).readAsStringSync();
    expect(xml, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(xml, contains('1C8F.1'));
    expect(xml, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
  });

  test('el podspec empaqueta el manifiesto (no está comentado)', () {
    final active = podspec
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('#'))
        .join('\n');
    expect(
      active,
      contains('live_island_kit/Sources/live_island_kit/PrivacyInfo.xcprivacy'),
    );
  });

  test('la extensión recibe su propio manifiesto al ejecutar setup', () {
    final rb = File('bin/setup_ios.rb').readAsStringSync();
    expect(rb, contains('PrivacyInfo.xcprivacy'));
    expect(rb, contains('resources_build_phase'));
  });

  test('el paquete de Swift Package Manager apunta a las mismas fuentes', () {
    final pkg = File('ios/live_island_kit/Package.swift').readAsStringSync();
    expect(pkg, contains('name: "live_island_kit"'));
    expect(pkg, contains('.process("PrivacyInfo.xcprivacy")'));
    expect(pkg, contains('-weak_framework'));
    expect(
      File(
        'ios/live_island_kit/Sources/live_island_kit/LiveIslandPlugin.swift',
      ).existsSync(),
      isTrue,
    );
    // El podspec lee las mismas fuentes que el paquete.
    expect(
      podspec,
      contains("live_island_kit/Sources/live_island_kit/**/*.swift"),
    );
  });

  // Apple exige declarar el motivo de cada API de «razón requerida». El código
  // solo usa UserDefaults del App Group (1C8F.1): si alguien agrega otra API de
  // estas categorías sin declararla, App Store puede rechazar la app de un cliente.
  test('el código de iOS no usa APIs de razón requerida sin declararlas', () {
    final manifiesto =
        File(
          'ios/live_island_kit/Sources/live_island_kit/PrivacyInfo.xcprivacy',
        ).readAsStringSync();
    final declaradas = {
      for (final m in RegExp(
        r'NSPrivacyAccessedAPICategory(\w+)',
      ).allMatches(manifiesto))
        m.group(1),
    };
    // categoría → patrón que delata su uso en el código Swift.
    final categorias = {
      'FileTimestamp': RegExp(
        r'creationDate|modificationDate|NSFileCreationDate|NSFileModificationDate|contentModificationDateKey|creationDateKey|\bstat\(|getattrlist',
      ),
      'SystemBootTime': RegExp(r'systemUptime|mach_absolute_time'),
      'DiskSpace': RegExp(
        r'volumeAvailableCapacity|volumeTotalCapacity|systemFreeSize|\bstatfs\(|\bstatvfs\(',
      ),
      'ActiveKeyboards': RegExp(r'activeInputModes'),
      'UserDefaults': RegExp(r'UserDefaults'),
    };
    final fuentes = [
      ...Directory('ios/live_island_kit/Sources').listSync(recursive: true),
      ...Directory('ios/LiveIslandExtension').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.swift'));
    for (final f in fuentes) {
      final texto = f.readAsStringSync();
      for (final e in categorias.entries) {
        if (e.value.hasMatch(texto)) {
          expect(
            declaradas,
            contains(e.key),
            reason:
                '${f.path} usa la categoría ${e.key}, que falta en PrivacyInfo.xcprivacy',
          );
        }
      }
    }
    expect(declaradas, {'UserDefaults'});
  });
}
