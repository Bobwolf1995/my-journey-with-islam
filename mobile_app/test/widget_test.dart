import 'package:flutter_test/flutter_test.dart';
import 'package:rihlati_with_islam/app.dart';

void main() {
  testWidgets('Rihlati app starts', (tester) async {
    await tester.pumpWidget(const RihlatiApp());

    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
