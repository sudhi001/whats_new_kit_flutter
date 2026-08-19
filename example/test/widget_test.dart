import 'package:flutter_test/flutter_test.dart';
import 'package:whats_new_kit_example/main.dart';

void main() {
  testWidgets('the example app lists its demos', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('showWhatsNewSheet'), findsOneWidget);
    expect(find.text('WhatsNewKit'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
  });

  testWidgets('tapping a reference sheet presents it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text("What's New\nin Calendar"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
