import 'package:flutter_test/flutter_test.dart';
import 'package:who_logbook/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const WhoLogApp());
    expect(find.byType(WhoLogApp), findsOneWidget);
  });
}
