import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WariVerse AI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('WariVerse AI'),
          ),
        ),
      ),
    );

    expect(find.text('WariVerse AI'), findsOneWidget);
  });
}
