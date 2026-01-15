import 'package:flutter_test/flutter_test.dart';
import 'package:writr/main.dart';

void main() {
  testWidgets(
    'App starts and shows home screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(const WritrApp());

      expect(find.text('Welcome to Writr'), findsOneWidget);
      expect(
        find.text('A Scrivener-compatible editor'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Action buttons are present',
    (WidgetTester tester) async {
      await tester.pumpWidget(const WritrApp());

      expect(find.text('Open Project'), findsOneWidget);
      expect(find.text('Create New Project'), findsOneWidget);
    },
  );
}
