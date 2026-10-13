import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:postman/game/postman_app.dart';

void main() {
  testWidgets('shows the Little Forest Postman menu', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PostmanApp());

    expect(find.text('Little Forest'), findsOneWidget);
    expect(find.text('Postman'), findsOneWidget);
    expect(find.textContaining('Continue · World'), findsOneWidget);

    await tester.tap(find.textContaining('Continue · World'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('WORLD 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
