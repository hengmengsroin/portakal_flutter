import 'package:portakal_flutter/portakal_flutter.dart';
import '../case_model.dart';
import '../raster_fixture.dart';

class EplValidationSuite implements ProtocolValidationSuite {
  @override
  ValidationProtocol get protocol => ValidationProtocol.epl;

  @override
  String get displayName => 'EPL2';

  @override
  String get description => 'EPL2-compatible page-mode command set';

  @override
  String? get warning => null;

  @override
  String get capabilityProbeCaseId => 'D00-EPL';

  @override
  List<HardwareValidationCase> get cases => [
        // D00-EPL — Minimal EPL Capability Probe
        HardwareValidationCase(
          id: 'D00-EPL',
          title: 'D00-EPL — Minimal EPL Probe',
          description: 'N (Clear) + A (ASCII text) + P1 (Print 1).',
          isDiagnostic: true,
          expectedPayload: 'PORTAKAL EPL TEST',
          validationKind: ValidationKind.text,
          expectedSha256: null,
          generator: () => (EplPrinter()
                ..clear()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL EPL TEST',
                  font: EplFont.font3,
                )
                ..print(copies: 1))
              .toBytes(),
        ),

        // H01 — ASCII Baseline
        HardwareValidationCase(
          id: 'H01',
          title: 'H01 — ASCII Baseline',
          description: 'Header and body text with A command.',
          expectedPayload: 'PORTAKAL 123 ABC xyz',
          validationKind: ValidationKind.text,
          expectedSha256:
              'b34bc4758a461c9848e1bb882fde809c30567a4c598ea62ada81aec0629757af',
          generator: () => (EplPrinter()
                ..clear()
                ..text(
                  x: 50,
                  y: 50,
                  text: 'PORTAKAL-HW | Proto: EPL | Case: H01',
                )
                ..text(
                  x: 50,
                  y: 100,
                  text: 'PORTAKAL 123 ABC xyz',
                  font: EplFont.font3,
                )
                ..print(copies: 1))
              .toBytes(),
        ),

        // H02-CP437 — Code Page 437
        HardwareValidationCase(
          id: 'H02-CP437',
          title: 'H02-CP437 — Latin (I8,0,001)',
          description: 'Code Page 437 Latin characters (ä, ö, ü, ß, ±, °).',
          expectedPayload: 'ä ö ü ß ± °',
          validationKind: ValidationKind.encoding,
          expectedSha256:
              '03b45233399246aabe4a849b238b2e85e2b80080903f75304f99fa1fd7263ff9',
          generator: () => (EplPrinter(
            encoding: const EplEncoding.cp437(
              sendSetCharSetCommand: true,
            ),
          )
                ..clear()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
                ..text(x: 50, y: 100, text: 'ä ö ü ß ± °')
                ..print(copies: 1))
              .toBytes(),
        ),

        // H06 — 1D Barcode Code 128 (B command)
        HardwareValidationCase(
          id: 'H06',
          title: 'H06 — Code 128 (B command)',
          description: '1D Barcode Code 128 symbology.',
          expectedPayload: 'PORTAKAL123456',
          requiresScanner: true,
          validationKind: ValidationKind.barcode,
          expectedSha256:
              'cd175036ff1284c309c30e18063e53cea1e66274aae50728f967683fc0033a7e',
          generator: () => (EplPrinter()
                ..clear()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
                ..barcode(
                  x: 50,
                  y: 70,
                  type: EplBarcodeType.code128,
                  height: 60,
                  content: 'PORTAKAL123456',
                  humanReadable: true,
                )
                ..print(copies: 1))
              .toBytes(),
        ),

        // H07 — 2D QR Code (b command)
        HardwareValidationCase(
          id: 'H07',
          title: 'H07 — QR Code (b command)',
          description: '2D QR Code symbology (Model 2, ECC M).',
          expectedPayload: 'https://example.com/portakal-hw-test',
          requiresScanner: true,
          validationKind: ValidationKind.qr,
          expectedSha256:
              '2ce2595dd8b4f7793970944b21bc9ec36f61d5a4c1ca6edd2bf58b77724f9552',
          generator: () => (EplPrinter()
                ..clear()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
                ..qrCode(
                  x: 50,
                  y: 70,
                  content: 'https://example.com/portakal-hw-test',
                  ecc: EplQrEcc.m,
                  cellWidth: 5,
                )
                ..print(copies: 1))
              .toBytes(),
        ),

        // H08 — Drawing Primitives (LO box and line)
        HardwareValidationCase(
          id: 'H08',
          title: 'H08 — Drawing (LO box & line)',
          description: 'Graphic Box and Line primitives via LO.',
          validationKind: ValidationKind.drawing,
          expectedSha256:
              'bdf88a948a958673d97b65645aaa1e9db2cdf9935af8be35c74b437dd16fb582',
          generator: () => (EplPrinter()
                ..clear()
                ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
                ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
                ..print(copies: 1))
              .toBytes(),
        ),

        // H09 — 1-Bit Binary Graphic Write (GW)
        HardwareValidationCase(
          id: 'H09',
          title: 'H09 — 64x64 Graphic (GW)',
          description:
              'Canonical 1-bit monochrome raster matrix via GW command.',
          validationKind: ValidationKind.raster,
          expectedSha256:
              '3bfee68f8be8d093e222c89b5b1a8308c8e118588e30d6819af76ba314d45060',
          generator: () => (EplPrinter()
                ..clear()
                ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H09 GW (64x64)')
                ..graphicFromMonochrome(
                  createCanonicalRaster64x64Bitmap(),
                  x: 50,
                  y: 70,
                )
                ..print(copies: 1))
              .toBytes(),
        ),

        // H10 — Multiple Copies (P3,1)
        HardwareValidationCase(
          id: 'H10',
          title: 'H10 — Multiple Copies (3 Labels)',
          description: 'Emits P3,1 to print 3 copies of the label.',
          validationKind: ValidationKind.copies,
          expectedSha256:
              '57ec02e3d464e26ee8dbb8cf3fdc477750c48ca7d49e8e6e09d690560f5a06e9',
          generator: () => (EplPrinter()
                ..clear()
                ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
                ..print(copies: 3))
              .toBytes(),
        ),

        // H12 — Buffer Clear (N command)
        HardwareValidationCase(
          id: 'H12',
          title: 'H12 — Clear (N command)',
          description: 'Emits N command to clear image buffer.',
          validationKind: ValidationKind.initialize,
          expectedSha256:
              '28312e346b76a3f91e8283519baab5f103d79547dedff5fb7ccc0dc3c5119bbe',
          generator: () => (EplPrinter()..clear()).toBytes(),
        ),
      ];
}
