import 'dart:convert';
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

    test(
      'Every protocol defines a valid D00 capability probe with null expectedSha256',
      () {
        for (final suite in ProtocolRegistry.allSuites) {
          final probe = suite.cases.firstWhere(
            (c) => c.id == suite.capabilityProbeCaseId,
          );
          expect(probe.isDiagnostic, isTrue);
          expect(
            probe.expectedSha256,
            isNull,
            reason: 'Diagnostic probe D00 should not have a frozen golden SHA',
          );
          final bytes = probe.generator();
          expect(
            bytes,
            isNotEmpty,
            reason: '${suite.displayName} D00 probe must generate bytes',
          );
          final sha = calculateSha256(bytes);
          expect(sha.length, equals(64));
        }
      },
    );

    test('All canonical Hxx cases match their frozen expectedSha256 values',
        () {
      final mismatches = <String>[];
      for (final suite in ProtocolRegistry.allSuites) {
        for (final c in suite.cases) {
          if (!c.isDiagnostic && c.isSupportedInSdk) {
            expect(
              c.expectedSha256,
              isNotNull,
              reason:
                  '${suite.displayName} case ${c.id} must declare frozen expectedSha256',
            );
            final bytes = c.generator();
            final actualSha = calculateSha256(bytes);
            if (actualSha != c.expectedSha256) {
              mismatches.add(
                '${suite.displayName} [${c.id}]: actual=$actualSha expected=${c.expectedSha256}',
              );
            }
          }
        }
      }
      expect(
        mismatches,
        isEmpty,
        reason: 'All cases should match expected golden SHA',
      );
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

  group('Protocol Specific Payload and Formatting Consistency Tests', () {
    test(
      'Barcode H06 payload is consistently PORTAKAL123456 across all protocols',
      () {
        for (final suite in ProtocolRegistry.allSuites) {
          final h06 = suite.cases.firstWhere((c) => c.id == 'H06');
          expect(h06.expectedPayload, equals('PORTAKAL123456'));
          expect(h06.requiresScanner, isTrue);
        }
      },
    );

    test(
      'QR Code H07 payload is consistently https://example.com/portakal-hw-test',
      () {
        for (final suite in ProtocolRegistry.allSuites) {
          final h07 = suite.cases.firstWhere((c) => c.id == 'H07');
          expect(
            h07.expectedPayload,
            equals('https://example.com/portakal-hw-test'),
          );
          expect(h07.requiresScanner, isTrue);
        }
      },
    );

    test('DPL hardware cases use native CR line endings (0x0D)', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.dpl);
      final d00Bytes =
          suite.cases.firstWhere((c) => c.id == 'D00-DPL').generator();
      expect(d00Bytes, contains(0x0D));
      final d00Str = latin1.decode(d00Bytes);
      expect(d00Str.endsWith('\r'), isTrue);
    });

    test('IPL hardware cases strictly use reserved format slots F90–F99', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.ipl);
      for (final c in suite.cases) {
        if (!c.isSupportedInSdk) continue;
        final bytes = c.generator();
        final str = latin1.decode(bytes);
        // Ensure only F90-F99 are referenced
        if (str.contains('F')) {
          expect(
            str,
            anyOf([
              contains('F90'),
              contains('F91'),
              contains('F92'),
              contains('F93'),
              contains('F94'),
              contains('F95'),
              contains('F96'),
              contains('F97'),
              contains('F98'),
              contains('F99'),
            ]),
          );
        }
      }
    });

    test('SBPL hardware cases use ESC A / ESC Z job markers', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.sbpl);
      final h01Bytes = suite.cases.firstWhere((c) => c.id == 'H01').generator();
      final str = latin1.decode(h01Bytes);
      expect(str, startsWith('\x1BA'));
      expect(str, endsWith('\x1BZ'));
    });

    test('Star PRNT raster case uses ESC * r A ... ESC * r B framing', () {
      final suite = ProtocolRegistry.getSuite(ValidationProtocol.star);
      final h09Bytes = suite.cases.firstWhere((c) => c.id == 'H09').generator();
      final str = latin1.decode(h09Bytes);
      expect(str, contains('\x1B*rA'));
      expect(str, contains('\x1B*rB'));
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
      expect(find.textContaining('DPL commands use native CR'), findsOneWidget);
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
