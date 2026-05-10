import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/app/app.dart';

void main() {
  testWidgets('app boots without exception', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PolarisApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
