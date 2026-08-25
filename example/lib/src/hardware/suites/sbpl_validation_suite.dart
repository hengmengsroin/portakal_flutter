import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';

class SbplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.sbpl;

  @override
  String get displayName => 'SBPL';

  @override
  String get description => 'SATO Barcode Printer Language protocol';

  @override
  String? get warning => 'Framed with ESC A and ESC Z job markers.';

  @override
  String get capabilityProbeCaseId => 'D00-SBPL';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-SBPL — Minimal SBPL Capability Probe
    HardwareValidationCase(
      id: 'D00-SBPL',
      title: 'D00-SBPL — Minimal SBPL Probe',
      description: 'ESC A + ESC V/H text placement + ESC Z framing.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL SBPL TEST',
      validationKind: ValidationKind.text,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL SBPL TEST',
                  font: SbplFont.xu,
                )
                ..endJob())
              .toBytes(),
    ),

    // H01 — ASCII Baseline
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: 'Header and body text with ESC V / ESC H commands.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: SBPL | Case: H01',
                  font: SbplFont.xu,
                )
                ..text(
                  x: 50,
                  y: 120,
                  text: 'PORTAKAL 123 ABC xyz',
                  font: SbplFont.xu,
                )
                ..endJob())
              .toBytes(),
    ),

    // H02-CP437 — Code Page 437
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin Encodings',
      description: 'Code Page 437 Latin characters (ä, ö, ü, ß, ±, °).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      generator: () =>
          (SbplPrinter(encoding: const SbplEncoding.cp437())
                ..startJob()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
                ..endJob())
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128 (ESC B)
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via ESC B command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  x: 50,
                  y: 80,
                  type: SbplBarcodeType.code128,
                  height: 60,
                  content: 'PORTAKAL123456',
                )
                ..endJob())
              .toBytes(),
    ),

    // H07 — 2D QR Code (ESC 2D30)
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code (ESC 2D30)',
      description: '2D QR Code symbology via ESC 2D30 command.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  x: 50,
                  y: 80,
                  content: 'https://example.com/portakal-hw-test',
                  cellWidth: 5,
                )
                ..endJob())
              .toBytes(),
    ),

    // H08 — Drawing Primitives (ESC FW)
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (ESC FW)',
      description: 'Graphic Box and Line primitives via ESC FW.',
      validationKind: ValidationKind.drawing,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..endJob())
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (Not Supported in SDK)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 1-Bit Raster Bitmap',
      description: 'Raster bitmap graphics.',
      isSupportedInSdk: false,
      unsupportedSdkReason:
          'Portakal current SBPL builder does not support generic raster graphics.',
      validationKind: ValidationKind.raster,
      generator: () => Uint8List(0),
    ),

    // H10 — Multiple Copies via ESC Q
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (ESC Q3)',
      description: 'Sets copies count to 3 via ESC Q.',
      validationKind: ValidationKind.copies,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..copies(3)
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H10 Batch 3 Copies',
                )
                ..endJob())
              .toBytes(),
    ),

    // H12 — Job Start (ESC A) and End (ESC Z)
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Job Framing (ESC A / Z)',
      description: 'Empty job framing.',
      validationKind: ValidationKind.initialize,
      generator: () =>
          (SbplPrinter()
                ..startJob()
                ..endJob())
              .toBytes(),
    ),
  ];
}
