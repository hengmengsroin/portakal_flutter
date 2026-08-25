import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'raster_fixture.dart';
import 'sha256.dart';

/// Representation of a runnable ESC/POS validation or diagnostic test case.
class EscPosValidationCase {
  final String id;
  final String title;
  final String description;
  final String? expectedPayload;
  final bool isDiagnostic;
  final bool requiresCutter;
  final Uint8List Function() generator;

  const EscPosValidationCase({
    required this.id,
    required this.title,
    required this.description,
    this.expectedPayload,
    this.isDiagnostic = false,
    this.requiresCutter = false,
    required this.generator,
  });

  /// Deterministic expected golden SHA-256 computed from [generator].
  String get goldenSha256 => calculateSha256(generator());
}

/// Registry of ESC/POS test cases and transport diagnostic probes.
class EscPosHardwareSuite {
  static final List<EscPosValidationCase> diagnosticCases = [
    // D00 — Pure ASCII Transport Probe
    EscPosValidationCase(
      id: 'D00',
      title: 'D00 — Pure ASCII Probe',
      description:
          'Raw ASCII "PORTAKAL TEST\\n\\n\\n". Zero ESC/POS control commands, no ESC @, no formatting, no cut.',
      expectedPayload: 'PORTAKAL TEST',
      isDiagnostic: true,
      generator: () => Uint8List.fromList([
        0x50, 0x4F, 0x52, 0x54, 0x41, 0x4B, 0x41, 0x4C, // PORTAKAL
        0x20, // space
        0x54, 0x45, 0x53, 0x54, // TEST
        0x0A, 0x0A, 0x0A, // \n\n\n
      ]),
    ),

    // D01 — Minimal ESC/POS Probe
    EscPosValidationCase(
      id: 'D01',
      title: 'D01 — Minimal ESC/POS',
      description:
          'ESC @ reset + ASCII "PORTAKAL TEST\\n\\n\\n". Minimal initialization, no formatting, no cut.',
      expectedPayload: 'PORTAKAL TEST',
      isDiagnostic: true,
      generator: () =>
          (EscPosPrinter(
                  encoding: const EscPosEncoding.cp437(sendTableSelect: false),
                )
                ..initialize()
                ..text('PORTAKAL TEST\n\n\n'))
              .toBytes(),
    ),

    // H01-NOCUT — Safe Physical Bring-up Variant
    EscPosValidationCase(
      id: 'H01-NOCUT',
      title: 'H01-NOCUT — ASCII Baseline',
      description:
          'Center title, bold text, left alignment, 3 line feeds. No cut command.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      isDiagnostic: true,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
                ..bold(true)
                ..text('PORTAKAL-HW | Case: H01 ESC/POS\n')
                ..bold(false)
                ..align(EscPosAlignment.left)
                ..text('PORTAKAL 123 ABC xyz\n')
                ..feedLines(3))
              .toBytes(),
    ),
  ];

  static final List<EscPosValidationCase> protocolCases = [
    // H01 — Canonical ASCII Baseline (Phase 4B Golden with Cut)
    EscPosValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline (Cut)',
      description:
          'Initialize, center title, bold text, left alignment, partial cut',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      requiresCutter: true,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
                ..bold(true)
                ..text('PORTAKAL-HW | Case: H01 ESC/POS\n')
                ..bold(false)
                ..align(EscPosAlignment.left)
                ..text('PORTAKAL 123 ABC xyz\n')
                ..cut(mode: EscPosCutMode.partial, feedLines: 3))
              .toBytes(),
    ),

    // H02-CP437 — Latin Encodings
    EscPosValidationCase(
      id: 'H02-CP437',
      title: 'H02 — CP437 Characters',
      description: 'Code Page 437 accented characters (Table 0)',
      expectedPayload: 'ä ö ü ß ± °',
      generator: () =>
          (EscPosPrinter(
                  encoding: const EscPosEncoding.cp437(
                    tableId: 0,
                    sendTableSelect: true,
                  ),
                )
                ..initialize()
                ..text('PORTAKAL-HW | Case: H02-CP437\nä ö ü ß ± °\n')
                ..feedLines(2))
              .toBytes(),
    ),

    // H05 — Font Sizing
    EscPosValidationCase(
      id: 'H05',
      title: 'H05 — Font Magnification',
      description: 'Text size multipliers 1x, 2x, 4x width/height',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..textSize(width: 1, height: 1)
                ..text('Size 1x Normal\n')
                ..textSize(width: 2, height: 2)
                ..text('Size 2x Medium\n')
                ..textSize(width: 4, height: 4)
                ..text('Size 4x Large\n')
                ..textSize(width: 1, height: 1)
                ..feedLines(2))
              .toBytes(),
    ),

    // H06 — 1D Barcode Code128
    EscPosValidationCase(
      id: 'H06',
      title: 'H06 — Code128 Barcode',
      description: '1D Barcode Code 128 symbology (60 dot height)',
      expectedPayload: 'PORTAKAL123456',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H06 Code128\n')
                ..barcode(
                  content: 'PORTAKAL123456',
                  type: EscPosBarcodeType.code128,
                  height: 60,
                )
                ..feedLines(2))
              .toBytes(),
    ),

    // H07 — 2D QR Code
    EscPosValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code Model 2 via standard GS ( k commands',
      expectedPayload: 'https://example.com/portakal-hw-test',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H07 QR Code\n')
                ..qrCode(
                  'https://example.com/portakal-hw-test',
                  model: EscPosQrModel.model2,
                  ecc: EscPosQrEcc.m,
                  size: 5,
                )
                ..feedLines(2))
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (64x64)
    EscPosValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap',
      description: 'Canonical 1-bit monochrome bitmap via GS v 0 binary raster',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H09 Raster GS v 0 (64x64)\n')
                ..rasterFromMonochrome(createCanonicalRaster64x64Bitmap())
                ..feedLines(2))
              .toBytes(),
    ),

    // H11 — Paper Cutter
    EscPosValidationCase(
      id: 'H11',
      title: 'H11 — Partial Paper Cut',
      description: 'Feeds 3 lines and triggers GS V partial cut',
      requiresCutter: true,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..text('End of receipt - Cutting below\n')
                ..cut(mode: EscPosCutMode.partial, feedLines: 3))
              .toBytes(),
    ),

    // H12 — Initialization Reset
    EscPosValidationCase(
      id: 'H12',
      title: 'H12 — Reset / Initialize',
      description: 'Emits ESC @ hardware reset command',
      generator: () => (EscPosPrinter()..initialize()).toBytes(),
    ),
  ];

  /// All cases combined (diagnostics first, then protocol suite).
  static List<EscPosValidationCase> get allCases => [
    ...diagnosticCases,
    ...protocolCases,
  ];
}
