import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writr/main.dart';

void main() {
  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WritrApp());

    expect(find.text('Welcome to Writr'), findsOneWidget);
    expect(find.text('A Scrivener-compatible editor for Android'), findsOneWidget);
  });

  testWidgets('Cloud provider buttons are present', (WidgetTester tester) async {
    await tester.pumpWidget(const WritrApp());

    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Dropbox'), findsOneWidget);
    expect(find.text('OneDrive'), findsOneWidget);
    expect(find.text('Local Storage'), findsOneWidget);
  });
}
