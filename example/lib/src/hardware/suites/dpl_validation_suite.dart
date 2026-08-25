import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';

class DplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.dpl;

  @override
  String get displayName => 'DPL';

  @override
  String get description => 'Datamax Programming Language protocol';

  @override
  String? get warning => 'DPL commands use native CR line endings.';

  @override
  String get capabilityProbeCaseId => 'D00-DPL';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-DPL — Minimal DPL Capability Probe
    HardwareValidationCase(
      id: 'D00-DPL',
      title: 'D00-DPL — Minimal DPL Probe',
      description: 'STX L + ASCII text + E label format framing.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL DPL TEST',
      validationKind: ValidationKind.text,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..text(x: 50, y: 50, text: 'PORTAKAL DPL TEST', font: '0')
                ..endLabel())
              .toBytes(),
    ),

    // H01 — ASCII Baseline
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: 'Header and body text with STX L / E framing.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: DPL | Case: H01',
                )
                ..text(x: 50, y: 120, text: 'PORTAKAL 123 ABC xyz', font: '0')
                ..endLabel())
              .toBytes(),
    ),

    // H02-CP437 — Code Page 437
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin Encodings',
      description: 'Code Page 437 European characters (ä, ö, ü, ß, ±, °).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      generator: () =>
          (DplPrinter(encoding: const DplEncoding.cp437())
                ..startLabel()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
                ..endLabel())
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128 (Record B)
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology (Record B).',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  x: 50,
                  y: 80,
                  type: DplBarcodeType.code128,
                  height: 60,
                  content: 'PORTAKAL123456',
                )
                ..endLabel())
              .toBytes(),
    ),

    // H07 — 2D QR Code (Record W1D)
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code (Record W1D)',
      description: '2D QR Code symbology via Record W1D.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  x: 50,
                  y: 80,
                  content: 'https://example.com/portakal-hw-test',
                  cellWidth: 5,
                )
                ..endLabel())
              .toBytes(),
    ),

    // H08 — Drawing Primitives (Record 9)
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (Record 9)',
      description: 'Graphic Box and Line primitives via Record 9.',
      validationKind: ValidationKind.drawing,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..endLabel())
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (Not Supported in SDK)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 1-Bit Raster Bitmap',
      description: 'Raster bitmap graphics.',
      isSupportedInSdk: false,
      unsupportedSdkReason:
          'Portakal current DPL builder does not support generic raster graphics.',
      validationKind: ValidationKind.raster,
      generator: () => Uint8List(0),
    ),

    // H10 — Multiple Copies
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (3 Labels)',
      description: 'Emits DPL copies configuration (3 copies).',
      validationKind: ValidationKind.copies,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..copies(3)
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
                ..endLabel())
              .toBytes(),
    ),

    // H12 — Format Start / End Framing
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Framing (STX L / E)',
      description: 'Empty label format framing.',
      validationKind: ValidationKind.initialize,
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..endLabel())
              .toBytes(),
    ),
  ];
}
