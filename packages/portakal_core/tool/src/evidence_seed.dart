import 'dart:convert';

/// Generates deterministic evidence seed JSON manifest for a generated hardware test case.
String generateEvidenceSeedJson({
  required String protocol,
  required String caseId,
  required String description,
  required String builderName,
  required String binFilename,
  required String hexFilename,
  required String sha256,
  required int byteCount,
  String? expectedPayload,
  String sdkVersion = '0.3.0',
}) {
  final manifest = <String, dynamic>{
    'schema_version': 1,
    'protocol': protocol,
    'case_id': caseId,
    'description': description,
    'sdk': {
      'package': 'portakal_core',
      'version': sdkVersion,
      'builder': builderName,
    },
    'artifact': {
      'bin': binFilename,
      'hex': hexFilename,
      'sha256': sha256,
      'byte_count': byteCount,
    },
    if (expectedPayload != null) 'expected': {'payload': expectedPayload},
    'hardware': {
      'manufacturer': null,
      'model': null,
      'firmware': null,
      'command_mode': null,
    },
    'result': {'level2': 'N/T', 'level3': 'N/T', 'simulator': 'N/T'},
  };

  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(manifest)}\n';
}
