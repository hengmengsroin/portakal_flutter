import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:portakal_core/portakal_core.dart';

/// Mock transport implementation matching the documented TcpPrinterTransport pattern.
class MockDocTransport implements PrinterTransport {
  final List<Uint8List> writtenChunks = [];
  ConnectionState _state = ConnectionState.disconnected;

  @override
  ConnectionState get state => _state;

  @override
  Future<void> connect() async {
    _state = ConnectionState.connected;
  }

  @override
  Future<void> disconnect() async {
    _state = ConnectionState.disconnected;
  }

  @override
  Future<void> write(Uint8List data) async {
    if (_state != ConnectionState.connected) {
      throw StateError('Transport not connected');
    }
    writtenChunks.add(Uint8List.fromList(data));
  }

  @override
  Future<Uint8List> read() async => Uint8List(0);
}

void main() {
  group('Executable Documentation Examples — Core', () {
    test('1. Pure Dart Quick Start (Preview-Before-Print via SVG & Bytes)', () {
      // 1. Build universal label layout
      final builder = label(const LabelConfig(width: 80, height: 50))
        ..text('Invoice Item', const TextOptions(x: 10, y: 10, size: 2, bold: true))
        ..barcode('ITEM-9988', const BarcodeOptions(x: 10, y: 60, type: '128', height: 50))
        ..qrcode('https://example.com/invoice/9988', const QRCodeOptions(x: 10, y: 130, cellWidth: 3))
        ..box(const BoxOptions(x: 5, y: 5, width: 620, height: 380, thickness: 2));

      // 2. Resolve once into canonical logical print job
      final ResolvedLabel job = builder.resolve();

      // 3. Render pure-Dart SVG preview string for web / backend verification
      final String svg = renderPreview(job);
      expect(svg, contains('<svg'));
      expect(svg, contains('Invoice Item'));

      // 4. Compile that SAME resolved job to printer bytes
      final Uint8List zplBytes = zpl.compileResolved(job);
      final Uint8List tscBytes = tsc.compileResolved(job);

      expect(zplBytes, isNotEmpty);
      expect(tscBytes, isNotEmpty);
    });

    test('2. Pure Dart Simple vs Resolved Workflows', () {
      final builder = label(const LabelConfig(width: 80, height: 50))
        ..text('BATCH JOB #500', const TextOptions(x: 10, y: 10));

      // Simple: compile directly
      final Uint8List batchBytes = tsc.compile(builder);
      expect(batchBytes, isNotEmpty);

      // Resolved: resolve then compile
      final job = builder.resolve();
      final Uint8List frozenBytes = tsc.compileResolved(job);
      expect(frozenBytes, equals(batchBytes));
    });

    test('3. Byte Contract: Authoritative Uint8List vs String Corruption', () {
      final builder = label(const LabelConfig(width: 40, height: 30))
        ..text('TEST', const TextOptions(x: 10, y: 10));
      final job = builder.resolve();

      final Uint8List bytes = tsc.compileResolved(job);

      // RIGHT: Raw bytes written directly to transport sink
      final transportSink = <int>[];
      transportSink.addAll(bytes);
      expect(transportSink, equals(bytes));

      // WRONG demonstration: Converting binary bytes through UTF-8 strings
      // is lossy for non-UTF-8 raster data / binary control sequences
      final decodedDiagnostic = latin1.decode(bytes);
      expect(decodedDiagnostic, isNotEmpty);
    });

    test('4. Getting Started: ESC/POS Receipt Example', () {
      final printer = EscPosPrinter()
        ..initialize()
        ..align(EscPosAlignment.center)
        ..bold(true)
        ..textSize(width: 2, height: 2)
        ..textLine('Coffee Shop')
        ..bold(false)
        ..textSize(width: 1, height: 1)
        ..align(EscPosAlignment.left)
        ..feedLines(1)
        ..textLine('1x Espresso         \$3.50')
        ..textLine('1x Croissant        \$4.00')
        ..feedLines(1)
        ..bold(true)
        ..textLine('Total:              \$7.50')
        ..bold(false)
        ..feedLines(3)
        ..cut();

      final Uint8List bytes = printer.toBytes();
      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(0x1B)); // ESC
      expect(bytes, containsAllInOrder([0x1B, 0x40])); // ESC @
    });

    test('5. Getting Started: TSC Label Example', () {
      final printer = TscPrinter()
        ..sizeDots(800, 1200)
        ..cls()
        ..text(
          x: 50,
          y: 50,
          text: 'EXPRESS SHIPPING',
          xMultiplication: 2,
          yMultiplication: 2,
        )
        ..barcode(
          x: 50,
          y: 120,
          type: TscBarcodeType.code128,
          height: 80,
          content: 'TRACK-998877',
        )
        ..qrCode(x: 50, y: 240, content: 'https://track.example.com/998877')
        ..print()
        ..toBytes();

      final Uint8List bytes = printer.toBytes();
      expect(bytes, isNotEmpty);
      final text = String.fromCharCodes(bytes);
      expect(text, contains('SIZE'));
      expect(text, contains('CLS'));
      expect(text, contains('EXPRESS SHIPPING'));
    });

    test('6. Universal Builder: Layout & Multi-Protocol Compilation', () {
      final myLabel = label(const LabelConfig(width: 80, height: 50))
        ..text(
          'SHIPPING LABEL',
          const TextOptions(x: 20, y: 20, size: 2, bold: true),
        )
        ..barcode(
          'TRACK-123456',
          const BarcodeOptions(x: 20, y: 70, type: '128', height: 60),
        )
        ..qrcode(
          'https://example.com',
          const QRCodeOptions(x: 20, y: 150, cellWidth: 4),
        )
        ..box(
          const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2),
        );

      final Uint8List tscBytes = tsc.compile(myLabel);
      final Uint8List zplBytes = zpl.compile(myLabel);
      final Uint8List eplBytes = epl.compile(myLabel);

      expect(tscBytes, isA<Uint8List>());
      expect(zplBytes, isA<Uint8List>());
      expect(eplBytes, isA<Uint8List>());
    });

    test('7. UnsupportedFeaturePolicy: Default Throws vs Ignore Omission', () {
      final circleLabel = label(const LabelConfig(width: 80, height: 60))
        ..circle(const CircleOptions(x: 100, y: 100, diameter: 80));

      // Throws UnsupportedFeatureError by default on ESC/POS
      expect(
        () => escpos.compile(circleLabel),
        throwsA(isA<UnsupportedFeatureError>()),
      );

      // Successfully compiles when policy is set to ignore
      final safeBytes = escpos.compile(
        circleLabel,
        policy: UnsupportedFeaturePolicy.ignore,
      );
      expect(safeBytes, isA<Uint8List>());
      expect(safeBytes, isNotEmpty);
    });

    test('8. Character Encoding & Safe Replacement Policy', () {
      final encoder = getEncoder(PrinterCodePage.cp858);
      final Uint8List encoded = encoder.encode('Total: 15.50 €');
      expect(encoded, isNotEmpty);

      // CP437 throws on Euro (€)
      final cp437Encoder = getEncoder(PrinterCodePage.cp437);
      expect(
        () => cp437Encoder.encode('Total: 15.50 €'),
        throwsA(isA<UnsupportedCharacterException>()),
      );

      // Safe replacement mode replaces unmapped characters with '?'
      final safeBytes = cp437Encoder.encode(
        'Total: 15.50 €',
        replaceUnsupported: true,
      );
      final decodedAscii = String.fromCharCodes(safeBytes);
      expect(decodedAscii, equals('Total: 15.50 ?'));
    });

    test('9. Raw Bytes Passthrough & ASCII Validation', () {
      final buffer = Uint8List.fromList([0x1B, 0x40]);
      final labelBuilder = label(const LabelConfig(width: 50, height: 30))
        ..rawBytes(buffer)
        ..rawAscii('CLS\n');

      final compiled = tsc.compile(labelBuilder);
      expect(compiled, isNotEmpty);

      // Non-ASCII throws UnsupportedCharacterException in rawAscii
      expect(
        () => label(const LabelConfig(width: 50, height: 30)).rawAscii('10 €'),
        throwsA(isA<UnsupportedCharacterException>()),
      );
    });

    test('10. Receipt Formatting: ReceiptColumn', () {
      final table = formatTable(
        [
          const ReceiptColumn(width: 20, align: 'left'),
          const ReceiptColumn(width: 10, align: 'right'),
        ],
        [
          ['Coffee', '\$3.50'],
          ['Muffin', '\$2.50'],
        ],
        32,
      );

      expect(table.join('\n'), contains('Coffee'));
      expect(table.join('\n'), contains('\$3.50'));
    });

    test('11. Transport Contracts: chunkedWrite and writeWithRetry', () async {
      final transport = MockDocTransport();
      await transport.connect();

      final data = Uint8List(1200); // 1200 bytes
      for (int i = 0; i < 1200; i++) {
        data[i] = i % 256;
      }

      // Chunked write
      await chunkedWrite(transport, data, const ChunkOptions(chunkSize: 512));

      expect(transport.writtenChunks.length, equals(3));
      expect(transport.writtenChunks[0].length, equals(512));
      expect(transport.writtenChunks[1].length, equals(512));
      expect(transport.writtenChunks[2].length, equals(176));

      // writeWithRetry
      await writeWithRetry(
        transport,
        Uint8List.fromList([0x1B, 0x40]),
        const RetryOptions(maxRetries: 2),
      );

      expect(
        transport.writtenChunks.last,
        equals(Uint8List.fromList([0x1B, 0x40])),
      );
      expect(BleUuids.service, isNotEmpty);
      expect(usbVendorIds.epson, equals(0x04B8));
    });

    test('12. IPL 7-Phase Lifecycle Native Builder', () {
      final printer = IplPrinter()
        ..advancedMode()
        ..programMode()
        ..eraseFormat(90)
        ..createFormat(90)
        ..labelLength(600)
        ..text(x: 50, y: 50, text: 'INTERMEC IPL TEST')
        ..barcode(y: 120, height: 70, content: 'IPL-998877')
        ..exitProgramMode()
        ..selectFormat(90)
        ..print(batchCount: 1, quantity: 1);

      final Uint8List bytes = printer.toBytes();
      expect(bytes, isNotEmpty);
      final text = String.fromCharCodes(bytes);
      expect(text, contains('E90'));
      expect(text, contains('F90'));
      expect(text, contains('INTERMEC IPL TEST'));
    });

    test('13. Image Dithering Pipeline', () {
      final rgba = Uint8List(16 * 16 * 4); // 16x16 white square
      for (int i = 0; i < rgba.length; i += 4) {
        rgba[i] = 255;
        rgba[i + 1] = 255;
        rgba[i + 2] = 255;
        rgba[i + 3] = 255;
      }

      final bitmap = imageToMonochrome(
        rgba,
        16,
        16,
        const MonochromeOptions(dither: 'floyd-steinberg', threshold: 128),
      );

      expect(bitmap.width, equals(16));
      expect(bitmap.height, equals(16));
      expect(bitmap.bytesPerRow, equals(2));
      expect(bitmap.data.length, equals(32));
    });
  });
}
