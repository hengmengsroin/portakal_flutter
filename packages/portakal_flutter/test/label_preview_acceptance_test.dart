import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  group('LabelPreview Visual Acceptance & Semantic Tests (V01-V07)', () {
    testWidgets('V01 — Invoice fixture visual acceptance and semantics', (
      WidgetTester tester,
    ) async {
      final invoice =
          label(const LabelConfig(width: 80, height: 100, copies: 2))
              .text('INVOICE #001',
                  const TextOptions(x: 20, y: 20, size: 2, bold: true))
              .barcode(
                  'INV100',
                  const BarcodeOptions(
                      x: 20, y: 60, type: '128', height: 50, readable: 1))
              .qrcode('https://inv.example.com/100',
                  const QRCodeOptions(x: 300, y: 60, cellWidth: 4));

      final job = invoice.resolve();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 400,
                child: LabelPreview.resolved(job: job),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('639x799 dots (203 DPI)'), findsOneWidget);

      // Verify semantics label
      final semantics = tester.getSemantics(find.byType(LabelPreview));
      expect(semantics.label, contains('Print preview, 80 by 100 millimeters'));
      expect(semantics.label, contains('639 by 799 dots'));
    });

    testWidgets('V02 — Shipping label fixture visual acceptance', (
      WidgetTester tester,
    ) async {
      final shipping = label(const LabelConfig(width: 100, height: 150))
          .text('PRIORITY MAIL',
              const TextOptions(x: 20, y: 20, size: 2, bold: true))
          .barcode('TRACK123',
              const BarcodeOptions(x: 20, y: 80, type: '39', height: 60));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 450,
                child: LabelPreview(label: shipping),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('799x1199 dots (203 DPI)'), findsOneWidget);
    });

    testWidgets('V03 — Product & price label fixture with EAN13 barcode', (
      WidgetTester tester,
    ) async {
      final product = label(const LabelConfig(width: 50, height: 30))
          .text('ORGANIC TEA', const TextOptions(x: 10, y: 10, bold: true))
          .text('\$12.50', const TextOptions(x: 10, y: 30, size: 2))
          .barcode('4006381333931',
              const BarcodeOptions(x: 10, y: 60, type: 'EAN13', height: 40));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 150,
                child: LabelPreview(label: product),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('400x240 dots (203 DPI)'), findsOneWidget);
    });

    testWidgets('V04 — Receipt continuous layout visual acceptance', (
      WidgetTester tester,
    ) async {
      final receipt = label(const LabelConfig(width: 80))
          .text('STORE #123', const TextOptions(x: 20, y: 10, bold: true))
          .text('Coffee 1x \$3.00', const TextOptions(x: 20, y: 40));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 200,
                child: LabelPreview(label: receipt),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('639x400 dots (203 DPI)'), findsOneWidget);
    });

    testWidgets('V05 — Barcode and QR matrix deterministic layout', (
      WidgetTester tester,
    ) async {
      final codeLabel = label(const LabelConfig(width: 60, height: 40))
          .barcode(
              'CODE128PAYLOAD',
              const BarcodeOptions(
                  x: 10, y: 10, type: '128', height: 40, readable: 1))
          .qrcode('https://portakal.dev/qr',
              const QRCodeOptions(x: 200, y: 10, cellWidth: 3));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: LabelPreview(label: codeLabel),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(find.text('480x320 dots (203 DPI)'), findsOneWidget);
    });

    testWidgets('V06 — Unicode label visual acceptance', (
      WidgetTester tester,
    ) async {
      final unicodeLabel = label(const LabelConfig(width: 50, height: 30))
          .text('CAFÉ & THÉ: 10.50€', const TextOptions(x: 10, y: 10));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 250,
                height: 150,
                child: LabelPreview(label: unicodeLabel),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('V07 — Bitmap logo visual acceptance', (
      WidgetTester tester,
    ) async {
      final bmp = MonochromeBitmap(
        data: Uint8List.fromList([0xF0, 0x0F, 0xAA, 0x55]),
        width: 16,
        height: 2,
        bytesPerRow: 2,
      );

      final bitmapLabel = label(const LabelConfig(width: 40, height: 30))
          .image(bmp, const ImageOptions(x: 10, y: 10, width: 80, height: 20));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 150,
                child: LabelPreview(label: bitmapLabel),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LabelPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
