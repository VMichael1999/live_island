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
    title: 'live_island',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1F6FEB),
      // La transición de zoom de Android fotografía la pantalla nueva en una
      // textura con mipmaps y Impeller + OpenGL ES la rechaza en algunos emuladores.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()},
      ),
    ),
    home: const HomeScreen(),
  );
}

/// Lista de los 15 presets y el editor.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('live_island')),
    body: ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.tune),
          title: const Text('Editor'),
          subtitle: const Text(
            'Cambia textos, color y avance y mira el resultado',
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
