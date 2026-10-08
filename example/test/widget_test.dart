import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_example/main.dart';

void main() {
  testWidgets('muestra la vista previa y el informe de validación del taxi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Tu conductor está en camino'), findsWidgets);
    expect(find.text('Validación'), findsOneWidget);
    expect(
      find.textContaining('Android la promueve a Live Update'),
      findsOneWidget,
    );
    // Sin actividad iniciada, solo se puede iniciar.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    // Retira la vista previa para cancelar su reloj.
    await tester.pumpWidget(const SizedBox());
  });
}
