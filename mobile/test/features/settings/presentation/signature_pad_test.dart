import 'package:alize_mobile/features/settings/presentation/widgets/signature_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<SignaturePadState> pumpPad(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: SignaturePad(),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<SignaturePadState>(find.byType(SignaturePad));
  }

  testWidgets('snapshot is null when the pad is empty', (tester) async {
    final pad = await pumpPad(tester);

    expect(pad.dirty, isFalse);
    expect(await pad.snapshot(), isNull);
  });

  testWidgets('drawing sets dirty and snapshot starts with data:image/png',
      (tester) async {
    final pad = await pumpPad(tester);
    final center = tester.getCenter(find.byType(SignaturePad));

    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(48, 24));
    await gesture.moveBy(const Offset(20, -10));
    await gesture.up();
    await tester.pump();

    expect(pad.dirty, isTrue);
    final snap = await tester.runAsync(pad.snapshot);
    expect(snap, isNotNull);
    expect(snap, startsWith('data:image/png'));
  });
}
