// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:routewise/main.dart';
import 'package:routewise/services/route_provider.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Mock load .env configuration for unit testing environment
    dotenv.testLoad(fileInput: 'GOOGLE_MAPS_API_KEY=YOUR_API_KEY_HERE');

    // Build our app with the required provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RouteProvider(),
        child: const RouteWiseApp(),
      ),
    );

    // Verify that the home screen loads and shows the RouteWise title.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('RouteWise'), findsOneWidget);
  });
}
