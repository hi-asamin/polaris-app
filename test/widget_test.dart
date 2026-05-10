import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';

void main() {
  testWidgets('renders skeleton home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PolarisApp()));
    await tester.pumpAndSettle();

    expect(find.text('polaris'), findsAtLeastNWidgets(1));
    expect(find.text('polaris-app skeleton ready'), findsOneWidget);
  });
}
