import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/hardware/escpos_hardware_cases.dart';
import 'package:example/src/hardware/raster_fixture.dart';
import 'package:example/src/hardware/sha256.dart';
import 'package:example/src/hardware/tsc_hardware_cases.dart';
import 'package:example/src/pages/hardware_validation_page.dart';
import 'package:example/src/transport/hardware_printer_transport.dart';

void main() {
  group('ESC/POS Diagnostic Probes & Generator Verification', () {
    test(
      'D00 Pure ASCII probe generates exact 16 bytes without ESC/POS commands',
      () {
        final d00 = EscPosHardwareSuite.diagnosticCases.firstWhere(
          (c) => c.id == 'D00',
        );
        final bytes = d00.generator();
        expect(bytes.length, equals(16));
        expect(
          bytes,
          equals(
            Uint8List.fromList([
              0x50, 0x4F, 0x52, 0x54, 0x41, 0x4B, 0x41, 0x4C, // PORTAKAL
              0x20, // space
              0x54, 0x45, 0x53, 0x54, // TEST
              0x0A, 0x0A, 0x0A, // \n\n\n
            ]),
          ),
        );
        expect(
          WriteDiagnosticInfo.formatHex(bytes),
          equals('50 4F 52 54 41 4B 41 4C 20 54 45 53 54 0A 0A 0A'),
        );
      },
    );

    test(
      'D01 Minimal ESC/POS probe generates exact 18 bytes with 1B 40 prefix',
      () {
        final d01 = EscPosHardwareSuite.diagnosticCases.firstWhere(
          (c) => c.id == 'D01',
        );
        final bytes = d01.generator();
        expect(bytes.length, equals(18));
        expect(bytes.sublist(0, 2), equals([0x1B, 0x40])); // ESC @
        expect(
          bytes.sublist(2),
          equals(
            Uint8List.fromList([
              0x50,
              0x4F,
              0x52,
              0x54,
              0x41,
              0x4B,
              0x41,
              0x4C,
              0x20,
              0x54,
              0x45,
              0x53,
              0x54,
              0x0A,
              0x0A,
              0x0A,
            ]),
          ),
        );
      },
    );

    test('H01-NOCUT generates formatted ASCII text without cutter command', () {
      final h01NoCut = EscPosHardwareSuite.diagnosticCases.firstWhere(
        (c) => c.id == 'H01-NOCUT',
      );
      final bytes = h01NoCut.generator();
      expect(bytes.length, equals(76));
      expect(h01NoCut.requiresCutter, isFalse);
    });

    test('H01 ASCII generator matches deterministic golden SHA-256', () {
      final h01Case = EscPosHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H01',
      );
      final bytes1 = h01Case.generator();
      final bytes2 = h01Case.generator();

      expect(
        bytes1,
        equals(bytes2),
        reason: 'H01 generation must be deterministic',
      );
      final sha = calculateSha256(bytes1);
      expect(sha, equals(h01Case.goldenSha256));
      expect(sha.length, equals(64));
    });

    test(
      'Canonical 64x64 raster fixture produces exactly 512 bytes with golden SHA',
      () {
        final fixtureBytes = generateCanonicalRaster64x64Bytes();
        expect(fixtureBytes.length, equals(512));

        final fixtureSha = calculateSha256(fixtureBytes);
        expect(
          fixtureSha,
          equals(
            '5316b8b37a5b2d8d1f68f92a3d0ef18b43caa01091b6b694ffb4ec8e62c1a3d9',
          ),
        );

        final h09Case = EscPosHardwareSuite.protocolCases.firstWhere(
          (c) => c.id == 'H09',
        );
        final h09Bytes = h09Case.generator();
        final h09Sha = calculateSha256(h09Bytes);
        expect(h09Sha, equals(h09Case.goldenSha256));
        expect(h09Sha.length, equals(64));
      },
    );

    test('Barcode and QR code cases encode expected payloads', () {
      final h06 = EscPosHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H06',
      );
      expect(h06.expectedPayload, equals('PORTAKAL123456'));

      final h07 = EscPosHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H07',
      );
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });
  });

  group('TSC Diagnostic Probes & Generator Verification', () {
    test('D00-TSC minimal probe generates valid TSPL command stream', () {
      final d00Tsc = TscHardwareSuite.diagnosticCases.firstWhere(
        (c) => c.id == 'D00-TSC',
      );
      final bytes = d00Tsc.generator();
      expect(bytes, isNotEmpty);
      final str = latin1.decode(bytes);
      expect(str, contains('SIZE 800 dot,600 dot\r\n'));
      expect(str, contains('CLS\r\n'));
      expect(str, contains('PORTAKAL TSC TEST'));
      expect(str, contains('PRINT 1\r\n'));
    });

    test('TSC H01 generates ASCII baseline TSPL job', () {
      final h01 = TscHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H01',
      );
      final bytes = h01.generator();
      final str = latin1.decode(bytes);
      expect(str, contains('SIZE 800 dot,600 dot\r\n'));
      expect(str, contains('PORTAKAL 123 ABC xyz'));
      expect(str, contains('PRINT 1\r\n'));
    });

    test('TSC H06 Code128 and H07 QR encode exact payloads', () {
      final h06 = TscHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H06',
      );
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h06Str = latin1.decode(h06.generator());
      expect(
        h06Str,
        contains('BARCODE 50,80,"128",80,1,0,2,4,"PORTAKAL123456"\r\n'),
      );

      final h07 = TscHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H07',
      );
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
      final h07Str = latin1.decode(h07.generator());
      expect(
        h07Str,
        contains(
          'QRCODE 50,80,"M",5,"A",0,"https://example.com/portakal-hw-test"\r\n',
        ),
      );
    });

    test('TSC H09 uses canonical raster bitmap fixture', () {
      final h09 = TscHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H09',
      );
      final bytes = h09.generator();
      expect(bytes.length, greaterThan(512));
      final str = latin1.decode(bytes);
      expect(str, contains('BITMAP 50,80,8,64,0,'));
    });

    test('TSC H10 generates 3 copies in batch', () {
      final h10 = TscHardwareSuite.protocolCases.firstWhere(
        (c) => c.id == 'H10',
      );
      final bytes = h10.generator();
      final str = latin1.decode(bytes);
      expect(str, contains('PRINT 1,3\r\n'));
    });
  });

  group('HardwareValidationPage Widget Tests', () {
    testWidgets('renders diagnostic probes and protocol case sections', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport = MockHardwarePrinterTransport(
        initialPrinters: [
          const DiscoveredPrinter(
            id: 'printer_001',
            name: 'Printer0001-328F',
            connectionType: DiscoveredConnectionType.ble,
            isConnected: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Printer0001-328F',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar and section headers
      expect(find.text('Hardware Validation — ESC/POS'), findsOneWidget);
      expect(find.text('Protocol Selection'), findsOneWidget);
      expect(find.text('Step 1: ESC/POS Diagnostic Probes'), findsOneWidget);
      expect(find.text('Step 2: ESC/POS Validation Suite'), findsOneWidget);

      // Verify diagnostic cases
      expect(find.text('D00'), findsOneWidget);
      expect(find.text('D01'), findsOneWidget);
      expect(find.text('H01-NOCUT'), findsOneWidget);

      // Verify protocol cases
      expect(find.text('H01'), findsOneWidget);
      expect(find.text('H02-CP437'), findsOneWidget);
      expect(find.text('H06'), findsOneWidget);
      expect(find.text('H07'), findsOneWidget);
      expect(find.text('H09'), findsOneWidget);
      expect(find.text('H11'), findsOneWidget);
    });

    testWidgets('switches to TSC protocol and transmits D00-TSC probe', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport = MockHardwarePrinterTransport(
        initialPrinters: [
          const DiscoveredPrinter(
            id: 'tsc_printer',
            name: 'Generic_TSC_203',
            connectionType: DiscoveredConnectionType.ble,
            isConnected: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Generic_TSC_203',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap TSC segmented button
      final tscSegment = find.text('TSC / TSPL2');
      expect(tscSegment, findsOneWidget);
      await tester.tap(tscSegment);
      await tester.pumpAndSettle();

      // Verify header updated
      expect(find.text('Hardware Validation — TSC / TSPL2'), findsOneWidget);
      expect(
        find.text('Step 1: TSC / TSPL2 Diagnostic Probes'),
        findsOneWidget,
      );
      expect(find.text('D00-TSC'), findsOneWidget);
      expect(find.text('H08'), findsOneWidget);
      expect(find.text('H10'), findsOneWidget);

      // Connect
      final connectBtn = find.text('Connect');
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Print D00-TSC
      final printD00Btn = find.text('Print D00-TSC');
      expect(printD00Btn, findsOneWidget);
      await tester.tap(printD00Btn);
      await tester.pumpAndSettle();

      // Verify transmission occurred
      expect(mockTransport.transmittedBytes.length, equals(1));
      final transmittedStr = latin1.decode(
        mockTransport.transmittedBytes.first,
      );
      expect(transmittedStr, contains('PORTAKAL TSC TEST'));
      expect(
        find.text('Active Verification: D00-TSC — Minimal TSC Probe'),
        findsOneWidget,
      );
    });

    testWidgets('transmits D00 probe and shows diagnostics and SENT state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport = MockHardwarePrinterTransport(
        initialPrinters: [
          const DiscoveredPrinter(
            id: 'p1',
            name: 'Printer0001-328F',
            connectionType: DiscoveredConnectionType.ble,
            isConnected: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Printer0001-328F',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Connect
      final connectBtn = find.text('Connect');
      expect(connectBtn, findsOneWidget);
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Print D00
      final printD00Btn = find.text('Print D00');
      expect(printD00Btn, findsOneWidget);
      await tester.tap(printD00Btn);
      await tester.pumpAndSettle();

      // Verify transmitted bytes
      expect(mockTransport.transmittedBytes.length, equals(1));
      final transmitted = mockTransport.transmittedBytes.first;
      expect(transmitted.length, equals(16));

      // Verify Active Verification panel shows D00 diagnostics
      expect(
        find.text('Active Verification: D00 — Pure ASCII Probe'),
        findsOneWidget,
      );
      expect(find.text('Transmission Diagnostics:'), findsOneWidget);
      expect(find.textContaining('SUCCESS'), findsOneWidget);

      // Operator marks PRINTED
      final printedBtn = find.text('PRINTED (Output Seen)');
      expect(printedBtn, findsOneWidget);
      await tester.tap(printedBtn);
      await tester.pumpAndSettle();

      expect(find.text('PRINTED'), findsWidgets);
    });

    testWidgets('marks TRANSPORT ERROR when transport throws exception', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport =
          MockHardwarePrinterTransport(
              initialPrinters: [
                const DiscoveredPrinter(
                  id: 'p1',
                  name: 'Printer0001-328F',
                  connectionType: DiscoveredConnectionType.ble,
                  isConnected: true,
                ),
              ],
            )
            ..simulateTransportFailure = true
            ..failureErrorMessage = 'GATT Error 133: Device disconnected';

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Printer0001-328F',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Print D01
      final printD01Btn = find.text('Print D01');
      await tester.tap(printD01Btn);
      await tester.pumpAndSettle();

      // Verify TRANSPORT ERROR status is assigned
      expect(find.text('TRANSPORT ERROR'), findsWidgets);
      expect(find.textContaining('GATT Error 133'), findsWidgets);
    });

    testWidgets('prompts confirmation dialog before cutter execution', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport = MockHardwarePrinterTransport(
        initialPrinters: [
          const DiscoveredPrinter(
            id: 'p1',
            name: 'Printer0001-328F',
            connectionType: DiscoveredConnectionType.ble,
            isConnected: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Printer0001-328F',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Print H11 button (Cutter)
      final printH11Btn = find.text('Print H11');
      await tester.scrollUntilVisible(
        printH11Btn,
        50,
        scrollable: find.byType(Scrollable).last,
      );
      expect(printH11Btn, findsOneWidget);
      await tester.tap(printH11Btn);
      await tester.pumpAndSettle();

      // Verify Cutter Warning dialog appears
      expect(find.text('Cutter Warning'), findsOneWidget);

      // Tap Proceed with Cut
      final proceedBtn = find.text('Proceed with Cut');
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();

      // Verify transmission occurred
      expect(mockTransport.transmittedBytes.length, equals(1));
    });
  });
}
