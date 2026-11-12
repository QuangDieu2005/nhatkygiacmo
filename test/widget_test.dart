import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app.dart';

void main() {
  testWidgets('Dream Diary app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DreamDiaryApp());
    expect(find.byType(DreamDiaryApp), findsOneWidget);
    // Bỏ qua pending timer của Splash Screen trong smoke test
    await tester.pump(const Duration(seconds: 3));
  });
}
