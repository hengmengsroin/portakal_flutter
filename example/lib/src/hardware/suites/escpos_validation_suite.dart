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
  String get description => 'ESC/POS-compatible receipt command set';

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
      expectedSha256: null,
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
      expectedSha256: null,
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
      expectedSha256:
          '97194073570f7cf492fa6747209ff8a356ea8c857731776510d54a203f16ce61',
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
      expectedSha256:
          'a10d4f8a3aa5505f04af365a50794cba3be4f62d9b07c77c9678e9336eff4636',
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
      expectedSha256:
          'b8867c7ceb0b0c16bc9a28e2fd045d865f293baae59783e4b3fd743e5d533bb5',
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
      expectedSha256:
          'dfa1ca81b00bda2e0231d458be143b989f5bd2c9d4afaba77a468447990efb18',
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

    // H06 — 1D Barcode Code 128
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via GS k command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      expectedSha256:
          'f634469af3f69c0cbec1200c09ffee3d9f75390e749863415013507cd4180497',
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
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code symbology (Model 2 via GS ( k, ECC Level M).',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      expectedSha256:
          'a651cc1718742e0399712a7637ae8b10153df3b652950b1eced6da2a159c41dd',
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
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap',
      description: 'Canonical 1-bit monochrome raster matrix via GS v 0.',
      validationKind: ValidationKind.raster,
      expectedSha256:
          '6fb45d9b4522056327a13620982062c0a369d061751f886dfee5c9a577bbd644',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
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
      expectedSha256:
          '14a098f9a45db66d7e54f72f65fbf4cfab4e529dcc31fd05d03526a9e3480597',
      generator: () =>
          (EscPosPrinter()
                ..initialize()
                ..text('End of receipt - Cutting below\n')
                ..cut(mode: EscPosCutMode.partial, feedLines: 3))
              .toBytes(),
    ),

    // H12 — Reset / Initialize
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Reset (ESC @)',
      description: 'Sends ESC @ reset command to initialize printer.',
      validationKind: ValidationKind.initialize,
      expectedSha256:
          'd376274f1c5409dac9df4be8f6fa47ebb103059e0b9ee2f5b6292fd808da6c17',
      generator: () => (EscPosPrinter()..initialize()).toBytes(),
    ),
  ];
}
