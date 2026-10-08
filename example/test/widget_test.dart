import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_example/main.dart';

void main() {
  testWidgets('muestra la vista previa y el informe de validación del taxi', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Tu conductor está en camino'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Validación'), 400);
    expect(find.text('Validación'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Android la promueve a Live Update'),
      400,
    );

    // Retira la vista previa para cancelar su reloj.
    await tester.pumpWidget(const SizedBox());
  });
}
