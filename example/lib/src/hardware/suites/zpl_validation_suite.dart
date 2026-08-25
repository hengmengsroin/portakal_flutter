import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class ZplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.zpl;

  @override
  String get displayName => 'ZPL II';

  @override
  String get description => 'ZPL II-compatible label command set';

  @override
  String? get warning =>
      'ZPL II capability requires Zebra or compatible emulation mode.';

  @override
  String get capabilityProbeCaseId => 'D00-ZPL';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-ZPL — Minimal ZPL II Capability Probe
    HardwareValidationCase(
      id: 'D00-ZPL',
      title: 'D00-ZPL — Minimal ZPL Probe',
      description:
          '^XA + ^FO50,50 + ^A0N,30,30 + ^FDPORTAKAL ZPL TEST^FS + ^XZ',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL ZPL TEST',
      validationKind: ValidationKind.text,
      expectedSha256: null,
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

    // H01 — ASCII Baseline
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline',
      description: '^XA / ^XZ framing with ^FO50,50 and ^FD text fields.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      expectedSha256:
          'ec94deef4e48b5e3e7ca4ab1526cdf710729e8c4c6dc2d504d8728fb29ed9de4',
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
    HardwareValidationCase(
      id: 'H02-UTF8',
      title: 'H02-UTF8 — Multilingual (^CI28)',
      description: 'UTF-8 encoded multilingual text using ^CI28.',
      expectedPayload: 'Portakal UTF-8: é à ü ç € Привет ខ្មែរ',
      validationKind: ValidationKind.encoding,
      expectedSha256:
          '83aa2e239b328e44aa4465e1aee3c950f8e58e47da148df795fbb312eeeb8af8',
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
    HardwareValidationCase(
      id: 'H05',
      title: 'H05 — Font Sizing (^A0)',
      description: 'Font height & width scaling (24x24, 48x48, 72x72).',
      validationKind: ValidationKind.text,
      expectedSha256:
          'e8f3eeacca78ea9c83d4a177fa6f0da1346f4bc8a0411e5e533296ec86cd1b19',
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
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 (^BC)',
      description: '1D Barcode Code 128 symbology via ^BC command.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      expectedSha256:
          '1732f726096200e83eed885fc844cb6a675a7840209b22244904979d61c1dba6',
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
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code (^BQ)',
      description: '2D QR Code symbology via ^BQ Model 2 command.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      expectedSha256:
          '183d29dbcc99c8a25a947d83a296b3ddffcc9218db5084fda97666ca8132a53b',
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
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (^GB Graphic Box)',
      description: 'Graphic Box and Line primitives via ^GB.',
      validationKind: ValidationKind.drawing,
      expectedSha256:
          '7a0c1b69ebe0784135c23e360e83c93502955019181175149ca8935f6ea20e39',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..endFormat())
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (^GFA)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 64x64 Raster Bitmap (^GFA)',
      description: 'Canonical 1-bit monochrome bitmap via ^GFA ASCII Hex.',
      validationKind: ValidationKind.raster,
      expectedSha256:
          '1d85f7b29696196ad8aed0aa49df8088e31298312c2086e13ca85c28071c46df',
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
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (^PQ)',
      description: 'Emits ^PQ3 to request 3 identical label copies.',
      validationKind: ValidationKind.copies,
      expectedSha256:
          '2266e5d9808a78a98c3aecd12cc16979e8510dc5732e5cceb4927636d9cb299a',
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
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Label Framing (^XA / ^XZ)',
      description: 'Empty label format framing (^XA^XZ).',
      validationKind: ValidationKind.initialize,
      expectedSha256:
          '97e1147617acb45f052c53d8744aacc18790c273a68648cfcb551acadf935e7d',
      generator: () =>
          (ZplPrinter()
                ..startFormat()
                ..endFormat())
              .toBytes(),
    ),
  ];
}
