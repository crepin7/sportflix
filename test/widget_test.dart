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
    // Titre en deux parties : 'Sport' blanc + 'flix' vert thème.
    expect(find.text('Sport', findRichText: true), findsOneWidget);
    expect(find.text('flix', findRichText: true), findsOneWidget);
  });

  testWidgets('Search field is present', (WidgetTester tester) async {
    await tester.pumpWidget(const SportflixApp());
    expect(find.byType(TextField), findsOneWidget);
  });
}
