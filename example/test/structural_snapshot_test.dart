import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'package:example/src/examples/example_catalog.dart';
import 'package:example/src/examples/general/invoice_example.dart';
import 'package:example/src/examples/logistics/shipping_label.dart';
import 'package:example/src/examples/pharmacy/medicine_price_label.dart';
import 'package:example/src/examples/restaurant/customer_receipt.dart';
import 'package:example/src/examples/restaurant/kitchen_ticket.dart';
import 'package:example/src/examples/retail/retail_price_label.dart';
import 'package:example/src/examples/warehouse/location_bin_label.dart';

void main() {
  group('Structural PreviewScene Assertions for All 19 Use Cases', () {
    test('All 19 examples produce well-formed PreviewScene objects with expected element types', () {
      for (final c in ExampleCatalog.allCases) {
        final job = c.buildLabel().resolve();
        final scene = PreviewScene.fromResolved(job);

        expect(scene.items, isNotEmpty, reason: '${c.id} must have items in scene');
        expect(scene.widthDots, equals(job.widthDots));
        expect(scene.heightDots, equals(job.heightDots));

        // Ensure every scene contains at least one text element
        final hasText = scene.items.any((e) => e is PreviewTextItem);
        expect(
          hasText,
          isTrue,
          reason: '${c.id} should have at least one text item',
        );
      }
    });
  });

  group('Flagship Example Deep Structural Acceptance', () {
    test('1. Retail Price Label — Structural Acceptance', () {
      final job = buildRetailPriceLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final lineItems = scene.items.whereType<PreviewLineItem>().toList();
      final barcodeItems = scene.items.whereType<PreviewBarcodeItem>().toList();

      expect(textItems.any((t) => t.text.contains('PORTAKAL MART')), isTrue);
      expect(textItems.any((t) => t.text.contains('\$3.50')), isTrue);
      expect(textItems.any((t) => t.text.contains('MILK-001')), isTrue);
      expect(lineItems.length, greaterThanOrEqualTo(2));
      expect(barcodeItems.length, equals(1));
      expect(barcodeItems.first.payload, equals('1234567890128'));
    });

    test('2. Medicine Price Label — Structural Acceptance', () {
      final job = buildMedicinePriceLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final barcodeItems = scene.items.whereType<PreviewBarcodeItem>().toList();

      expect(textItems.any((t) => t.text.contains('AMOXICILLIN 500mg')), isTrue);
      expect(textItems.any((t) => t.text.contains('Batch: AMX240801')), isTrue);
      expect(textItems.any((t) => t.text.contains('EXP: 08/2028')), isTrue);
      expect(textItems.any((t) => t.text.contains('\$4.50')), isTrue);
      expect(barcodeItems.length, equals(1));
      expect(barcodeItems.first.payload, equals('AMX240801'));
    });

    test('3. Kitchen Order Ticket — Structural Acceptance', () {
      final job = buildKitchenTicketLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final boxItems = scene.items.whereType<PreviewRectItem>().toList();
      final lineItems = scene.items.whereType<PreviewLineItem>().toList();

      expect(textItems.any((t) => t.text.contains('TABLE 12')), isTrue);
      expect(textItems.any((t) => t.text.contains('Order #A1024')), isTrue);
      expect(textItems.any((t) => t.text.contains('Beef Lok Lak')), isTrue);
      expect(textItems.any((t) => t.text.contains('PEANUT ALLERGY')), isTrue);
      expect(boxItems.length, greaterThanOrEqualTo(1));
      expect(lineItems.length, greaterThanOrEqualTo(2));
    });

    test('4. Warehouse Location Bin Label — Structural Acceptance', () {
      final job = buildLocationBinLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final barcodeItems = scene.items.whereType<PreviewBarcodeItem>().toList();

      expect(textItems.any((t) => t.text.contains('B12')), isTrue);
      expect(textItems.any((t) => t.text.contains('AISLE 03')), isTrue);
      expect(barcodeItems.length, equals(1));
      expect(barcodeItems.first.payload, equals('A-03-07-B12'));
    });

    test('5. Cross-Border Shipping Label — Structural Acceptance', () {
      final job = buildShippingLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final barcodeItems = scene.items.whereType<PreviewBarcodeItem>().toList();
      final qrItems = scene.items.whereType<PreviewQrItem>().toList();

      expect(textItems.any((t) => t.text.contains('PORTAKAL EXPRESS')), isTrue);
      expect(textItems.any((t) => t.text.contains('SOK DARA')), isTrue);
      expect(textItems.any((t) => t.text.contains('PKL202608250001')), isTrue);
      expect(barcodeItems.length, equals(1));
      expect(barcodeItems.first.payload, equals('PKL202608250001'));
      expect(qrItems.length, equals(1));
      expect(qrItems.first.payload, contains('PKL202608250001'));
    });

    test('6. Commercial Invoice — Structural Acceptance', () {
      final job = buildInvoiceLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final barcodeItems = scene.items.whereType<PreviewBarcodeItem>().toList();
      final qrItems = scene.items.whereType<PreviewQrItem>().toList();

      expect(textItems.any((t) => t.text.contains('INVOICE')), isTrue);
      expect(textItems.any((t) => t.text.contains('INV-2026-001')), isTrue);
      expect(textItems.any((t) => t.text.contains('\$181.50')), isTrue);
      expect(barcodeItems.length, equals(1));
      expect(barcodeItems.first.payload, equals('INV2026001'));
      expect(qrItems.length, equals(1));
      expect(qrItems.first.payload, contains('INV-2026-001'));
    });

    test('Customer Receipt & Continuous Preview Acceptance', () {
      final job = buildCustomerReceiptLabel().resolve();
      final scene = PreviewScene.fromResolved(job);

      expect(scene.widthDots, equals(job.widthDots));
      expect(scene.heightDots, equals(job.heightDots));

      final textItems = scene.items.whereType<PreviewTextItem>().toList();
      final qrItems = scene.items.whereType<PreviewQrItem>().toList();

      expect(textItems.any((t) => t.text.contains('PORTAKAL CAFE')), isTrue);
      expect(textItems.any((t) => t.text.contains('TOTAL')), isTrue);
      expect(textItems.any((t) => t.text.contains('\$6.05')), isTrue);
      expect(qrItems.length, equals(1));
    });
  });
}
