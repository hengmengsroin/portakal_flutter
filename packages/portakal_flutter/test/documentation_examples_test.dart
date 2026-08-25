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
        ..line(const LineOptions(x1: 20, y1: 50, x2: 600, y2: 50, thickness: 2))
        ..barcode(
          'TRACK-998877',
          const BarcodeOptions(x: 20, y: 70, type: '128', height: 60),
        )
        ..qrcode(
          'https://track.example.com/998877',
          const QRCodeOptions(x: 20, y: 160, cellWidth: 4),
        )
        ..box(
          const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2),
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
}
