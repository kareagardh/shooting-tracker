import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShootingTrackerApp());
    expect(find.text('Shooting Results'), findsOneWidget);
  });
}
