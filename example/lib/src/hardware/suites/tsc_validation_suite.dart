import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class TscValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.tsc;

  @override
  String get displayName => 'TSC / TSPL2';

  @override
  String get description =>
      'TSC / TSPL2-compatible label and receipt command set';

  @override
  String? get warning => null;

  @override
  String get capabilityProbeCaseId => 'D00-TSC';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-TSC — Minimal TSPL2 Diagnostic Probe
    HardwareValidationCase(
      id: 'D00-TSC',
      title: 'D00-TSC — Minimal TSC Probe',
      description:
          'SIZE 800,600 dots + CLS + "PORTAKAL TSC TEST" text + PRINT 1.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL TSC TEST',
      validationKind: ValidationKind.text,
      expectedSha256: null,
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

    // H01 — ASCII Baseline
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: 'SIZE 800,600, CLS, scalable header, 2x body text, PRINT 1.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      expectedSha256:
          '8e064319f18a1d446fcfadd0131d20c8ab346f4244ceded5814ef1893629bc24',
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
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin Encodings',
      description: 'Code Page 437 Latin characters (CODEPAGE 437).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          '76334c9bb5822d6a169047bbac044c18ec11d57f1a18192aa1c13d009879c3d6',
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
    HardwareValidationCase(
      id: 'H02-CP850',
      title: 'H02-CP850 — Latin-1',
      description: 'Code Page 850 Multilingual Latin-1 (CODEPAGE 850).',
      expectedPayload: 'é à è ù ç ñ Á Í Ó',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          '3062a103dd7b447b4c4a4fe6f671ca9a28f1fbe1b538fb7cde136de3b490c793',
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
    HardwareValidationCase(
      id: 'H02-CP1252',
      title: 'H02-CP1252 — Windows 1252',
      description: 'Windows-1252 Western European symbols (CODEPAGE 1252).',
      expectedPayload: 'é à è “ ” ‘ ’ © ®',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          'faebd54a70fb02c6f5b2a8737557f360d45edd5ed954d0f8533404c330c97e28',
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
    HardwareValidationCase(
      id: 'H05',
      title: 'H05 — Font Scaling',
      description: 'Font multipliers 1x, 2x, 4x width/height.',
      validationKind: ValidationKind.text,
      expectedSha256:
          '50190d3f0aa7661d7bcdbc6538dca7df88cd8585835367c5cd9b4ca3cef98a4a',
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
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via BARCODE command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      expectedSha256:
          '37756c0da132344e3235fad9ae3b86fad1656c4c8ead1f28bae64ed7085e223e',
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
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code symbology via QRCODE command.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      expectedSha256:
          '2c395221311a4886698ab6c0cbdf53232c307446d119464e676c0e57ef34af1a',
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
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing Primitives',
      description: 'Geometric primitives (BOX, BAR, CIRCLE).',
      validationKind: ValidationKind.drawing,
      expectedSha256:
          'cc91a4fc925762ada9c2b7d3a7dae4e238033ec40fe7db6ca2afebc0cd3da756',
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
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap',
      description:
          'Canonical 1-bit monochrome bitmap via BITMAP binary stream.',
      validationKind: ValidationKind.raster,
      expectedSha256:
          '743515de16b76c24747fb9b86b84e9c917ac0f1d3f35fe465ffd487ab26a55dc',
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
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (3 Labels)',
      description: 'Emits PRINT 1, 3 to request 3 identical labels in one job.',
      validationKind: ValidationKind.copies,
      expectedSha256:
          '131475c43d27e3771500d51429d76dcecebf5f0e54e9c5a60e086589144cf3c8',
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
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — CLS Buffer Clear',
      description: 'Emits CLS command to reset TSC image buffer.',
      validationKind: ValidationKind.initialize,
      expectedSha256:
          'ca51cc9362eb8b34f911287ffc21e078c21f39b54bef2f59bf6ef59a6724d768',
      generator: () => (TscPrinter()..cls()).toBytes(),
    ),
  ];
}
