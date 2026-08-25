import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  testWidgets(
    'Executable Documentation Examples — Flutter Preview & ReceiptColumn',
    (WidgetTester tester) async {
      // 1. Universal Label Builder setup
      final shippingLabel = label(const LabelConfig(width: 80, height: 60))
        ..text(
          'EXPRESS DELIVERY',
          const TextOptions(x: 20, y: 20, size: 2, bold: true),
        )
        ..line(
          const LineOptions(x1: 20, y1: 50, x2: 600, y2: 50, thickness: 2),
        )
        ..barcode(
          'TRACK-998877',
          const BarcodeOptions(x: 20, y: 70, type: '128', height: 60),
        )
        ..qrcode(
          'https://track.example.com/998877',
          const QRCodeOptions(x: 20, y: 160, cellWidth: 4),
        )
        ..box(
          const BoxOptions(
            x: 10,
            y: 10,
            width: 620,
            height: 460,
            thickness: 2,
          ),
        );

      // 2. Receipt row formatting with ReceiptColumn
      final receiptRow = formatRow(
        [
          const ReceiptColumn(width: 20, align: 'left'),
          const ReceiptColumn(width: 12, align: 'right'),
        ],
        ['Espresso', '\$3.50'],
        32,
      );

      // 3. Test Flutter Widget Tree containing both Flutter Column and LabelPreview
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(receiptRow),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: LabelPreview(label: shippingLabel, showMeta: true),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text(receiptRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Executable Documentation Examples — Preview-Before-Print Canonical Workflow',
    (WidgetTester tester) async {
      // 1. Build label
      final builder = label(const LabelConfig(width: 50, height: 30))
        ..text('Portakal', const TextOptions(x: 20, y: 20));

      // 2. Resolve once to immutable print job
      final job = builder.resolve();

      // 3. Render Flutter preview from resolved job
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 240,
                child: LabelPreview.resolved(job: job),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('400x240 dots (203 DPI)'), findsOneWidget);

      // 4. Compile same job to bytes
      final bytes = tsc.compileResolved(job);
      expect(bytes, isNotEmpty);

      // 5. Mutate builder afterwards and verify job was unchanged
      builder.text('Mutated Text', const TextOptions(x: 100, y: 100));
      expect(job.elements.length, equals(1));
      expect(tsc.compileResolved(job), equals(bytes));
    },
  );

  testWidgets('Executable Documentation Examples — Direct Scene Preview', (
    WidgetTester tester,
  ) async {
    final builder = label(
      const LabelConfig(width: 40, height: 30),
    ).text('Scene Direct', const TextOptions(x: 10, y: 10));

    final scene = PreviewScene.fromBuilder(builder);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 240,
              child: LabelPreview.scene(scene: scene),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LabelPreview), findsOneWidget);
  });
}
