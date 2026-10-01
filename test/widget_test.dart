import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timos_app/main.dart';

void main() {
  testWidgets('zeigt den Wäsche-Timer im Startzustand', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TimosApp());
    await tester.pumpAndSettle();

    expect(find.text('TimosApp'), findsOneWidget);
    expect(find.text('Wäsche · 2:35 Std.'), findsOneWidget);
    expect(find.text('02:35:00'), findsOneWidget);
    expect(find.text('Wäsche starten'), findsOneWidget);
  });
}
