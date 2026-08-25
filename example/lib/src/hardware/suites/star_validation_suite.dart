import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class StarValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.star;

  @override
  String get displayName => 'Star Line / PRNT';

  @override
  String get description => 'Star Line Mode / supported Star PRNT subset';

  @override
  String? get warning => 'Requires Star Line Mode command set support.';

  @override
  String get capabilityProbeCaseId => 'D00-STAR';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-STAR — Minimal Star Capability Probe
    HardwareValidationCase(
      id: 'D00-STAR',
      title: 'D00-STAR — Minimal Star Probe',
      description: 'ESC @ initialize + "PORTAKAL STAR TEST\\n\\n\\n".',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL STAR TEST',
      validationKind: ValidationKind.text,
      expectedSha256: null,
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..text('PORTAKAL STAR TEST\n\n\n'))
              .toBytes(),
    ),

    // H01 — ASCII Baseline (With Cut)
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description:
          'Center, Bold, Left text formatting with partial cut (ESC d 2).',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      requiresCutter: true,
      validationKind: ValidationKind.text,
      expectedSha256:
          'c6bdfb68e5d63cb595d834588d18f868eab6df1f77f41b00633064e5115501f2',
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..align(StarAlignment.center)
                ..bold(true)
                ..text('PORTAKAL-HW | Case: H01 Star PRNT\n')
                ..bold(false)
                ..align(StarAlignment.left)
                ..text('PORTAKAL 123 ABC xyz\n')
                ..feedLines(3)
                ..cut(StarCutMode.partial))
              .toBytes(),
    ),

    // H02-CP437 — Code Page 437
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin (Table 0)',
      description: 'Code Page 437 Latin characters (ä, ö, ü, ß, ±, °).',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          '2e2083b2b3086272cabe03905153339d03072fe61ff1ec2a963448e8895d2763',
      generator: () =>
          (StarPrntPrinter(
                  encoding: const StarPrntEncoding.cp437(
                    sendCodePageCommand: true,
                  ),
                )
                ..initialize()
                ..text('PORTAKAL-HW | Case: H02-CP437\nä ö ü ß ± °\n')
                ..feedLines(2))
              .toBytes(),
    ),

    // H02-CP850 — Multilingual Latin-1
    HardwareValidationCase(
      id: 'H02-CP850',
      title: 'H02-CP850 — Latin-1 (Table 1)',
      description: 'Code Page 850 Multilingual Latin-1.',
      expectedPayload: 'é à è ù ç ñ Á Í Ó',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          '39ae864987c9f035e635b41da1cd501d242c0094ebbcea710e917d2452b6f5f0',
      generator: () =>
          (StarPrntPrinter(
                  encoding: const StarPrntEncoding.cp850(
                    sendCodePageCommand: true,
                  ),
                )
                ..initialize()
                ..text('PORTAKAL-HW | Case: H02-CP850\né à è ù ç ñ Á Í Ó\n')
                ..feedLines(2))
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128 (ESC GS b)
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 Barcode',
      description: '1D Barcode Code 128 symbology via ESC GS b.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      expectedSha256:
          '55d5925b2e047d0fb07347e7a880150fc9fb5cef2a70a3bd7b5c7d5a9fd6e0ec',
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H06 Code128\n')
                ..barcode(
                  'PORTAKAL123456',
                  type: StarBarcodeType.code128,
                  height: 60,
                )
                ..feedLines(2))
              .toBytes(),
    ),

    // H07 — 2D QR Code (ESC GS y S 0/1/2)
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code',
      description: '2D QR Code Model 2 symbology.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      expectedSha256:
          '6b67d3e76eabc4d1e28b54c908ffc20e233c1bf490cda6eb24c9a95af6d2e97f',
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H07 QR Code\n')
                ..qrCode(
                  'https://example.com/portakal-hw-test',
                  model: StarQrModel.model2,
                  ecc: StarQrEcc.m,
                  cellWidth: 5,
                )
                ..feedLines(2))
              .toBytes(),
    ),

    // H09 — Star Line Mode Raster (ESC * r A ... b nL nH ... ESC * r B)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster (ESC * r A)',
      description: 'Canonical 1-bit monochrome raster matrix.',
      validationKind: ValidationKind.raster,
      expectedSha256:
          'c0afd3d9b40eebf4249109be888c4e478db6821b8336089b9f5d2b1f6dae3f42',
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..text('PORTAKAL-HW | Case: H09 Star Raster (64x64)\n')
                ..rasterFromMonochrome(createCanonicalRaster64x64Bitmap())
                ..feedLines(2))
              .toBytes(),
    ),

    // H11 — Paper Cut (ESC d 2)
    HardwareValidationCase(
      id: 'H11',
      title: 'H11 — Partial Cut',
      description: 'Partial paper cut via ESC d 2.',
      requiresCutter: true,
      validationKind: ValidationKind.cut,
      expectedSha256:
          '6a7a49d56aaecebc5b9b34fd10a628a04172d860d886f6336e710137588b7d82',
      generator: () =>
          (StarPrntPrinter()
                ..initialize()
                ..text('End of receipt - Cutting below\n')
                ..feedLines(3)
                ..cut(StarCutMode.partial))
              .toBytes(),
    ),

    // H12 — Printer Initialize (ESC @)
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Initialize (ESC @)',
      description: 'Emits ESC @ to initialize printer.',
      validationKind: ValidationKind.initialize,
      expectedSha256:
          '722ca241c5a697ee3602ba79c89c4ea77a64fc4ddbea7fce2bef00d8eb23034d',
      generator: () => (StarPrntPrinter()..initialize()).toBytes(),
    ),
  ];
}
