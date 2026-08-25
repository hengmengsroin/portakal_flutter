import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';

class DplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.dpl;

  @override
  String get displayName => 'DPL';

  @override
  String get description =>
      'DPL-compatible command set (native CR line endings)';

  @override
  String? get warning => 'DPL commands use native CR (0x0D) line endings.';

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
      expectedSha256: null,
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
      expectedSha256:
          '3b28a6560a0a5ed495825d6fa7f60129f65bdf491a451dda0dec7f2e03acbd27',
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
      expectedSha256:
          'b4577781b52ef75c78c974fa1fb3ed18c7472bf0edb202a6dfb2e742a3d27da8',
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
      expectedSha256:
          'e186697b556ea044ee620fdf78c03918880c5467bf460c91b493739306f62ef3',
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
      expectedSha256:
          'ec248763a267b9f20c9f740a43772f9d1d05087641d55edbc7b6eb73e35e8b4f',
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
      expectedSha256:
          '7781c082633f09426609ea0a4009662bae5b5dad5f3a2fad7fc394ac68cdb46d',
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
      expectedSha256: null,
      generator: () => Uint8List(0),
    ),

    // H10 — Multiple Copies
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (3 Labels)',
      description: 'Emits DPL copies configuration (3 copies).',
      validationKind: ValidationKind.copies,
      expectedSha256:
          'aa96a45b56c020b97c5b8b75afbd08b680ea6a0debb072cb035dee5d00b83d7c',
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
      expectedSha256:
          'f68d0d4693abd4609d1c5dd4ab9cdda1ff748042ce3499f5c2680f9e57e235b7',
      generator: () =>
          (DplPrinter()
                ..startLabel()
                ..endLabel())
              .toBytes(),
    ),
  ];
}
