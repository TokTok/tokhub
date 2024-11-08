import 'package:flutter_test/flutter_test.dart';
import 'package:tokhub/app_state.dart';
import 'package:tokhub/main.dart';

void main() {
  testWidgets('Smoke test, ensure the widget can build',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester
        .pumpWidget(MyApp(store: createStore(const AppState.initialState())));
  });
}
