import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  group('Executable Documentation Examples — Flutter & Core Re-Export', () {
    test('1. README Quick Start Snippet', () {
      // 1. Build a label layout
      final builder = label(const LabelConfig(width: 40, height: 30))
        ..text('Product A1', const TextOptions(x: 20, y: 20, size: 2, bold: true))
        ..qrcode('https://example.com/a1', const QRCodeOptions(x: 20, y: 70, cellWidth: 3));

      // 2. Resolve into an immutable print job
      final ResolvedLabel job = builder.resolve();

      // 3. Compile the exact same job to authoritative printer bytes
      final Uint8List bytes = tsc.compileResolved(job);

      expect(bytes, isNotEmpty);
      expect(bytes, isA<Uint8List>());
    });

    test('2. Simple vs Preview-Before-Print Workflows', () {
      // Simple Workflow
      final simpleBuilder = label(const LabelConfig(width: 80, height: 50))
        ..text('BATCH ITEM #1042', const TextOptions(x: 20, y: 20));
      final Uint8List simpleBytes = tsc.compile(simpleBuilder);
      expect(simpleBytes, isNotEmpty);

      // Preview-Before-Print Workflow
      final builder = label(const LabelConfig(width: 50, height: 30))
        ..text('Portakal', const TextOptions(x: 20, y: 20));
      final job = builder.resolve();
      final previewBytes = tsc.compileResolved(job);
      expect(previewBytes, isNotEmpty);
    });

    testWidgets('3. Preview-Before-Print Flutter Screen Widget', (WidgetTester tester) async {
      final builder = label(const LabelConfig(width: 80, height: 60))
        ..text('EXPRESS DELIVERY', const TextOptions(x: 20, y: 20, size: 2, bold: true))
        ..line(const LineOptions(x1: 20, y1: 50, x2: 600, y2: 50, thickness: 2))
        ..barcode('TRACK-998877', const BarcodeOptions(x: 20, y: 70, type: '128', height: 60))
        ..qrcode('https://track.example.com/998877', const QRCodeOptions(x: 20, y: 160, cellWidth: 4))
        ..box(const BoxOptions(x: 10, y: 10, width: 620, height: 460, thickness: 2));

      final ResolvedLabel job = builder.resolve();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Confirm Label')),
            body: Center(
              child: LabelPreview.resolved(job: job, showMeta: true),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                final bytes = tsc.compileResolved(job);
                expect(bytes, isNotEmpty);
              },
              child: const Icon(Icons.print),
            ),
          ),
        ),
      );

      expect(find.text('Confirm Label'), findsOneWidget);
      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.byIcon(Icons.print), findsOneWidget);

      // Tap print button and verify compilation
      await tester.tap(find.byIcon(Icons.print));
      await tester.pump();
    });

    testWidgets('4. ReceiptColumn formatting with Flutter Column collision shielding', (
      WidgetTester tester,
    ) async {
      final receiptRow = formatRow(
        [
          const ReceiptColumn(width: 20, align: 'left'),
          const ReceiptColumn(width: 12, align: 'right'),
        ],
        ['Espresso', '\$3.50'],
        32,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Receipt Header'),
                Text(receiptRow),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(find.text('Receipt Header'), findsOneWidget);
      expect(find.text(receiptRow), findsOneWidget);
    });

    test('5. Common Error Handling Snippet Verification', () {
      final geometricLabel = label(const LabelConfig(width: 80, height: 50))
        ..box(const BoxOptions(x: 10, y: 10, width: 200, height: 100));

      final job = geometricLabel.resolve();

      // Catch UnsupportedFeatureError
      var unsupportedCaught = false;
      try {
        escpos.compileResolved(job);
      } on UnsupportedFeatureError catch (e) {
        unsupportedCaught = true;
        expect(e.message, contains('ESC/POS'));
      }
      expect(unsupportedCaught, isTrue);

      // Catch EncodingError
      var encodingCaught = false;
      try {
        final encoder = getEncoder(PrinterCodePage.cp437);
        encoder.encode('Price: 15.50 €');
      } on UnsupportedCharacterException catch (e) {
        encodingCaught = true;
        expect(e.character, equals('€'));
      }
      expect(encodingCaught, isTrue);
    });

    test('6. Byte-Safe Contract: Raw bytes written to conceptual sink', () {
      final job = label(const LabelConfig(width: 40, height: 30))
        .text('DATA', const TextOptions(x: 10, y: 10))
        .resolve();

      final Uint8List bytes = tsc.compileResolved(job);

      final mockBuffer = <int>[];
      void transportWrite(Uint8List b) {
        mockBuffer.addAll(b);
      }

      transportWrite(bytes);
      expect(mockBuffer, isNotEmpty);
      expect(mockBuffer.length, equals(bytes.length));
    });

    test('7. Portakal 1.2 Hybrid Layout & Typed Barcode Workflow', () {
      final receipt = sequentialLabel(const LabelConfig(width: 80, height: 80, unit: Unit.mm))
        ..text('PORTAKAL CAFE', const TextOptions(size: 2, bold: true))
        ..divider()
        ..row('Iced Latte', r'$2.50')
        ..row('Butter Croissant', r'$2.00')
        ..divider()
        ..row('TOTAL', r'$4.50', bold: true)
        ..barcode(
          'ORD-8821',
          BarcodeOptions.typed(
            x: 20,
            y: 450,
            symbology: BarcodeSymbology.code128,
            height: 50,
          ),
        );

      final ResolvedLabel job = receipt.resolve();
      final Uint8List escposBytes = escpos.compileResolved(job);
      final Uint8List tscBytes = tsc.compileResolved(job);
      final Uint8List zplBytes = zpl.compileResolved(job);

      expect(escposBytes, isNotEmpty);
      expect(tscBytes, isNotEmpty);
      expect(zplBytes, isNotEmpty);
    });
  });
}
