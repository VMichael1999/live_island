import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_example/catalog.dart';
import 'package:live_island_example/main.dart';

void main() {
  testWidgets('la lista muestra los 15 presets y el editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Editor'), findsOneWidget);
    expect(catalog, hasLength(15));
    for (final e in catalog) {
      expect(find.text(e.label), findsOneWidget);
    }
  });

  testWidgets('un preset muestra su vista previa y su validación', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Estacionamiento'));
    await tester.pumpAndSettle();
    expect(find.text('Estacionamiento activo'), findsWidgets);
    expect(find.text('Validación'), findsOneWidget);
    // Retira la pantalla para cancelar el reloj de la vista previa.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el editor cambia el título en la vista previa', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Título'),
      'Mi título',
    );
    await tester.pump();
    expect(find.text('Mi título'), findsWidgets);
    expect(find.textContaining('final preset = TripPreset()'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
