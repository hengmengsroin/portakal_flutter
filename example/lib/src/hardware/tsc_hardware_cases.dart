import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import 'raster_fixture.dart';
import 'sha256.dart';

/// Representation of a runnable TSC validation or diagnostic test case.
class TscValidationCase {
  final String id;
  final String title;
  final String description;
  final String? expectedPayload;
  final bool isDiagnostic;
  final Uint8List Function() generator;

  const TscValidationCase({
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

/// Registry of TSC test cases and transport diagnostic probes.
class TscHardwareSuite {
  static final List<TscValidationCase> diagnosticCases = [
    // D00-TSC — Pure TSC Minimal Diagnostic Probe
    TscValidationCase(
      id: 'D00-TSC',
      title: 'D00-TSC — Minimal TSC Probe',
      description:
          'SIZE 800,600 dots + CLS + "PORTAKAL TSC TEST" text + PRINT 1.',
      expectedPayload: 'PORTAKAL TSC TEST',
      isDiagnostic: true,
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL TSC TEST',
                  font: TscResidentFont.font3,
                )
                ..print(copies: 1))
              .toBytes(),
    ),
  ];

  static final List<TscValidationCase> protocolCases = [
    // H01 — ASCII Baseline
    TscValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: 'SIZE 800,600, CLS, scalable header, 2x body text, PRINT 1',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(
                  x: 50,
                  y: 50,
                  text:
                      'PORTAKAL-HW | Proto: TSC | Case: H01 | SDK: 0.3.0 | Run: 001',
                  font: TscResidentFont.scalable,
                  xMultiplication: 1,
                  yMultiplication: 1,
                )
                ..text(
                  x: 50,
                  y: 120,
                  text: 'PORTAKAL 123 ABC xyz',
                  font: TscResidentFont.scalable,
                  xMultiplication: 2,
                  yMultiplication: 2,
                )
                ..print(copies: 1))
              .toBytes(),
    ),

    // H02-CP437 — Latin Encodings
    TscValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin Encodings',
      description: 'Code Page 437 Latin characters (CODEPAGE 437)',
      expectedPayload: 'ä ö ü ß ± °',
      generator: () =>
          (TscPrinter(
                  encoding: const TscEncoding.cp437(sendCodePageCommand: true),
                )
                ..sizeDots(800, 600)
                ..cls()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
                ..print(copies: 1))
              .toBytes(),
    ),

    // H02-CP850 — Multilingual Latin-1
    TscValidationCase(
      id: 'H02-CP850',
      title: 'H02-CP850 — Latin-1',
      description: 'Code Page 850 Multilingual Latin-1',
      expectedPayload: 'é à è ù ç ñ Á Í Ó',
      generator: () =>
          (TscPrinter(
                  encoding: const TscEncoding.cp850(sendCodePageCommand: true),
                )
                ..sizeDots(800, 600)
                ..cls()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP850')
                ..text(x: 50, y: 120, text: 'é à è ù ç ñ Á Í Ó')
                ..print(copies: 1))
              .toBytes(),
    ),

    // H02-CP1252 — Windows Western European
    TscValidationCase(
      id: 'H02-CP1252',
      title: 'H02-CP1252 — Windows 1252',
      description: 'Windows-1252 Western European symbols',
      expectedPayload: 'é à è “ ” ‘ ’ © ®',
      generator: () =>
          (TscPrinter(
                  encoding: const TscEncoding.cp1252(sendCodePageCommand: true),
                )
                ..sizeDots(800, 600)
                ..cls()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP1252')
                ..text(x: 50, y: 120, text: 'é à è “ ” ‘ ’ © ®')
                ..print(copies: 1))
              .toBytes(),
    ),

    // H05 — Font Magnification Scaling
    TscValidationCase(
      id: 'H05',
      title: 'H05 — Font Scaling',
      description: 'Font magnification multipliers 1x, 2x, 4x width/height',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'Scale 1x Normal',
                  font: TscResidentFont.font3,
                  xMultiplication: 1,
                  yMultiplication: 1,
                )
                ..text(
                  x: 50,
                  y: 120,
                  text: 'Scale 2x Medium',
                  font: TscResidentFont.font3,
                  xMultiplication: 2,
                  yMultiplication: 2,
                )
                ..text(
                  x: 50,
                  y: 220,
                  text: 'Scale 4x Large',
                  font: TscResidentFont.font3,
                  xMultiplication: 4,
                  yMultiplication: 4,
                )
                ..print(copies: 1))
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128
    TscValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via BARCODE command',
      expectedPayload: 'PORTAKAL123456',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  x: 50,
                  y: 80,
                  type: TscBarcodeType.code128,
                  height: 80,
                  content: 'PORTAKAL123456',
                  readable: TscBarcodeReadable.left,
                )
                ..print(copies: 1))
              .toBytes(),
    ),

    // H07 — 2D QR Code
    TscValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code symbology via QRCODE command',
      expectedPayload: 'https://example.com/portakal-hw-test',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  x: 50,
                  y: 80,
                  content: 'https://example.com/portakal-hw-test',
                  ecc: TscQrEcc.m,
                  cellWidth: 5,
                )
                ..print(copies: 1))
              .toBytes(),
    ),

    // H08 — Drawing Primitives
    TscValidationCase(
      id: 'H08',
      title: 'H08 — Drawing Primitives',
      description: 'Geometric primitives (BOX, BAR, CIRCLE)',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..box(x: 50, y: 50, xEnd: 250, yEnd: 150, thickness: 2)
                ..bar(x: 50, y: 180, width: 400, height: 4)
                ..circle(x: 350, y: 100, diameter: 80, thickness: 2)
                ..print(copies: 1))
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (64x64)
    TscValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap',
      description: 'Canonical 1-bit monochrome bitmap via BITMAP command',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 600)
                ..cls()
                ..text(
                  x: 50,
                  y: 30,
                  text: 'PORTAKAL-HW | Case: H09 Raster 64x64',
                )
                ..bitmapFromMonochrome(
                  createCanonicalRaster64x64Bitmap(),
                  x: 50,
                  y: 80,
                )
                ..print(copies: 1))
              .toBytes(),
    ),

    // H10 — Multiple Copies Batch
    TscValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (3 Labels)',
      description:
          'Emits PRINT 3, 1 to print 3 identical label copies in one job',
      generator: () =>
          (TscPrinter()
                ..sizeDots(800, 400)
                ..cls()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H10 Batch 3 Copies',
                )
                ..print(copies: 3))
              .toBytes(),
    ),

    // H12 — Initialization & CLS
    TscValidationCase(
      id: 'H12',
      title: 'H12 — CLS Buffer Clear',
      description: 'Emits CLS command to reset TSC image buffer',
      generator: () => (TscPrinter()..cls()).toBytes(),
    ),
  ];

  /// All cases combined (diagnostics first, then protocol suite).
  static List<TscValidationCase> get allCases => [
    ...diagnosticCases,
    ...protocolCases,
  ];
}
