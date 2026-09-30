import 'package:flutter_test/flutter_test.dart';
import 'package:app_mob_alimento/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const RestaurantFeedbackApp());
    expect(find.text('Avaliação do Restaurante'), findsOneWidget);
  });
}
