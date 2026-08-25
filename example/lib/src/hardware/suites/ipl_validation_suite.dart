import 'dart:typed_data';
import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';

class IplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.ipl;

  @override
  String get displayName => 'IPL';

  @override
  String get description =>
      'Intermec Printer Language protocol (F90-F99 formats)';

  @override
  String? get warning =>
      'Uses reserved validation formats F90-F99 to avoid clobbering production formats.';

  @override
  String get capabilityProbeCaseId => 'D00-IPL';

  @override
  List<HardwareValidationCase> get cases => [
    // D00-IPL — Minimal IPL Capability Probe (Format F90)
    HardwareValidationCase(
      id: 'D00-IPL',
      title: 'D00-IPL — Minimal IPL Probe',
      description:
          'Advanced Mode + Program Mode + F90 format lifecycle + Print.',
      isDiagnostic: true,
      expectedPayload: 'PORTAKAL IPL TEST',
      validationKind: ValidationKind.text,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(90)
                ..createFormat(90)
                ..text(x: 50, y: 50, text: 'PORTAKAL IPL TEST')
                ..exitProgramMode()
                ..selectFormat(90)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H01 — ASCII Baseline (Format F90)
    HardwareValidationCase(
      id: 'H01',
      title: 'H01 — ASCII Baseline (F90)',
      description: 'Header and body text with Format F90 lifecycle.',
      expectedPayload: 'PORTAKAL 123 ABC xyz',
      validationKind: ValidationKind.text,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(90)
                ..createFormat(90)
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: IPL | Case: H01',
                )
                ..text(x: 50, y: 120, text: 'PORTAKAL 123 ABC xyz')
                ..exitProgramMode()
                ..selectFormat(90)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H02-CP437 — Code Page 437 (Format F91)
    HardwareValidationCase(
      id: 'H02-CP437',
      title: 'H02-CP437 — Latin Encodings (F91)',
      description: 'Code Page 437 Latin characters on Format F91.',
      expectedPayload: 'ä ö ü ß ± °',
      validationKind: ValidationKind.encoding,
      generator: () =>
          (IplPrinter(encoding: const IplEncoding.cp437())
                ..advancedMode()
                ..programMode()
                ..eraseFormat(91)
                ..createFormat(91)
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
                ..exitProgramMode()
                ..selectFormat(91)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H06 — 1D Barcode Code 128 (Format F92)
    HardwareValidationCase(
      id: 'H06',
      title: 'H06 — Code 128 (F92)',
      description: '1D Barcode Code 128 on Format F92.',
      expectedPayload: 'PORTAKAL123456',
      requiresScanner: true,
      validationKind: ValidationKind.barcode,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(92)
                ..createFormat(92)
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  y: 80,
                  type: IplBarcodeType.code128,
                  height: 60,
                  content: 'PORTAKAL123456',
                )
                ..exitProgramMode()
                ..selectFormat(92)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H07 — 2D QR Code (Format F93)
    HardwareValidationCase(
      id: 'H07',
      title: 'H07 — QR Code (F93)',
      description: '2D QR Code symbology on Format F93.',
      expectedPayload: 'https://example.com/portakal-hw-test',
      requiresScanner: true,
      validationKind: ValidationKind.qr,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(93)
                ..createFormat(93)
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  y: 80,
                  content: 'https://example.com/portakal-hw-test',
                  cellWidth: 5,
                )
                ..exitProgramMode()
                ..selectFormat(93)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H08 — Drawing Primitives (Format F94)
    HardwareValidationCase(
      id: 'H08',
      title: 'H08 — Drawing (F94)',
      description: 'Graphic Box and Line primitives on Format F94.',
      validationKind: ValidationKind.drawing,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(94)
                ..createFormat(94)
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..exitProgramMode()
                ..selectFormat(94)
                ..batchCount(1)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H09 — 1-Bit Raster Bitmap (Not Supported in SDK)
    HardwareValidationCase(
      id: 'H09',
      title: 'H09 — 1-Bit Raster Bitmap',
      description: 'Raster bitmap graphics.',
      isSupportedInSdk: false,
      unsupportedSdkReason:
          'Portakal current IPL builder does not support generic raster graphics.',
      validationKind: ValidationKind.raster,
      generator: () => Uint8List(0),
    ),

    // H10 — Multiple Copies (Format F95)
    HardwareValidationCase(
      id: 'H10',
      title: 'H10 — Multiple Copies (F95)',
      description: 'Sets batch count to 3 labels on Format F95.',
      validationKind: ValidationKind.copies,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..programMode()
                ..eraseFormat(95)
                ..createFormat(95)
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Case: H10 Batch 3 Copies',
                )
                ..exitProgramMode()
                ..selectFormat(95)
                ..batchCount(3)
                ..quantity(1)
                ..print())
              .toBytes(),
    ),

    // H12 — Lifecycle / Exit Program Mode
    HardwareValidationCase(
      id: 'H12',
      title: 'H12 — Lifecycle',
      description: 'Advanced mode and exit program mode.',
      validationKind: ValidationKind.initialize,
      generator: () =>
          (IplPrinter()
                ..advancedMode()
                ..exitProgramMode())
              .toBytes(),
    ),
  ];
}
