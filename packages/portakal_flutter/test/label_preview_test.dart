import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  group('LabelPreview widget tests', () {
    testWidgets('renders basic label without exception', (
      WidgetTester tester,
    ) async {
      final sampleLabel = label(const LabelConfig(width: 40, height: 30))
          .text('Hello Flutter', const TextOptions(x: 10, y: 10))
          .box(
            const BoxOptions(x: 5, y: 5, width: 100, height: 80, thickness: 2),
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 240,
                child: LabelPreview(label: sampleLabel),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('320x240 dots (203 DPI)'), findsOneWidget);
    });

    testWidgets('respects showMeta=false to hide metadata label', (
      WidgetTester tester,
    ) async {
      final sampleLabel = label(
        const LabelConfig(width: 40, height: 30),
      ).text('No Meta', const TextOptions(x: 10, y: 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 240,
                child: LabelPreview(label: sampleLabel, showMeta: false),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('320x240 dots (203 DPI)'), findsNothing);
    });

    testWidgets(
      'renders complex elements including barcode, qr, image, lines',
      (WidgetTester tester) async {
        final bitmap = MonochromeBitmap(
          data: Uint8List.fromList([0xFF, 0x00, 0xAA, 0x55]),
          width: 16,
          height: 2,
          bytesPerRow: 2,
        );

        final complexLabel = label(const LabelConfig(width: 80, height: 60))
            .text(
              'Invoice #100',
              const TextOptions(x: 10, y: 10, bold: true, size: 2),
            )
            .line(
              const LineOptions(x1: 10, y1: 40, x2: 600, y2: 40, thickness: 2),
            )
            .circle(
              const CircleOptions(x: 100, y: 100, diameter: 50, thickness: 2),
            )
            .ellipse(
              const EllipseOptions(x: 200, y: 100, width: 80, height: 40),
            )
            .reverse(
              const ReverseOptions(x: 10, y: 150, width: 200, height: 30),
            )
            .erase(const EraseOptions(x: 50, y: 160, width: 50, height: 10))
            .image(bitmap, const ImageOptions(x: 10, y: 200))
            .barcode(
              '12345678',
              const BarcodeOptions(x: 10, y: 250, type: '128', height: 50),
            )
            .qrcode(
              'https://example.com',
              const QRCodeOptions(x: 250, y: 250, cellWidth: 4),
            )
            .rawAscii('RAW_PASSTHROUGH');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: LabelPreview(label: complexLabel),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LabelPreview), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'verifies core builder and native printers accessible via portakal_flutter re-export',
      () {
        final builder = label(const LabelConfig(width: 50, height: 30));
        expect(builder, isA<LabelBuilder>());

        final tsc = TscPrinter();
        expect(tsc, isA<TscPrinter>());

        final zpl = ZplPrinter();
        expect(zpl, isA<ZplPrinter>());

        final escpos = EscPosPrinter();
        expect(escpos, isA<EscPosPrinter>());
      },
    );
  });
}
