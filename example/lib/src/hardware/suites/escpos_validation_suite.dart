import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class EscPosValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.escpos;

  @override
  String get displayName => 'ESC/POS';

  @override
  String get description => 'Epson ESC/POS standard thermal receipt protocol';

  @override
  String? get warning => null;

  @override
  String get capabilityProbeCaseId => 'D00';

  @override
  List<HardwareValidationCase> get cases => [
    // D00 — Pure ASCII Transport Probe
    HardwareValidationCase(
      id: 'D00',
      title: 'D00 — Pure ASCII Probe',
      description:
          'Raw ASCII string without any ESC/POS commands. Verifies byte transmission.',
      isDiagnostic: true,
      validationKind: ValidationKind.text,
      generator: () => Uint8List.fromList([
        0x50, 0x4F, 0x52, 0x54, 0x41, 0x4B, 0x41, 0x4C, // PORTAKAL
        0x20, // space
        0x54, 0x45, 0x53, 0x54, // TEST
        0x0A, 0x0A, 0x0A, // \n\n\n
      ]),
    ),

    // D01 — Minimal ESC/POS Probe
    HardwareValidationCase(
      id: 'D01',
      title: 'D01 — Minimal ESC/POS Probe',
      description:
          'ESC @ reset + ASCII "PORTAKAL TEST\\n\\n\\n". Minimal initialization, no cut.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL TEST',
      validationKind: ValidationKind.text,
      generator: () =>
          (EscPosPrinter(
                  encoding: const EscPosEncoding.cp437(sendTableSelect: false),
                )
                ..initialize()
                ..text('PORTAKAL TEST\n\n\n'))
              .toBytes(),
    ),

    // H01-NOCUT — Safe ASCII Formatting (No Cut)
    HardwareValidationCase(
      id: 'H01-NOCUT',
      title: 'H01-NOCUT — ASCII (No Cut)',
      description:
          'Formatted ASCII layout (Center, Bold, Left, 3 Feeds) without cutter actuation.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
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

    // H01 — ASCII Baseline (With Cut)
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline (With Cut)',
      description:
          'ASCII Text formatting (Bold, Underline, Center) with partial cut.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      requiresCutter: true,
      validationKind: ValidationKind.text,
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

    // H02-CP437 — Latin Accented Characters
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin (Table 0)',
      description: 'CP437 European accented characters (ä, ö, ü, ß, ±, °).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
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

    // H05 — Font Magnification Scaling
    HardwareValidationCase(
      id: 'H05',
      title: 'H05 — Font Scaling',
      description:
          'Character width and height multipliers (1x Normal, 2x Medium, 4x Large).',
      validationKind: ValidationKind.text,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..textSize(width: 1, height: 1)
                ..text('Scale 1x Normal\n')
                ..textSize(width: 2, height: 2)
                ..text('Scale 2x Medium\n')
                ..textSize(width: 4, height: 4)
                ..text('Scale 4x Large\n')
                ..textSize(width: 1, height: 1)
                ..feedLines(2))
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via GS k command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
                ..barcode(
                  content: 'PORTAKAL123456',
                  type: EscPosBarcodeType.code128,
                  height: 80,
                  hri: EscPosBarcodeHri.below,
                )
                ..feedLines(2))
              .toBytes(),
    ),

    // H07 — 2D QR Code
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code symbology (Model 2, ECC Level M).',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
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
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap',
      description: 'Canonical 1-bit monochrome raster matrix via GS v 0.',
      validationKind: ValidationKind.raster,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
                ..text('PORTAKAL-HW | Case: H09 Raster GS v 0 (64x64)\n')
                ..rasterFromMonochrome(createCanonicalRaster64x64Bitmap())
                ..feedLines(2))
              .toBytes(),
    ),

    // H11 — Paper Cutter Command
    HardwareValidationCase(
      id: 'H11',
      title: 'H11 — Partial Cut',
      description: 'Actuates paper cutter blade via GS V 1 0x03 after 3 feeds.',
      requiresCutter: true,
      validationKind: ValidationKind.cut,
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..align(EscPosAlignment.center)
                ..text('PORTAKAL CUT TEST\n')
                ..cut(mode: EscPosCutMode.partial, feedLines: 3))
              .toBytes(),
    ),

    // H12 — Reset / Initialize
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Reset (ESC @)',
      description: 'Sends ESC @ reset command to clear printer state.',
      validationKind: ValidationKind.initialize,
      generator: () => (EscPosPrinter()..initialize()).toBytes(),
    ),
  ];
}
