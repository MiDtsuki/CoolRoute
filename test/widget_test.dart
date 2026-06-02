import 'package:flutter_test/flutter_test.dart';

import 'package:cool_route/app.dart';

void main() {
  testWidgets('CoolRoute renders welcome and main tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const CoolRouteApp(firebaseReady: false));

    expect(find.text('CoolRoute'), findsWidgets);
    expect(find.text('Continue as prototype user'), findsOneWidget);

    await tester.tap(find.text('Continue as prototype user'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Route'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
  });
}
