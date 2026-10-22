import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `dart run live_island_kit:setup` sube la plataforma del Podfile a iOS 15: si no,
/// una app nueva (que trae `# platform :ios, '12.0'`) falla en `pod install`.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('podfile_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// Corre `raise_podfile_platform` sobre un Podfile con ese contenido (o sin
  /// Podfile si es null) y devuelve el resultado y el texto final.
  (String, String?) correr(String? podfile) {
    final f = File('${tmp.path}/Podfile');
    if (podfile != null) f.writeAsStringSync(podfile);
    final r = Process.runSync('ruby', [
      '-e',
      "require './bin/podfile_platform'; puts raise_podfile_platform(ARGV[0])",
      f.path,
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    return (
      (r.stdout as String).trim(),
      f.existsSync() ? f.readAsStringSync() : null,
    );
  }

  test(
    "el '# platform :ios, 12.0' de la plantilla de Flutter se activa en 15.0",
    () {
      final (res, text) = correr(
        "# Uncomment this line to define a global platform for your project\n"
        "# platform :ios, '12.0'\n\nproject 'Runner'\n",
      );
      expect(res, 'raised');
      expect(text, contains("\nplatform :ios, '15.0'\n"));
      expect(text, isNot(contains("# platform :ios")));
      expect(text, contains("project 'Runner'"));
    },
  );

  test('una plataforma activa más baja se sube', () {
    final (res, text) = correr("platform :ios, '13.0'\n");
    expect(res, 'raised');
    expect(text, "platform :ios, '15.0'\n");
  });

  test('una plataforma igual o mayor no se toca', () {
    for (final v in ['15.0', '16.1', '17']) {
      final original = "platform :ios, '$v'\nproject 'Runner'\n";
      final (res, text) = correr(original);
      expect(res, 'ok', reason: v);
      expect(text, original);
    }
  });

  test('sin línea de plataforma se agrega al principio', () {
    final (res, text) = correr("project 'Runner'\n");
    expect(res, 'raised');
    expect(text, startsWith("platform :ios, '15.0'\n"));
  });

  test('sin Podfile (solo Swift Package Manager) no hace nada', () {
    final (res, text) = correr(null);
    expect(res, 'missing');
    expect(text, isNull);
  });

  test('si se vuelve a correr, no cambia nada', () {
    correr("# platform :ios, '12.0'\n");
    final (res, _) = correr("platform :ios, '15.0'\n");
    expect(res, 'ok');
  });
}
