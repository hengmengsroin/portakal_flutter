import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:example/src/examples/example_catalog.dart';
import 'package:example/src/export/svg_export.dart';
import 'package:example/src/pages/example_detail_page.dart';
import 'package:example/src/pages/example_gallery_page.dart';
import 'package:example/src/transport/hardware_printer_transport.dart';

void main() {
  group('Example Gallery & Detail Widget Tests', () {
    testWidgets('Gallery page renders all category chips, search bar, and example cards', (
      WidgetTester tester,
    ) async {
      final mockTransport = MockHardwarePrinterTransport();
      await tester.pumpWidget(
        MaterialApp(
          home: ExampleGalleryPage(transport: mockTransport),
        ),
      );

      // Verify header & search bar
      expect(find.text('Portakal Example Gallery'), findsOneWidget);
      expect(find.byKey(const Key('gallery_search_field')), findsOneWidget);

      // Verify category filter chips
      expect(find.byKey(const Key('category_all')), findsOneWidget);
      expect(find.byKey(const Key('category_retail')), findsOneWidget);
      expect(find.byKey(const Key('category_pharmacy')), findsOneWidget);

      // Verify presence of example cards
      expect(find.text('Simple Text & Frame'), findsOneWidget);
      expect(find.text('Retail Product Price Label'), findsOneWidget);
    });

    testWidgets('Category filtering updates list dynamically', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExampleGalleryPage(),
        ),
      );

      // Tap on 'Retail' chip
      await tester.tap(find.byKey(const Key('category_retail')));
      await tester.pumpAndSettle();

      // Retail examples should be present
      expect(find.text('Retail Product Price Label'), findsOneWidget);
      expect(find.text('Promotion & Discount Tag'), findsOneWidget);

      // Other category examples should be filtered out
      expect(find.text('Simple Text & Frame'), findsNothing);
    });

    testWidgets('Search query filters examples by text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExampleGalleryPage(),
        ),
      );

      // Enter search query
      await tester.enterText(find.byKey(const Key('gallery_search_field')), 'Amoxicillin');
      await tester.pumpAndSettle();

      expect(find.text('Medicine Price & Batch Label'), findsOneWidget);
      expect(find.text('Simple Text & Frame'), findsNothing);
    });

    testWidgets('Detail page renders preview, protocol selector, and compiles raw bytes', (
      WidgetTester tester,
    ) async {
      final example = ExampleCatalog.getById('simple_text')!;
      final mockTransport = MockHardwarePrinterTransport();

      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example,
            transport: mockTransport,
          ),
        ),
      );

      // Verify title and metadata
      expect(find.text('Simple Text & Frame'), findsOneWidget);
      expect(find.text('Visual Label Preview'), findsOneWidget);

      // Ensure visible and verify raw byte output
      final rawByteFinder = find.text('Raw Byte Output');
      await tester.ensureVisible(rawByteFinder);
      await tester.pumpAndSettle();
      expect(rawByteFinder, findsOneWidget);
      expect(find.text('Copy Hex'), findsOneWidget);

      // Ensure print button is visible and tap it
      final printButton = find.byKey(const Key('print_to_hardware_button'));
      await tester.ensureVisible(printButton);
      await tester.pumpAndSettle();
      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully sent'), findsOneWidget);
    });

    testWidgets('Detail page displays honest error banner on unsupported protocol features', (
      WidgetTester tester,
    ) async {
      // simple_text has boxes & lines which ESC/POS does not support in compileResolved
      final example = ExampleCatalog.getById('simple_text')!;

      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example,
          ),
        ),
      );

      // Scroll to dropdown and change protocol to ESC/POS
      final dropdownFinder = find.byKey(const Key('protocol_dropdown'));
      await tester.ensureVisible(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('ESC/POS').last);
      await tester.pumpAndSettle();

      // Error banner should be displayed with exact reason
      expect(find.text('Unsupported Protocol Feature'), findsOneWidget);
      expect(find.textContaining('ESC/POS receipt compiler does not support geometric'), findsOneWidget);
    });

    testWidgets('Detail page has exactly one Download SVG action and displays feedback', (
      WidgetTester tester,
    ) async {
      final example = ExampleCatalog.getById('simple_text')!;
      String? savedFile;
      String? savedData;

      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example,
            fileSaver: (filename, content) async {
              savedFile = filename;
              savedData = content;
              return SvgDownloadResult.success(
                filename: filename,
                savedLocation: '/Users/test/Downloads/$filename',
              );
            },
          ),
        ),
      );

      // Verify exactly ONE Download SVG button exists in the entire detail page
      expect(find.byKey(const Key('download_svg_button')), findsOneWidget);
      expect(find.byTooltip('Download SVG'), findsOneWidget);

      // Tap the single Download SVG button
      await tester.tap(find.byKey(const Key('download_svg_button')));
      await tester.pumpAndSettle();

      // Verify download callback was triggered with proper filename and SVG content
      expect(savedFile, equals('simple_text.svg'));
      expect(savedData, contains('<svg'));
      expect(savedData, contains('</svg>'));

      // Verify success SnackBar displays the saved destination path
      expect(find.text('Saved SVG to /Users/test/Downloads/simple_text.svg'), findsOneWidget);
    });

    testWidgets('Detail page Download SVG handles user cancellation without error', (
      WidgetTester tester,
    ) async {
      final example = ExampleCatalog.getById('simple_text')!;

      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example,
            fileSaver: (filename, content) async {
              return SvgDownloadResult.cancelled(filename: filename);
            },
          ),
        ),
      );

      // Tap the Download SVG button
      await tester.tap(find.byKey(const Key('download_svg_button')));
      await tester.pumpAndSettle();

      // Verify no error SnackBar is shown on cancellation
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Detail page Download SVG handles file saver failure with error SnackBar', (
      WidgetTester tester,
    ) async {
      final example = ExampleCatalog.getById('customer_receipt')!;

      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example,
            fileSaver: (filename, content) async {
              return const SvgDownloadResult.failure(
                filename: 'customer_receipt.svg',
                errorMessage: 'Permission denied',
              );
            },
          ),
        ),
      );

      // Tap Download SVG button
      await tester.tap(find.byKey(const Key('download_svg_button')));
      await tester.pumpAndSettle();

      // Verify error SnackBar
      expect(find.text('Failed to save SVG: Permission denied'), findsOneWidget);
    });

    testWidgets('Detail page didUpdateWidget refreshes ResolvedLabel when exampleCase changes on same state', (
      WidgetTester tester,
    ) async {
      final example1 = ExampleCatalog.getById('simple_text')!;
      final example2 = ExampleCatalog.getById('customer_receipt')!;
      String? exportedContent;

      // Pump initial example
      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example1,
            fileSaver: (filename, content) async {
              exportedContent = content;
              return SvgDownloadResult.success(filename: filename);
            },
          ),
        ),
      );

      expect(find.text('Simple Text & Frame'), findsOneWidget);

      // Update widget with new exampleCase on the same State instance
      await tester.pumpWidget(
        MaterialApp(
          home: ExampleDetailPage(
            exampleCase: example2,
            fileSaver: (filename, content) async {
              exportedContent = content;
              return SvgDownloadResult.success(filename: filename);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Dining Receipt'), findsOneWidget);

      // Trigger export on updated state
      await tester.tap(find.byKey(const Key('download_svg_button')));
      await tester.pumpAndSettle();

      // Verify exported SVG is for customer_receipt, NOT simple_text
      expect(exportedContent, contains('PORTAKAL CAFE'));
      expect(exportedContent, contains('TOTAL'));
    });

    testWidgets('App smoke launch with PortakalApp and PortakalHardwareApp', (
      WidgetTester tester,
    ) async {
      final mockTransport = MockHardwarePrinterTransport();
      await tester.pumpWidget(PortakalApp(transport: mockTransport));
      expect(find.text('Portakal Example Gallery'), findsOneWidget);

      await tester.pumpWidget(PortakalHardwareApp(transport: mockTransport));
      expect(find.text('Portakal Hardware Test Bench — ESC/POS'), findsOneWidget);
    });
  });
}
