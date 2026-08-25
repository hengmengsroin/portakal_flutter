import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'raster_fixture.dart';
import 'sha256.dart';

/// Representation of a runnable ZPL validation or diagnostic test case.
class ZplValidationCase {
  final String id;
  final String title;
  final String description;
  final String? expectedPayload;
  final bool isDiagnostic;
  final Uint8List Function() generator;

  const ZplValidationCase({
    required this.id,
    required this.title,
    required this.description,
    this.expectedPayload,
    this.isDiagnostic = false,
    required this.generator,
  });

  /// Deterministic expected golden SHA-256 computed from [generator].
  String get goldenSha256 => calculateSha256(generator());
}

/// Registry of ZPL test cases and transport diagnostic capability probes.
class ZplHardwareSuite {
  static final List<ZplValidationCase> diagnosticCases = [
    // D00-ZPL — Minimal ZPL II Capability Probe
    ZplValidationCase(
      id: 'D00-ZPL',
      title: 'D00-ZPL — Minimal ZPL Probe',
      description:
          '^XA + ^FO50,50 + ^A0N,30,30 + ^FDPORTAKAL ZPL TEST^FS + ^XZ',
      expectedPayload: 'PORTAKAL ZPL TEST',
      isDiagnostic: true,
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL ZPL TEST',
                  height: 30,
                  width: 30,
                )
                ..endFormat())
              .toBytes(),
    ),
  ];

  static final List<ZplValidationCase> protocolCases = [
    // H01 — ASCII Baseline
    ZplValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: '^XA / ^XZ framing with ^FO50,50 and ^FD text fields',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: ZPL | Case: H01 | SDK: 0.3.0',
                )
                ..text(x: 50, y: 120, text: 'PORTAKAL 123 ABC xyz')
                ..endFormat())
              .toBytes(),
    ),

    // H02-UTF8 — Multilingual UTF-8 with ^CI28
    ZplValidationCase(
      id: 'H02-UTF8',
      title: 'H02-UTF8 — Multilingual (^CI28)',
      description: 'UTF-8 encoded multilingual text using ^CI28',
      expectedPayload: 'Portakal UTF-8: é à ü ç € Привет ខ្មែរ',
      generator: () =>
          (ZplPrinter(encoding: const ZplEncoding.utf8(emitCiCommand: true))
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H02-UTF8 (^CI28)',
                )
                ..text(
                  x: 50,
                  y: 120,
                  text: 'Portakal UTF-8: é à ü ç € Привет ខ្មែរ',
                )
                ..endFormat())
              .toBytes(),
    ),

    // H05 — Font Sizing with ^A0
    ZplValidationCase(
      id: 'H05',
      title: 'H05 — Font Sizing (^A0)',
      description: 'Font height & width scaling (24x24, 48x48, 72x72)',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'Size 24x24 Normal',
                  height: 24,
                  width: 24,
                )
                ..text(
                  x: 50,
                  y: 120,
                  text: 'Size 48x48 Medium',
                  height: 48,
                  width: 48,
                )
                ..text(
                  x: 50,
                  y: 220,
                  text: 'Size 72x72 Large',
                  height: 72,
                  width: 72,
                )
                ..endFormat())
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128 (^BC)
    ZplValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 (^BC)',
      description: '1D Barcode Code 128 symbology via ^BC command',
      expectedPayload: 'PORTAKAL123456',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H06 ZPL ^BC Code128',
                )
                ..barcode(
                  x: 50,
                  y: 100,
                  content: 'PORTAKAL123456',
                  type: ZplBarcodeType.code128,
                  height: 80,
                  interpretationLine: true,
                )
                ..endFormat())
              .toBytes(),
    ),

    // H07 — 2D QR Code (^BQ)
    ZplValidationCase(
      id: 'H07',
      title: 'H07 — QR Code (^BQ)',
      description: '2D QR Code symbology via ^BQ Model 2 command',
      expectedPayload: 'https://example.com/portakal-hw-test',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H07 ZPL ^BQ')
                ..qrCode(
                  x: 50,
                  y: 100,
                  content: 'https://example.com/portakal-hw-test',
                  magnification: 5,
                  ecc: ZplQrEcc.m,
                )
                ..endFormat())
              .toBytes(),
    ),

    // H08 — Drawing Primitives (^GB)
    ZplValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (^GB Graphic Box)',
      description: 'Graphic Box and Line primitives via ^GB',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..endFormat())
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (^GFA)
    ZplValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap (^GFA)',
      description: 'Canonical 1-bit monochrome bitmap via ^GFA ASCII Hex',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H09 ZPL ^GFA (64x64)',
                )
                ..graphicFieldFromMonochrome(
                  createCanonicalRaster64x64Bitmap(),
                  x: 50,
                  y: 100,
                )
                ..endFormat())
              .toBytes(),
    ),

    // H10 — Multiple Copies via ^PQ
    ZplValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (^PQ)',
      description: 'Emits ^PQ3 to request 3 identical label copies in one job',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..printQuantity(copies: 3)
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H10 Batch 3 Copies (^PQ)',
                )
                ..endFormat())
              .toBytes(),
    ),

    // H12 — Label Framing (^XA / ^XZ)
    ZplValidationCase(
      id: 'H12',
      title: 'H12 — Label Framing (^XA / ^XZ)',
      description: 'Empty label format framing (^XA^XZ)',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..endFormat())
              .toBytes(),
    ),
  ];

  /// All cases combined (diagnostics first, then protocol suite).
  static List<ZplValidationCase> get allCases => [
    ...diagnosticCases,
    ...protocolCases,
  ];
}
