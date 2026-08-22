import 'package:flutter_test/flutter_test.dart';

import 'package:synap/main.dart';

void main() {
  testWidgets('mostra o header e o botão da câmera', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SynapApp());

    expect(find.text('foto do aparelho → como treinar'), findsOneWidget);
    expect(find.text('TIRAR FOTO DO APARELHO'), findsOneWidget);
  });
}
