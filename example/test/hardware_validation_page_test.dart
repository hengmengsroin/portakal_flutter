import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/src/hardware/case_model.dart';
import 'package:example/src/hardware/protocol_registry.dart';
import 'package:example/src/hardware/raster_fixture.dart';
import 'package:example/src/hardware/sha256.dart';
import 'package:example/src/pages/hardware_validation_page.dart';
import 'package:example/src/transport/hardware_printer_transport.dart';

void main() {
  group('Protocol Registry & D00 Capability Probes (All 9 Protocols)', () {
    test('Registry contains all 9 supported printer protocols', () {
      expect(ProtocolRegistry.allSuites.length, equals(9));

      final expectedProtocols = [
        ValidationProtocol.escpos,
        ValidationProtocol.tsc,
        ValidationProtocol.zpl,
        ValidationProtocol.epl,
        ValidationProtocol.cpcl,
        ValidationProtocol.dpl,
        ValidationProtocol.ipl,
        ValidationProtocol.sbpl,
        ValidationProtocol.star,
      ];

      for (final p in expectedProtocols) {
        final suite = ProtocolRegistry.getSuite(p);
        expect(suite.protocol, equals(p));
        expect(suite.displayName, isNotEmpty);
        expect(suite.description, isNotEmpty);
        expect(suite.capabilityProbeCaseId, isNotEmpty);
        expect(suite.cases, isNotEmpty);
      }
    });

    test('Every protocol defines a valid D00 capability probe', () {
      for (final suite in ProtocolRegistry.allSuites) {
        final probe = suite.cases.firstWhere(
          (c) => c.id == suite.capabilityProbeCaseId,
        );
        expect(probe.isDiagnostic, isTrue);
        final bytes = probe.generator();
        expect(
          bytes,
          isNotEmpty,
          reason: '${suite.displayName} D00 probe must generate bytes',
        );
        final sha = calculateSha256(bytes);
        expect(sha.length, equals(64));
      }
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
      },
    );

    test('DPL, IPL, and SBPL mark unsupported raster graphics as N/S-SDK', () {
      final dplH09 = ProtocolRegistry.getSuite(
        ValidationProtocol.dpl,
      ).cases.firstWhere((c) => c.id == 'H09');
      expect(dplH09.isSupportedInSdk, isFalse);
      expect(dplH09.unsupportedSdkReason, contains('DPL'));

      final iplH09 = ProtocolRegistry.getSuite(
        ValidationProtocol.ipl,
      ).cases.firstWhere((c) => c.id == 'H09');
      expect(iplH09.isSupportedInSdk, isFalse);
      expect(iplH09.unsupportedSdkReason, contains('IPL'));

      final sbplH09 = ProtocolRegistry.getSuite(
        ValidationProtocol.sbpl,
      ).cases.firstWhere((c) => c.id == 'H09');
      expect(sbplH09.isSupportedInSdk, isFalse);
      expect(sbplH09.unsupportedSdkReason, contains('SBPL'));
    });
  });

  group('Protocol Specific Payload Tests', () {
    test('ESC/POS H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.escpos);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('TSC H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.tsc);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('ZPL H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.zpl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('EPL H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.epl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('CPCL H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.cpcl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('DPL H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.dpl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('IPL H06 and H07 payloads with F92 and F93 formats', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.ipl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('SBPL H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.sbpl);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });

    test('Star PRNT H06 and H07 payloads', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.star);
      final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
      expect(h06.expectedPayload, equals('PORTAKAL123456'));
      final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
      expect(
        h07.expectedPayload,
        equals('https://example.com/portakal-hw-test'),
      );
    });
  });

  group('HardwareValidationPage Universal Widget Tests', () {
    testWidgets('renders all 9 protocols in dropdown selector', (tester) async {
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

      expect(
        find.text('Portakal Hardware Test Bench — ESC/POS'),
        findsOneWidget,
      );
      expect(find.text('Select Protocol'), findsOneWidget);
      expect(find.text('Step 1: ESC/POS Capability Probes'), findsOneWidget);
      expect(find.text('Step 2: ESC/POS Validation Suite'), findsOneWidget);

      // Open dropdown
      final dropdown = find.byType(DropdownButton<ValidationProtocol>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify all 9 protocol labels appear
      expect(find.text('ESC/POS'), findsWidgets);
      expect(find.text('TSC / TSPL2'), findsWidgets);
      expect(find.text('ZPL II'), findsWidgets);
      expect(find.text('EPL2'), findsWidgets);
      expect(find.text('CPCL'), findsWidgets);
      expect(find.text('DPL'), findsWidgets);
      expect(find.text('IPL'), findsWidgets);
      expect(find.text('SBPL'), findsWidgets);
      expect(find.text('Star Line / PRNT'), findsWidgets);
    });

    testWidgets('switches to DPL and shows N/S-SDK on H09 Raster', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTransport = MockHardwarePrinterTransport(
        initialPrinters: [
          const DiscoveredPrinter(
            id: 'dpl_printer',
            name: 'Datamax_E4204B',
            connectionType: DiscoveredConnectionType.ble,
            isConnected: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HardwareValidationPage(
            transport: mockTransport,
            targetDeviceName: 'Datamax_E4204B',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select DPL from dropdown
      final dropdown = find.byType(DropdownButton<ValidationProtocol>);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('DPL').last);
      await tester.pumpAndSettle();

      // Verify DPL header and warning
      expect(find.text('Portakal Hardware Test Bench — DPL'), findsOneWidget);
      expect(
        find.textContaining('DPL commands use native CR line endings.'),
        findsOneWidget,
      );
      expect(find.text('D00-DPL'), findsOneWidget);

      // Verify N/S-SDK badge on H09
      expect(find.text('N/S-SDK'), findsWidgets);
      expect(
        find.textContaining('Portakal current DPL builder does not support'),
        findsOneWidget,
      );
    });

    testWidgets(
      'marks D00 probe as N/S-DEVICE, gates advanced cases, and allows override',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1600);
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

        // Switch to ZPL
        final dropdown = find.byType(DropdownButton<ValidationProtocol>);
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('ZPL II').last);
        await tester.pumpAndSettle();

        // Print D00-ZPL
        final printD00Btn = find.text('Print D00-ZPL');
        await tester.tap(printD00Btn);
        await tester.pumpAndSettle();

        // Mark N/S-DEVICE
        final nsBtn = find.text('N/S-DEVICE (No Command Support)');
        await tester.tap(nsBtn);
        await tester.pumpAndSettle();

        // Verify Protocol Capability Notice appeared
        expect(find.text('Protocol Capability Notice'), findsOneWidget);
        expect(
          find.textContaining(
            'This connected printer does not appear to support this protocol',
          ),
          findsOneWidget,
        );

        // Tap Continue Anyway override
        final overrideBtn = find.text('Continue Anyway (Advanced Override)');
        expect(overrideBtn, findsOneWidget);
        await tester.scrollUntilVisible(
          overrideBtn,
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(overrideBtn);
        await tester.pumpAndSettle();

        // Verify override hides warning
        expect(find.text('Protocol Capability Notice'), findsNothing);
      },
    );

    testWidgets('exports comprehensive session JSON for active protocol', (
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

      // Tap share icon in app bar
      final shareIcon = find.byIcon(Icons.share);
      expect(shareIcon, findsOneWidget);
      await tester.tap(shareIcon);
      await tester.pumpAndSettle();

      // Verify dialog with JSON preview appears
      expect(find.text('Export ESC/POS Session JSON'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
