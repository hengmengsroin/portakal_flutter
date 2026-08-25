import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';
import 'raster_fixture.dart';

/// Support classification for a hardware validation case.
enum SupportStatus {
  /// Fully supported by current SDK and runnable on hardware.
  supported,

  /// Not supported by the current SDK implementation.
  notSupportedSdk,

  /// Not supported by the physical device / printer language specification.
  notSupportedDevice,
}

/// Typed definition for a reproducible hardware validation test case.
class HardwareCaseDefinition {
  final String protocol;
  final String id;
  final String description;
  final String builderName;
  final SupportStatus status;
  final String? statusReason;
  final String? expectedPayload;
  final Uint8List Function() generator;

  const HardwareCaseDefinition({
    required this.protocol,
    required this.id,
    required this.description,
    required this.builderName,
    this.status = SupportStatus.supported,
    this.statusReason,
    this.expectedPayload,
    required this.generator,
  });

  bool get isSupported => status == SupportStatus.supported;
}

/// Registry of all standard hardware validation cases across the 9 supported protocols.
class CaseRegistry {
  static const List<String> supportedProtocols = [
    'tsc',
    'escpos',
    'zpl',
    'epl',
    'cpcl',
    'dpl',
    'ipl',
    'sbpl',
    'star',
  ];

  static final Map<String, List<HardwareCaseDefinition>> _registry = {
    'tsc': _buildTscCases(),
    'escpos': _buildEscPosCases(),
    'zpl': _buildZplCases(),
    'epl': _buildEplCases(),
    'cpcl': _buildCpclCases(),
    'dpl': _buildDplCases(),
    'ipl': _buildIplCases(),
    'sbpl': _buildSbplCases(),
    'star': _buildStarCases(),
  };

  /// Returns all registered cases for [protocol].
  static List<HardwareCaseDefinition> getCasesForProtocol(String protocol) {
    final list = _registry[protocol.toLowerCase()];
    if (list == null) {
      throw ArgumentError(
        'Unknown protocol "$protocol". Valid: ${supportedProtocols.join(', ')}',
      );
    }
    return list;
  }

