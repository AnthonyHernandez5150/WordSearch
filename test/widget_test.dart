import 'package:flutter_test/flutter_test.dart';

import 'package:wordsearch/main.dart';

void main() {
  testWidgets('home screen shows the custom word search launcher', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('WordSearch'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Start Explorer'), findsOneWidget);

    await tester.tap(find.text('Expert'));
    await tester.pump();

    expect(find.text('Start Expert'), findsOneWidget);

    await tester.tap(find.text('Start Expert'));
    await tester.pumpAndSettle();

    expect(find.text('Find every hidden word'), findsOneWidget);
    expect(find.text('Night Sprint'), findsOneWidget);
  });
}
