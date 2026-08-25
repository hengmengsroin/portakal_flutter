import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class CpclValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.cpcl;

  @override
  String get displayName => 'CPCL';

  @override
  String get description => 'Comtec / Zebra Mobile receipt & label protocol';

  @override
  String? get warning => null;

  @override
  String get capabilityProbeCaseId => 'D00-CPCL';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-CPCL — Minimal CPCL Capability Probe
    HardwareValidationCase(
      id: 'D00-CPCL',
      title: 'D00-CPCL — Minimal CPCL Probe',
      description: '! 0 200 200 300 1 + TEXT + FORM + PRINT session lifecycle.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL CPCL TEST',
      validationKind: ValidationKind.text,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 300)
                ..text(x: 50, y: 50, text: 'PORTAKAL CPCL TEST')
                ..form()
                ..print())
              .toBytes(),
    ),

    // H01 — ASCII Baseline
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: 'Header and body text with TEXT command.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 400)
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: CPCL | Case: H01',
                )
                ..text(x: 50, y: 100, text: 'PORTAKAL 123 ABC xyz', size: 1)
                ..form()
                ..print())
              .toBytes(),
    ),

    // H02-CP437 — Code Page 437
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin (COUNTRY USA)',
      description: 'Code Page 437 Latin characters (ä, ö, ü, ß, ±, °).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      generator: () =>
          (CpclPrinter(
                  encoding: const CpclEncoding.usa(sendCountryCommand: true),
                )
                ..startPage(heightDots: 400)
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 100, text: 'ä ö ü ß ± °')
                ..form()
                ..print())
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via BARCODE 128 command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 400)
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  x: 50,
                  y: 70,
                  type: CpclBarcodeType.code128,
                  height: 60,
                  content: 'PORTAKAL123456',
                )
                ..form()
                ..print())
              .toBytes(),
    ),

    // H07 — 2D QR Code
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code symbology via BARCODE QR command.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 400)
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  x: 50,
                  y: 70,
                  content: 'https://example.com/portakal-hw-test',
                  cellWidth: 5,
                )
                ..form()
                ..print())
              .toBytes(),
    ),

    // H08 — Drawing Primitives (BOX, LINE)
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (BOX & LINE)',
      description: 'Graphic Box and Line primitives.',
      validationKind: ValidationKind.drawing,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 400)
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..form()
                ..print())
              .toBytes(),
    ),

    // H09 — 1-Bit ASCII-Hex Graphic (EG)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Graphic (EG)',
      description: 'Expanded Graphic (EG) 1-bit monochrome raster matrix.',
      validationKind: ValidationKind.raster,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 400)
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H09 EG (64x64)')
                ..graphicFromMonochrome(
                  createCanonicalRaster64x64Bitmap(),
                  x: 50,
                  y: 70,
                )
                ..form()
                ..print())
              .toBytes(),
    ),

    // H10 — Multiple Copies via session header quantity
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (3 Labels)',
      description: 'Sets session copies parameter to 3.',
      validationKind: ValidationKind.copies,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 300, copies: 3)
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
                ..form()
                ..print())
              .toBytes(),
    ),

    // H12 — Session Start & Form Feed
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Form & Feed',
      description: 'Minimal session start and form feed.',
      validationKind: ValidationKind.initialize,
      generator: () =>
          (CpclPrinter()
                ..startPage(heightDots: 200)
                ..form()
                ..print())
              .toBytes(),
    ),
  ];
}