  /// Returns a specific case definition by [protocol] and [caseId].
  static HardwareCaseDefinition? getCase(String protocol, String caseId) {
    final cases = getCasesForProtocol(protocol);
    final target = caseId.toUpperCase();
    for (final c in cases) {
      if (c.id.toUpperCase() == target) {
        return c;
      }
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // TSC / TSPL2 Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildTscCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H01',
        description: 'ASCII Text baseline layout',
        builderName: 'TscPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..text(
                x: 50,
                y: 50,
                text:
                    'PORTAKAL-HW | Proto: TSC | Case: H01 | SDK: 0.3.0 | Run: 001',
                font: TscResidentFont.scalable,
                xMultiplication: 1,
                yMultiplication: 1,
              )
              ..text(
                x: 50,
                y: 120,
                text: 'PORTAKAL 123 ABC xyz',
                font: TscResidentFont.scalable,
                xMultiplication: 2,
                yMultiplication: 2,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-CP437',
        description: 'Code Page 437 Latin & special characters',
        builderName: 'TscPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.cp437(
            sendCodePageCommand: true,
          ),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
              ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-CP850',
        description: 'Code Page 850 Multilingual Latin-1',
        builderName: 'TscPrinter',
        expectedPayload: 'é à è ù ç ñ Á Í Ó',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.cp850(
            sendCodePageCommand: true,
          ),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP850')
              ..text(x: 50, y: 120, text: 'é à è ù ç ñ Á Í Ó')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-CP857',
        description: 'Code Page 857 Turkish characters',
        builderName: 'TscPrinter',
        expectedPayload: 'Ğ ğ Ş ş İ ı ç ö ü',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.cp857(
            sendCodePageCommand: true,
          ),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP857')
              ..text(x: 50, y: 120, text: 'Ğ ğ Ş ş İ ı ç ö ü')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-CP866',
        description: 'Code Page 866 Cyrillic #2',
        builderName: 'TscPrinter',
        expectedPayload: 'Привет мир! 123',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.cp866(
            sendCodePageCommand: true,
          ),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP866')
              ..text(x: 50, y: 120, text: 'Привет мир! 123')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-CP1252',
        description: 'Windows-1252 Western European',
        builderName: 'TscPrinter',
        expectedPayload: 'é à è “ ” ‘ ’ © ®',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.cp1252(
            sendCodePageCommand: true,
          ),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP1252')
              ..text(x: 50, y: 120, text: 'é à è “ ” ‘ ’ © ®')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H02-UTF8',
        description: 'UTF-8 Unicode encoding mode',
        builderName: 'TscPrinter',
        expectedPayload: 'Portakal Unicode: 日本語 / 한국어 / ខ្មែរ',
        generator: () => (TscPrinter(
          encoding: const TscEncoding.utf8(sendCodePageCommand: true),
        )
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-UTF8')
              ..text(
                x: 50,
                y: 120,
                text: 'Portakal Unicode: 日本語 / 한국어 / ខ្មែរ',
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H04',
        description: 'Rotation (0°, 90°, 180°, 270°)',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()
              ..sizeDots(800, 800)
              ..cls()
              ..text(
                x: 100,
                y: 100,
                text: 'ROT 0 DEG',
                rotation: TscRotation.deg0,
              )
              ..text(
                x: 300,
                y: 100,
                text: 'ROT 90 DEG',
                rotation: TscRotation.deg90,
              )
              ..text(
                x: 500,
                y: 300,
                text: 'ROT 180 DEG',
                rotation: TscRotation.deg180,
              )
              ..text(
                x: 300,
                y: 500,
                text: 'ROT 270 DEG',
                rotation: TscRotation.deg270,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H05',
        description: 'Font Scaling (1x, 2x, 4x)',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..text(
                x: 50,
                y: 50,
                text: 'Scale 1x Normal',
                font: TscResidentFont.font3,
                xMultiplication: 1,
                yMultiplication: 1,
              )
              ..text(
                x: 50,
                y: 120,
                text: 'Scale 2x Medium',
                font: TscResidentFont.font3,
                xMultiplication: 2,
                yMultiplication: 2,
              )
              ..text(
                x: 50,
                y: 220,
                text: 'Scale 4x Large',
                font: TscResidentFont.font3,
                xMultiplication: 4,
                yMultiplication: 4,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H06',
        description: '1D Barcode (Code128)',
        builderName: 'TscPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H06 Code128')
              ..barcode(
                x: 50,
                y: 80,
                type: TscBarcodeType.code128,
                height: 80,
                content: 'PORTAKAL123456',
                readable: TscBarcodeReadable.left,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H07',
        description: '2D QR Code',
        builderName: 'TscPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..text(x: 50, y: 30, text: 'PORTAKAL-HW | Case: H07 QR Code')
              ..qrCode(
                x: 50,
                y: 80,
                content: 'https://example.com/portakal-hw-test',
                ecc: TscQrEcc.m,
                cellWidth: 5,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H08',
        description: 'Drawing (Box, Line, Circle)',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..box(x: 50, y: 50, xEnd: 250, yEnd: 150, thickness: 2)
              ..bar(x: 50, y: 180, width: 400, height: 4)
              ..circle(x: 350, y: 100, diameter: 80, thickness: 2)
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H09',
        description: '1-Bit Raster Bitmap (64x64)',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()
              ..sizeDots(800, 600)
              ..cls()
              ..text(
                x: 50,
                y: 30,
                text: 'PORTAKAL-HW | Case: H09 Raster 64x64',
              )
              ..bitmapFromMonochrome(
                createRaster64x64Bitmap(),
                x: 50,
                y: 80,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H10',
        description: 'Copies (Batch 3 copies)',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()
              ..sizeDots(800, 400)
              ..cls()
              ..text(
                x: 50,
                y: 50,
                text: 'PORTAKAL-HW | Case: H10 Batch 3 Copies',
              )
              ..print(copies: 3))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H11',
        description: 'Cutter command',
        builderName: 'TscPrinter',
        status: SupportStatus.notSupportedSdk,
        statusReason:
            'TSC cutter control is configured via printer-side SET CUTTER rather than per-label command stream in current baseline',
        generator: () => Uint8List(0),
      ),
      HardwareCaseDefinition(
        protocol: 'tsc',
        id: 'H12',
        description: 'Initialization & CLS clear',
        builderName: 'TscPrinter',
        generator: () => (TscPrinter()..cls()).toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // ESC/POS Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildEscPosCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H01',
        description: 'ASCII Text formatting (Bold, Underline, Center)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (EscPosPrinter()
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
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP437',
        description: 'Code Page 437 Latin (Table 0)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (EscPosPrinter(
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
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP858',
        description:
            'Code Page 858 Western European with Euro sign € (Table 19)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'é à è ù ç €',
        generator: () => (EscPosPrinter(
          encoding: const EscPosEncoding.cp858(
            tableId: 19,
            sendTableSelect: true,
          ),
        )
              ..initialize()
              ..text(
                'PORTAKAL-HW | Case: H02-CP858\né à è ù ç € (Euro at 0xD5)\n',
              )
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP850',
        description: 'Code Page 850 Multilingual Latin-1 (Table 2)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'é à è ù ç ñ Á Í Ó',
        generator: () => (EscPosPrinter(
          encoding: const EscPosEncoding.cp850(
            tableId: 2,
            sendTableSelect: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP850\né à è ù ç ñ Á Í Ó\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP1252',
        description: 'Windows-1252 Western European (Table 16)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'é à è € “ ” ‘ ’ © ®',
        generator: () => (EscPosPrinter(
          encoding: const EscPosEncoding.cp1252(
            tableId: 16,
            sendTableSelect: true,
          ),
        )
              ..initialize()
              ..text(
                'PORTAKAL-HW | Case: H02-CP1252\né à è € “ ” ‘ ’ © ®\n',
              )
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP857',
        description: 'Code Page 857 Turkish (Table 13)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'Ğ ğ Ş ş İ ı ç ö ü',
        generator: () => (EscPosPrinter(
          encoding: const EscPosEncoding.cp857(
            tableId: 13,
            sendTableSelect: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP857\nĞ ğ Ş ş İ ı ç ö ü\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H02-CP866',
        description: 'Code Page 866 Cyrillic #2 (Table 17)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'Привет мир! 123',
        generator: () => (EscPosPrinter(
          encoding: const EscPosEncoding.cp866(
            tableId: 17,
            sendTableSelect: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP866\nПривет мир! 123\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H04',
        description: 'Rotation (0° and 180° upside down)',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
              ..initialize()
              ..text('Normal text orientation\n')
              ..invert(true)
              ..text('Inverted text mode\n')
              ..invert(false)
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H05',
        description: 'Font Scale multipliers (1x, 2x, 4x)',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
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
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H06',
        description: '1D Barcode (Code128)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (EscPosPrinter()
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
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H07',
        description: '2D QR Code (Model 2 via GS ( k)',
        builderName: 'EscPosPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (EscPosPrinter()
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
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H08',
        description: 'Geometric Line separator',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
              ..initialize()
              ..text('Above separator line\n')
              ..text('------------------------------------------\n')
              ..text('Below separator line\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H09',
        description: '1-Bit Raster Bitmap (GS v 0)',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
              ..initialize()
              ..text('PORTAKAL-HW | Case: H09 Raster GS v 0 (64x64)\n')
              ..rasterFromMonochrome(createRaster64x64Bitmap())
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H10',
        description: 'Multiple copies via repeated print cycle',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
              ..initialize()
              ..text('Receipt Copy 1 of 2\n')
              ..cut(mode: EscPosCutMode.partial, feedLines: 2)
              ..initialize()
              ..text('Receipt Copy 2 of 2\n')
              ..cut(mode: EscPosCutMode.partial, feedLines: 2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H11',
        description: 'Partial paper cut',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()
              ..initialize()
              ..text('End of receipt - Cutting below\n')
              ..cut(mode: EscPosCutMode.partial, feedLines: 3))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'escpos',
        id: 'H12',
        description: 'Printer initialize (ESC @)',
        builderName: 'EscPosPrinter',
        generator: () => (EscPosPrinter()..initialize()).toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // ZPL II Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildZplCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H01',
        description: 'ASCII Text with ^FO and ^FD',
        builderName: 'ZplPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (ZplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H02-UTF8',
        description: 'UTF-8 multilingual text with ^CI28',
        builderName: 'ZplPrinter',
        expectedPayload: 'Portakal UTF-8: é à ü ç € Привет ខ្មែរ',
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H02-CP1252',
        description: 'Legacy Western European without ^CI28',
        builderName: 'ZplPrinter',
        expectedPayload: 'é à è ç',
        generator: () => (ZplPrinter(encoding: const ZplEncoding.legacy())
              ..startFormat()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-Legacy')
              ..text(x: 50, y: 120, text: 'é à è ç')
              ..endFormat())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H04',
        description: 'Rotation (0°, 90°, 180°, 270°)',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
              ..startFormat()
              ..text(
                x: 100,
                y: 100,
                text: 'ROT 0 DEG',
                rotation: ZplRotation.unrotated,
              )
              ..text(
                x: 300,
                y: 100,
                text: 'ROT 90 DEG',
                rotation: ZplRotation.rotated90,
              )
              ..text(
                x: 500,
                y: 300,
                text: 'ROT 180 DEG',
                rotation: ZplRotation.inverted180,
              )
              ..text(
                x: 300,
                y: 500,
                text: 'ROT 270 DEG',
                rotation: ZplRotation.bottomUp270,
              )
              ..endFormat())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H05',
        description: 'Font Sizing with ^A0',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H06',
        description: '1D Barcode (^BC Code128)',
        builderName: 'ZplPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (ZplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H07',
        description: '2D QR Code (^BQ Model 2)',
        builderName: 'ZplPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (ZplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H08',
        description: 'Drawing (^GB Graphic Box & Line)',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
              ..startFormat()
              ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
              ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
              ..endFormat())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H09',
        description: '1-Bit Raster Bitmap (^GFA ASCII Hex)',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
              ..startFormat()
              ..text(
                x: 50,
                y: 50,
                text: 'PORTAKAL-HW | Case: H09 ZPL ^GFA (64x64)',
              )
              ..graphicFieldFromMonochrome(
                createRaster64x64Bitmap(),
                x: 50,
                y: 100,
              )
              ..endFormat())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H10',
        description: 'Copies via ^PQ',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H11',
        description: 'Cutter command',
        builderName: 'ZplPrinter',
        status: SupportStatus.notSupportedSdk,
        statusReason:
            'Zebra cutter actuation is controlled via media mode (^MM) or host config rather than per-label cut command in current baseline',
        generator: () => Uint8List(0),
      ),
      HardwareCaseDefinition(
        protocol: 'zpl',
        id: 'H12',
        description: 'Label framing (^XA / ^XZ)',
        builderName: 'ZplPrinter',
        generator: () => (ZplPrinter()
              ..startFormat()
              ..endFormat())
            .toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // EPL2 Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildEplCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H01',
        description: 'ASCII Text (A command)',
        builderName: 'EplPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
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
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H02-CP437',
        description: 'Code Page 437 (I8,0,001)',
        builderName: 'EplPrinter',
        expectedPayload: 'ä ö ü ß ± °',
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
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H02-CP850',
        description: 'Code Page 850 (I8,1,001)',
        builderName: 'EplPrinter',
        expectedPayload: 'é à è ù ç ñ Á Í Ó',
        generator: () => (EplPrinter(
          encoding: const EplEncoding.cp850(
            sendSetCharSetCommand: true,
          ),
        )
              ..clear()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP850')
              ..text(x: 50, y: 100, text: 'é à è ù ç ñ Á Í Ó')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H02-CP1252',
        description: 'Windows-1252 (I8,13,001)',
        builderName: 'EplPrinter',
        expectedPayload: 'é à è “ ” ‘ ’ © ®',
        generator: () => (EplPrinter(
          encoding: const EplEncoding.cp1252(
            sendSetCharSetCommand: true,
          ),
        )
              ..clear()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP1252')
              ..text(x: 50, y: 100, text: 'é à è “ ” ‘ ’ © ®')
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H06',
        description: '1D Barcode (B Code128)',
        builderName: 'EplPrinter',
        expectedPayload: 'PORTAKAL123456',
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
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H07',
        description: '2D QR Code (b QR)',
        builderName: 'EplPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
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
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H08',
        description: 'Box and Line drawing (LO)',
        builderName: 'EplPrinter',
        generator: () => (EplPrinter()
              ..clear()
              ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
              ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H09',
        description: '1-Bit Binary Graphic Write (GW)',
        builderName: 'EplPrinter',
        generator: () => (EplPrinter()
              ..clear()
              ..text(
                x: 50,
                y: 30,
                text: 'PORTAKAL-HW | Case: H09 GW (64x64)',
              )
              ..graphicFromMonochrome(
                createRaster64x64Bitmap(),
                x: 50,
                y: 70,
              )
              ..print(copies: 1))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H10',
        description: 'Copies (P3,1)',
        builderName: 'EplPrinter',
        generator: () => (EplPrinter()
              ..clear()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
              ..print(copies: 3))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'epl',
        id: 'H12',
        description: 'Buffer clear (N command)',
        builderName: 'EplPrinter',
        generator: () => (EplPrinter()..clear()).toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // CPCL Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildCpclCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H01',
        description: 'ASCII Text (TEXT command)',
        builderName: 'CpclPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (CpclPrinter()
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
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H02-CP437',
        description: 'Code Page 437 (COUNTRY USA)',
        builderName: 'CpclPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (CpclPrinter(
          encoding: const CpclEncoding.usa(sendCountryCommand: true),
        )
              ..startPage(heightDots: 400)
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
              ..text(x: 50, y: 100, text: 'ä ö ü ß ± °')
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H02-CP850',
        description: 'Code Page 850 (COUNTRY CP850)',
        builderName: 'CpclPrinter',
        expectedPayload: 'é à è ù ç ñ Á Í Ó',
        generator: () => (CpclPrinter(
          encoding: const CpclEncoding.cp850(
            sendCountryCommand: true,
          ),
        )
              ..startPage(heightDots: 400)
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP850')
              ..text(x: 50, y: 100, text: 'é à è ù ç ñ Á Í Ó')
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H02-CP1252',
        description: 'Windows-1252 (COUNTRY CP1252)',
        builderName: 'CpclPrinter',
        expectedPayload: 'é à è “ ” ‘ ’ © ®',
        generator: () => (CpclPrinter(
          encoding: const CpclEncoding.cp1252(
            sendCountryCommand: true,
          ),
        )
              ..startPage(heightDots: 400)
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP1252')
              ..text(x: 50, y: 100, text: 'é à è “ ” ‘ ’ © ®')
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H06',
        description: '1D Barcode (BARCODE 128)',
        builderName: 'CpclPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (CpclPrinter()
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
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H07',
        description: '2D QR Code (BARCODE QR)',
        builderName: 'CpclPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (CpclPrinter()
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
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H08',
        description: 'Box and Line drawing (BOX, LINE)',
        builderName: 'CpclPrinter',
        generator: () => (CpclPrinter()
              ..startPage(heightDots: 400)
              ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
              ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H09',
        description: '1-Bit ASCII-Hex Graphic (EG)',
        builderName: 'CpclPrinter',
        generator: () => (CpclPrinter()
              ..startPage(heightDots: 400)
              ..text(
                x: 50,
                y: 30,
                text: 'PORTAKAL-HW | Case: H09 EG (64x64)',
              )
              ..graphicFromMonochrome(
                createRaster64x64Bitmap(),
                x: 50,
                y: 70,
              )
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H10',
        description: 'Copies via session header quantity',
        builderName: 'CpclPrinter',
        generator: () => (CpclPrinter()
              ..startPage(heightDots: 300, copies: 3)
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
              ..form()
              ..print())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'cpcl',
        id: 'H12',
        description: 'Session start and form feed',
        builderName: 'CpclPrinter',
        generator: () => (CpclPrinter()
              ..startPage(heightDots: 200)
              ..form()
              ..print())
            .toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // DPL Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildDplCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H01',
        description: 'ASCII Text with STX L and E CR termination',
        builderName: 'DplPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (DplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H02-CP437',
        description: 'Code Page 437 characters',
        builderName: 'DplPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (DplPrinter(encoding: const DplEncoding.cp437())
              ..startLabel()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
              ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
              ..endLabel())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H06',
        description: '1D Barcode (Code128 record B)',
        builderName: 'DplPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (DplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H07',
        description: '2D QR Code (record W1D)',
        builderName: 'DplPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (DplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H08',
        description: 'Box and Line drawing (Record 9)',
        builderName: 'DplPrinter',
        generator: () => (DplPrinter()
              ..startLabel()
              ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
              ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
              ..endLabel())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H09',
        description: '1-Bit Raster Bitmap',
        builderName: 'DplPrinter',
        status: SupportStatus.notSupportedSdk,
        statusReason:
            'Portakal current DPL implementation does not support ImageElement / generic raster graphics',
        generator: () => Uint8List(0),
      ),
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H10',
        description: 'Copies configuration',
        builderName: 'DplPrinter',
        generator: () => (DplPrinter()
              ..startLabel()
              ..copies(3)
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H10 3 Copies')
              ..endLabel())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'dpl',
        id: 'H12',
        description: 'Format Start and End framing',
        builderName: 'DplPrinter',
        generator: () => (DplPrinter()
              ..startLabel()
              ..endLabel())
            .toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // IPL Cases (Strictly using F90–F99 reserved format numbers)
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildIplCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H01',
        description: 'ASCII Text (Advanced Mode + Format F90 lifecycle)',
        builderName: 'IplPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (IplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H02-CP437',
        description: 'Code Page 437 on Format F91',
        builderName: 'IplPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (IplPrinter(encoding: const IplEncoding.cp437())
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H06',
        description: '1D Barcode (Code128 on Format F92)',
        builderName: 'IplPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (IplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H07',
        description: '2D QR Code (c21 on Format F93)',
        builderName: 'IplPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (IplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H08',
        description: 'Box and Line drawing on Format F94',
        builderName: 'IplPrinter',
        generator: () => (IplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H09',
        description: '1-Bit Raster Bitmap',
        builderName: 'IplPrinter',
        status: SupportStatus.notSupportedSdk,
        statusReason:
            'Portakal current IPL implementation does not support ImageElement / generic raster graphics',
        generator: () => Uint8List(0),
      ),
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H10',
        description: 'Copies and batch execution on Format F95',
        builderName: 'IplPrinter',
        generator: () => (IplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'ipl',
        id: 'H12',
        description: 'Advanced mode and program mode exit',
        builderName: 'IplPrinter',
        generator: () => (IplPrinter()
              ..advancedMode()
              ..exitProgramMode())
            .toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // SBPL (SATO) Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildSbplCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H01',
        description: 'ASCII Text (ESC V / ESC H)',
        builderName: 'SbplPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (SbplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H02-CP437',
        description: 'Code Page 437',
        builderName: 'SbplPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (SbplPrinter(encoding: const SbplEncoding.cp437())
              ..startJob()
              ..text(x: 50, y: 50, text: 'PORTAKAL-HW | Case: H02-CP437')
              ..text(x: 50, y: 120, text: 'ä ö ü ß ± °')
              ..endJob())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H06',
        description: '1D Barcode (ESC B Code128)',
        builderName: 'SbplPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (SbplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H07',
        description: '2D QR Code (ESC 2D30)',
        builderName: 'SbplPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (SbplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H08',
        description: 'Box and Line drawing (ESC FW)',
        builderName: 'SbplPrinter',
        generator: () => (SbplPrinter()
              ..startJob()
              ..box(x: 50, y: 50, width: 200, height: 100, thickness: 2)
              ..line(x1: 50, y1: 180, x2: 450, y2: 180, thickness: 4)
              ..endJob())
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H09',
        description: '1-Bit Raster Bitmap',
        builderName: 'SbplPrinter',
        status: SupportStatus.notSupportedSdk,
        statusReason:
            'Portakal current SBPL implementation does not support ImageElement / generic raster graphics',
        generator: () => Uint8List(0),
      ),
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H10',
        description: 'Copies via ESC Q',
        builderName: 'SbplPrinter',
        generator: () => (SbplPrinter()
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
      HardwareCaseDefinition(
        protocol: 'sbpl',
        id: 'H12',
        description: 'Job start (ESC A) and Job end (ESC Z)',
        builderName: 'SbplPrinter',
        generator: () => (SbplPrinter()
              ..startJob()
              ..endJob())
            .toBytes(),
      ),
    ];
  }

  // --------------------------------------------------------------------------
  // Star PRNT (Line Mode) Cases
  // --------------------------------------------------------------------------
  static List<HardwareCaseDefinition> _buildStarCases() {
    return [
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H01',
        description: 'ASCII Text formatting (Bold, Underline, Center)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'PORTAKAL 123 ABC xyz',
        generator: () => (StarPrntPrinter()
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
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H02-CP437',
        description: 'Code Page 437 (Table 0)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'ä ö ü ß ± °',
        generator: () => (StarPrntPrinter(
          encoding: const StarPrntEncoding.cp437(
            sendCodePageCommand: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP437\nä ö ü ß ± °\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H02-CP858',
        description:
            'Code Page 858 Western European with Euro sign € (Table 3)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'é à è ù ç €',
        generator: () => (StarPrntPrinter(
          encoding: const StarPrntEncoding.cp858(
            sendCodePageCommand: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP858\né à è ù ç €\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H02-CP850',
        description: 'Code Page 850 Multilingual Latin-1 (Table 1)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'é à è ù ç ñ Á Í Ó',
        generator: () => (StarPrntPrinter(
          encoding: const StarPrntEncoding.cp850(
            sendCodePageCommand: true,
          ),
        )
              ..initialize()
              ..text('PORTAKAL-HW | Case: H02-CP850\né à è ù ç ñ Á Í Ó\n')
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H02-CP1252',
        description: 'Windows-1252 Western European (Table 16)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'é à è € “ ” ‘ ’ © ®',
        generator: () => (StarPrntPrinter(
          encoding: const StarPrntEncoding.cp1252(
            sendCodePageCommand: true,
          ),
        )
              ..initialize()
              ..text(
                'PORTAKAL-HW | Case: H02-CP1252\né à è € “ ” ‘ ’ © ®\n',
              )
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H06',
        description: '1D Barcode (ESC GS b Code128)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'PORTAKAL123456',
        generator: () => (StarPrntPrinter()
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
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H07',
        description: '2D QR Code (ESC GS y S 0/1/2)',
        builderName: 'StarPrntPrinter',
        expectedPayload: 'https://example.com/portakal-hw-test',
        generator: () => (StarPrntPrinter()
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
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H09',
        description:
            'Star Line Mode Raster (ESC * r A ... b nL nH ... ESC * r B)',
        builderName: 'StarPrntPrinter',
        generator: () => (StarPrntPrinter()
              ..initialize()
              ..text('PORTAKAL-HW | Case: H09 Star Raster (64x64)\n')
              ..rasterFromMonochrome(createRaster64x64Bitmap())
              ..feedLines(2))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H11',
        description: 'Paper Cut (ESC d 2 partial cut)',
        builderName: 'StarPrntPrinter',
        generator: () => (StarPrntPrinter()
              ..initialize()
              ..text('End of receipt - Cutting below\n')
              ..feedLines(3)
              ..cut(StarCutMode.partial))
            .toBytes(),
      ),
      HardwareCaseDefinition(
        protocol: 'star',
        id: 'H12',
        description: 'Printer initialize (ESC @)',
        builderName: 'StarPrntPrinter',
        generator: () => (StarPrntPrinter()..initialize()).toBytes(),
      ),
    ];
  }
}
