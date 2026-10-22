// `CupertinoPageTransitionsBuilder` vive en `material` (Flutter 3.29) o en
// `cupertino` (versiones recientes): se importan los dos.
// ignore: unnecessary_import, unused_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'catalog.dart';
import 'editor_screen.dart';
import 'model.dart';
import 'preset_screen.dart';

final model = ExampleModel();

void main() {
  runApp(const ExampleApp());
  model.init();
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'live_island_kit',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1F6FEB),
      // La transición de zoom de Android fotografía la pantalla nueva en una
      // textura con mipmaps y Impeller + OpenGL ES la rechaza en algunos emuladores.
      // Sin `const`: en Flutter recientes el constructor ya no lo es.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
      ),
    ),
    // Tocar una actividad abre `liveisland://app/<caso>?progress=NN`: Flutter lo
    // entrega como ruta (`/<caso>?progress=NN`), también si la app estaba cerrada.
    onGenerateInitialRoutes: (name) {
      final opened = _routeFor(name);
      return [
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        if (opened != null) opened,
      ];
    },
    onGenerateRoute: (settings) => _routeFor(settings.name ?? '/'),
  );

  static Route<void>? _routeFor(String name) {
    final uri = Uri.parse(name);
    if (uri.path.length < 2) return null;
    final id = uri.path.substring(1);
    final entry = catalog.where((e) => e.id == id).firstOrNull;
    if (entry == null) return null;
    model.openedFrom = name;
    return MaterialPageRoute<void>(builder: (_) => PresetScreen(entry));
  }
}

/// Lista de los 15 presets y el editor.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('live_island_kit')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('Editor'),
          subtitle: const Text(
            'Change texts, color and progress and see the result',
          ),
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
              ),
        ),
        const Divider(),
        for (final e in catalog)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: e.preset.spec.accent,
              child: const Icon(Icons.bolt, color: Colors.white),
            ),
            title: Text(e.label),
            subtitle: Text(e.preset.runtimeType.toString()),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => PresetScreen(e)),
                ),
          ),
      ],
    ),
  );
}
