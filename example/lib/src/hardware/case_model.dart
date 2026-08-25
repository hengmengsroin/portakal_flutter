import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Supported printer protocols in the hardware validation test bench.
enum ValidationProtocol {
  escpos('escpos', 'ESC/POS', 'ESC/POS-compatible receipt command set'),
  tsc(
    'tsc',
    'TSC / TSPL2',
    'TSC / TSPL2-compatible label and receipt command set',
  ),
  zpl('zpl', 'ZPL II', 'ZPL II-compatible label command set'),
  epl('epl', 'EPL2', 'EPL2-compatible page-mode command set'),
  cpcl('cpcl', 'CPCL', 'CPCL-compatible mobile receipt & label command set'),
  dpl('dpl', 'DPL', 'DPL-compatible command set (native CR line endings)'),
  ipl(
    'ipl',
    'IPL',
    'IPL-compatible command set (reserved F90-F99 format slots)',
  ),
  sbpl(
    'sbpl',
    'SBPL',
    'SBPL-compatible command set (ESC A / ESC Z job framing)',
  ),
  star(
    'star',
    'Star Line / PRNT',
    'Star Line Mode / supported Star PRNT subset',
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
  final String? expectedSha256;
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
    this.expectedSha256,
    required this.generator,
  });
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
