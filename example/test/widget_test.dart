import 'package:flutter_test/flutter_test.dart';
import 'package:live_island_example/main.dart';

void main() {
  testWidgets('muestra el informe de validación del taxi', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Validación'), findsOneWidget);
    expect(
      find.textContaining('Android la promueve a Live Update'),
      findsOneWidget,
    );
  });
}
