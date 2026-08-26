import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Itemized tabular report template demonstrating multi-column table layout (80mm media).
LabelBuilder buildTableLayoutLabel() {
  final doc = sequentialLabel(const LabelConfig(width: 80, height: 90, copies: 1));

  doc
      // Report Header
      .row('INVENTORY AUDIT REPORT', 'PAGE 1/1', bold: true, size: 1)
      .row('Store #104 - Central Warehouse', 'Date: 2026-08-25')
      .divider();

  // Multi-column table with mixed fixed and flex columns and custom alignments
  final table = doc.table(
    columns: [
      LabelColumn.fixed(120),                                    // SKU column (fixed 120 dots)
      LabelColumn.flex(3),                                       // Description column (flex weight 3, left-aligned)
      LabelColumn.flex(1, align: LabelTextAlign.center),          // Qty column (flex weight 1, center-aligned)
      LabelColumn.flex(1, align: LabelTextAlign.right),           // Value column (flex weight 1, right-aligned)
    ],
    gap: 8,
  );

  table
    ..row(['SKU', 'Description', 'Qty', 'Total'], bold: true)
    ..divider(thickness: 2)
    ..row(['PKG-101', 'Direct Thermal Paper Roll', '24', r'$72.00'])
    ..row(['PKG-102', 'Wax/Resin Ribbon 110mm', '10', r'$50.00'])
    ..row(['PKG-103', 'Printhead Cleaner Kit', '5', r'$25.00'])
    ..row(['PKG-104', 'USB Barcode Scanner', '2', r'$70.00'])
    ..divider()
    ..row(['TOTAL', '4 Line Items Audited', '41', r'$217.00'], bold: true);

  doc
      .space(10)
      .divider()
      .row('Audit Status:', 'PASSED (100% MATCH)', bold: true)
      .row('Auditor:', 'ID #8821 (Ops Team)')
      .space(10);

  // Verification Barcode
  doc.barcode(
    'AUD-20260825-104',
    BarcodeOptions.typed(
      x: 30,
      y: 540,
      symbology: BarcodeSymbology.code128,
      height: 50,
      readable: 1,
    ),
  );

  return doc;
}

final tableLayoutCase = ExampleCase(
  id: 'table_layout',
  title: 'Structured Table & Column Layout',
  description:
      'Demonstrates multi-column table layout with mixed fixed/flex widths, left/center/right cell alignments, bold header rows, semantic dividers, and totals.',
  category: ExampleCategory.advanced,
  recommendedMedia: '80mm Continuous',
  sourcePath: 'lib/src/examples/general/table_layout_example.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
    ExampleProtocol.escpos,
    ExampleProtocol.starprnt,
  },
  buildLabel: buildTableLayoutLabel,
  quickSnippet: '''
final job = buildTableLayoutLabel().resolve();
final escposBytes = escpos.compileResolved(job);
final tscBytes = tsc.compileResolved(job);
''',
);
