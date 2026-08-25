import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'sha256.dart';

/// Supported printer protocols in the hardware validation test bench.
enum ValidationProtocol {
  escpos('escpos', 'ESC/POS', 'Epson ESC/POS thermal receipt protocol'),
  tsc('tsc', 'TSC / TSPL2', 'TSC / TSPL2 label and receipt printer protocol'),
  zpl('zpl', 'ZPL II', 'Zebra Programming Language II label protocol'),
  epl('epl', 'EPL2', 'Eltron Programming Language 2 page-mode protocol'),
  cpcl('cpcl', 'CPCL', 'Comtec / Zebra Mobile receipt & label protocol'),
  dpl('dpl', 'DPL', 'Datamax Programming Language protocol'),
  ipl('ipl', 'IPL', 'Intermec Printer Language protocol (F90-F99 formats)'),
  sbpl('sbpl', 'SBPL', 'SATO Barcode Printer Language protocol'),
  star(
    'star',
    'Star Line / PRNT',
    'Star Micronics Line Mode raster & text protocol',
  );

  final String id;
  final String displayName;
  final String description;

  const ValidationProtocol(this.id, this.displayName, this.description);
}

/// Category of verification performed by a test case.
enum ValidationKind {
  text,
  encoding,
  barcode,
  qr,
  raster,
  drawing,
  copies,
  cut,
  initialize,
  rawCommand,
  lifecycle,
}

/// Verification status for a test case execution.
enum CaseResultStatus {
  notTested('N/T', Colors.grey),
  connecting('CONNECTING', Colors.purple),
  sending('SENDING', Colors.amber),
  sent('SENT', Colors.blue),
  transportError('TRANSPORT ERROR', Colors.red),
  printed('PRINTED', Colors.teal),
  pass('PASS', Colors.green),
  partial('PARTIAL', Colors.orange),
  fail('FAIL', Colors.redAccent),
  notSupportedDevice('N/S-DEVICE', Colors.indigo),
  notSupportedSdk('N/S-SDK', Colors.deepPurple);

  final String label;
  final Color color;
  const CaseResultStatus(this.label, this.color);
}

/// Shared test case definition model for all protocol test suites.
class HardwareValidationCase {
  final String id;
  final String title;
  final String description;
  final bool isDiagnostic;
  final bool isSupportedInSdk;
  final String? unsupportedSdkReason;
  final bool requiresCutter;
  final bool requiresScanner;
  final String? expectedPayload;
  final ValidationKind validationKind;
  final Uint8List Function() generator;

  const HardwareValidationCase({
    required this.id,
    required this.title,
    required this.description,
    this.isDiagnostic = false,
    this.isSupportedInSdk = true,
    this.unsupportedSdkReason,
    this.requiresCutter = false,
    this.requiresScanner = false,
    this.expectedPayload,
    this.validationKind = ValidationKind.text,
    required this.generator,
  });

  /// Deterministic expected golden SHA-256 computed from [generator].
  String get goldenSha256 =>
      isSupportedInSdk ? calculateSha256(generator()) : 'N/A';
}

/// Contract for a protocol validation suite.
abstract interface class ProtocolValidationSuite {
  ValidationProtocol get protocol;
  String get displayName;
  String get description;
  String? get warning;
  String get capabilityProbeCaseId;
  List<HardwareValidationCase> get cases;
}
