import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportflix/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SportflixApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home screen displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const SportflixApp());
    // Titre en RichText : 'Sport' blanc + 'flix' vert thème.
    expect(find.text('Sportflix', findRichText: true), findsOneWidget);
  });

  testWidgets('Search field is present', (WidgetTester tester) async {
    await tester.pumpWidget(const SportflixApp());
    expect(find.byType(TextField), findsOneWidget);
  });
}
