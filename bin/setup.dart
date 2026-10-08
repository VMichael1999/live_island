import 'dart:io';
import 'dart:isolate';

/// Configura una app Flutter para usar live_island en iOS:
///
///     dart run live_island:setup [--app-group group.com.miapp] [--extension LiveIslandExtension]
///
/// Agrega el Widget Extension al proyecto de Xcode, el App Group y
/// `NSSupportsLiveActivities` (con `--push`, también el permiso de push). Se puede repetir para actualizar el renderer.
Future<void> main(List<String> args) async {
  String? group;
  var extension = 'LiveIslandExtension';
  var push = false;
  String project = '.';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--app-group':
        group = args[++i];
      case '--extension':
        extension = args[++i];
      case '--push':
        push = true;
      case '--project':
        project = args[++i];
      case '-h':
      case '--help':
        _usage();
        return;
      default:
        stderr.writeln('Opción desconocida: ${args[i]}');
        _usage();
        exitCode = 64;
        return;
    }
  }

  final iosDir = Directory('$project/ios');
  if (!File('$project/pubspec.yaml').existsSync() ||
      !Directory('${iosDir.path}/Runner.xcodeproj').existsSync()) {
    stderr.writeln(
      'Ejecuta este comando en la raíz de una app Flutter con carpeta ios/.',
    );
    exitCode = 66;
    return;
  }

  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:live_island/live_island.dart'),
  );
  if (uri == null) {
    stderr.writeln(
      'No se encontró el paquete live_island. ¿Está en tu pubspec.yaml?',
    );
    exitCode = 66;
    return;
  }
  final root = File.fromUri(uri).parent.parent.path;

  if (!Platform.isMacOS) {
    stdout.writeln('iOS: omitido (Xcode solo existe en macOS).');
    return;
  }

  stdout.writeln('Configurando iOS…');
  final result = await Process.run('ruby', [
    '$root/bin/setup_ios.rb',
    iosDir.path,
    '$root/ios/LiveIslandExtension',
    group ?? '-',
    extension,
    push ? 'push' : '-',
  ]);
  stdout.write(result.stdout);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    stderr.writeln(
      '\nNo se pudo configurar iOS. Necesitas Ruby y la gema xcodeproj '
      '(viene con CocoaPods: `sudo gem install cocoapods`).',
    );
    exitCode = result.exitCode;
    return;
  }

  stdout.writeln('''

Listo. Falta, una sola vez, en Xcode (ios/Runner.xcworkspace):
  1. Selecciona tu equipo de desarrollo en los targets Runner y $extension.
  2. En un dispositivo real activa las Live Activities para la app (Ajustes).
Luego: flutter run''');
}

void _usage() {
  stdout.writeln('''
Uso: dart run live_island:setup [opciones]

  --app-group <id>     App Group (por defecto group.<bundle id>.liveisland)
  --push               Agrega el permiso de push (aps-environment) para actualizar
                       o iniciar actividades por APNs; requiere una cuenta de
                       desarrollador con la capacidad Push Notifications
  --extension <name>   Nombre del Widget Extension (LiveIslandExtension)
  --project <dir>      Carpeta de la app Flutter (por defecto .)
''');
}
