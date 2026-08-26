import 'package:flutter_test/flutter_test.dart';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'package:example/src/examples/example_case.dart';
import 'package:example/src/examples/example_catalog.dart';
import 'package:example/src/export/svg_export.dart';

void main() {
  group('Phase 12D — SVG Filename Sanitizer Tests', () {
    test('Converts standard titles and names to lowercase with underscores', () {
      expect(sanitizeSvgFilename('Customer Receipt'), equals('customer_receipt.svg'));
      expect(sanitizeSvgFilename('Kitchen Ticket'), equals('kitchen_ticket.svg'));
      expect(sanitizeSvgFilename('Shipping Label'), equals('shipping_label.svg'));
    });

    test('Sanitizes slashes, path separators, and special characters', () {
      expect(
        sanitizeSvgFilename('Medicine / Price Label'),
        equals('medicine_price_label.svg'),
      );
      expect(
        sanitizeSvgFilename(r'Category\Subcategory/Item: #123 (Special)'),
        equals('category_subcategory_item_123_special.svg'),
      );
      expect(
        sanitizeSvgFilename('Special & Unique #100 / Item!'),
        equals('special_unique_100_item.svg'),
      );
    });

    test('Collapses consecutive underscores and trims boundary underscores', () {
      expect(sanitizeSvgFilename('___Multiple___Underscores___'), equals('multiple_underscores.svg'));
      expect(sanitizeSvgFilename('  Spaces   and    Tabs   '), equals('spaces_and_tabs.svg'));
      expect(sanitizeSvgFilename('  Demo   Label  '), equals('demo_label.svg'));
    });

    test('Does not duplicate .svg extension if already present', () {
      expect(sanitizeSvgFilename('customer_receipt.svg'), equals('customer_receipt.svg'));
      expect(sanitizeSvgFilename('Medicine / Price Label.svg'), equals('medicine_price_label.svg'));
      expect(sanitizeSvgFilename('demo.svg.svg'), equals('demo.svg'));
    });

    test('Handles edge-case empty, slashes-only, unicode, or symbols-only input safely', () {
      expect(sanitizeSvgFilename(''), equals('label.svg'));
      expect(sanitizeSvgFilename('   '), equals('label.svg'));
      expect(sanitizeSvgFilename('///'), equals('label.svg'));
      expect(sanitizeSvgFilename(r'\\\'), equals('label.svg'));
      expect(sanitizeSvgFilename('!@#\$%^&*()'), equals('label.svg'));
      expect(sanitizeSvgFilename('Café ☕ / 100%'), equals('caf_100.svg'));
    });
  });

  group('Phase 12D — SVG Export Generation for All 20 Gallery Examples', () {
    test('Every gallery example exports valid, well-formed standalone SVG from canonical ResolvedLabel', () {
      for (final exampleCase in ExampleCatalog.allCases) {
        // Resolve exactly once
        final job = exampleCase.buildLabel().resolve();

        // Export from the same resolved job
        final export = SvgExport.fromCase(exampleCase, job);

        // Verify filename
        expect(export.filename, endsWith('.svg'), reason: '${exampleCase.id} must end with .svg');
        expect(export.filename, isNotEmpty);
        expect(export.filename, isNot(contains(' ')));

        // Verify SVG XML structure
        final svg = export.content;
        expect(svg, startsWith('<svg'), reason: '${exampleCase.id} SVG must start with <svg');
        expect(svg, endsWith('</svg>'), reason: '${exampleCase.id} SVG must end with </svg>');
        expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
        expect(svg, contains('viewBox="0 0 '));

        // Verify dimension annotations
        expect(svg, contains('${job.widthDots}×${job.heightDots} dots (${job.dpi} DPI)'));
      }
    });

    test('Representative sequential example (customer_receipt) contains expected items and text', () {
      final receiptCase = ExampleCatalog.getById('customer_receipt')!;
      final job = receiptCase.buildLabel().resolve();
      final export = SvgExport.fromCase(receiptCase, job);

      expect(export.filename, equals('customer_receipt.svg'));
      expect(export.content, contains('PORTAKAL CAFE'));
      expect(export.content, contains('TOTAL'));
      expect(export.content, contains('Iced Latte'));
      expect(export.content, contains('Thank you for dining with us!'));
    });

    test('Representative exact examples export successfully with their graphical elements', () {
      // Shipping label (mixed barcode, lines, boxes, text)
      final shipping = ExampleCatalog.getById('shipping_label')!;
      final shippingJob = shipping.buildLabel().resolve();
      final shippingExport = SvgExport.fromCase(shipping, shippingJob);

      expect(shippingExport.filename, equals('shipping_label.svg'));
      expect(shippingExport.content, contains('PORTAKAL EXPRESS'));
      expect(shippingExport.content, contains('PKL202608250001'));
      expect(shippingExport.content, contains('<svg'));
      expect(shippingExport.content, contains('</svg>'));

      // Invoice example (tables, headers, barcode, QR)
      final invoice = ExampleCatalog.getById('invoice')!;
      final invoiceJob = invoice.buildLabel().resolve();
      final invoiceExport = SvgExport.fromCase(invoice, invoiceJob);

      expect(invoiceExport.filename, equals('invoice.svg'));
      expect(invoiceExport.content, contains('INVOICE'));
      expect(invoiceExport.content, contains('INV-2026-001'));
    });

    test('Barcode and QR examples render real vector elements in SVG', () {
      // Asset tag with 2D DataMatrix/QR & 1D barcode
      final assetTag = ExampleCatalog.getById('asset_tag')!;
      final assetJob = assetTag.buildLabel().resolve();
      final assetExport = SvgExport.fromCase(assetTag, assetJob);

      expect(assetExport.filename, equals('asset_tag.svg'));
      expect(assetExport.content, contains('<rect')); // Barcode bars and boxes
      expect(assetExport.content, contains('IT-000184'));
    });
  });

  group('Phase 12D — Same ResolvedLabel Contract & Protocol Independence', () {
    test('Exported SVG uses the exact same ResolvedLabel and does not mutate it', () {
      final example = ExampleCatalog.getById('retail_price_label')!;
      final job = example.buildLabel().resolve();

      // Take a baseline SVG directly from job
      final directSvg = renderPreview(job);

      // Export via helper
      final export = SvgExport.fromCase(example, job);

      // Verify exact equivalence
      expect(export.content, equals(directSvg));

      // Verify job properties remain intact
      expect(job.widthDots, equals(320));
      expect(job.heightDots, equals(240));
    });

    test('Logical SVG output is strictly independent of target printer protocol compilation', () {
      final example = ExampleCatalog.getById('retail_price_label')!;
      final job = example.buildLabel().resolve();

      final baselineSvg = renderPreview(job);

      // Compile to TSC
      final tscBytes = compileExample(ExampleProtocol.tsc, job);
      expect(tscBytes, isNotEmpty);
      expect(renderPreview(job), equals(baselineSvg));

      // Compile to ZPL
      final zplBytes = compileExample(ExampleProtocol.zpl, job);
      expect(zplBytes, isNotEmpty);
      expect(renderPreview(job), equals(baselineSvg));

      // Compile to EPL
      final eplBytes = compileExample(ExampleProtocol.epl, job);
      expect(eplBytes, isNotEmpty);
      expect(renderPreview(job), equals(baselineSvg));

      // SvgExport is identical
      final export = SvgExport.fromCase(example, job);
      expect(export.content, equals(baselineSvg));
    });
  });

  group('Phase 12D — File Saver Execution & Testability', () {
    test('Dispatches save to custom/injected saver without OS/browser interaction', () async {
      final example = ExampleCatalog.getById('kitchen_ticket')!;
      final job = example.buildLabel().resolve();
      final export = SvgExport.fromCase(example, job);

      String? capturedFilename;
      String? capturedContent;

      final result = await export.save(
        customSaver: (filename, content) async {
          capturedFilename = filename;
          capturedContent = content;
          return SvgDownloadResult.success(
            filename: filename,
            savedLocation: '/mock/path/$filename',
          );
        },
      );

      expect(result.isSuccess, isTrue);
      expect(result.filename, equals('kitchen_ticket.svg'));
      expect(result.savedLocation, equals('/mock/path/kitchen_ticket.svg'));
      expect(capturedFilename, equals('kitchen_ticket.svg'));
      expect(capturedContent, equals(export.content));
      expect(capturedContent, contains('<svg'));
    });

    test('Handles user cancellation gracefully with cancelled result', () async {
      final example = ExampleCatalog.getById('queue_ticket')!;
      final job = example.buildLabel().resolve();
      final export = SvgExport.fromCase(example, job);

      final result = await export.save(
        customSaver: (filename, content) async {
          return SvgDownloadResult.cancelled(
            filename: 'queue_ticket.svg',
          );
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Handles saver failure gracefully with failure result', () async {
      final example = ExampleCatalog.getById('queue_ticket')!;
      final job = example.buildLabel().resolve();
      final export = SvgExport.fromCase(example, job);

      final result = await export.save(
        customSaver: (filename, content) async {
          return const SvgDownloadResult.failure(
            filename: 'queue_ticket.svg',
            errorMessage: 'Disk full or permission denied',
          );
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.errorMessage, equals('Disk full or permission denied'));
    });
  });
}
