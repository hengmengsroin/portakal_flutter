import 'dart:convert';
import 'dart:io';

import 'src/case_registry.dart';
import 'src/evidence_seed.dart';
import 'src/hex_formatter.dart';
import 'src/sha256.dart';

void main(List<String> args) {
  String? protocol;
  String? caseId;
  bool isAll = false;
  bool isList = false;
  String outputDir = './out';
  String versionLabel = '0.3.0';

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      _printUsage();
      exit(0);
    } else if (arg == '-p' || arg == '--protocol') {
      if (i + 1 < args.length) {
        protocol = args[++i].toLowerCase();
      }
    } else if (arg == '-c' || arg == '--case') {
      if (i + 1 < args.length) {
        caseId = args[++i].toUpperCase();
      }
    } else if (arg == '-a' || arg == '--all') {
      isAll = true;
    } else if (arg == '-l' || arg == '--list') {
      isList = true;
    } else if (arg == '-o' || arg == '--output') {
      if (i + 1 < args.length) {
        outputDir = args[++i];
      }
    } else if (arg == '-v' || arg == '--version-label') {
      if (i + 1 < args.length) {
        versionLabel = args[++i];
      }
    }
  }

  // Handle --list
  if (isList) {
    _handleList(protocol);
    return;
  }

  if (protocol == null) {
    stderr.writeln('Error: Missing required argument --protocol <name>.');
    stderr.writeln(
      'Valid protocols: ${CaseRegistry.supportedProtocols.join(', ')}',
    );
    stderr.writeln('Run with --help for usage.');
    exit(64);
  }

  if (!CaseRegistry.supportedProtocols.contains(protocol)) {
    stderr.writeln('Error: Unknown protocol "$protocol".');
    stderr.writeln(
      'Valid protocols: ${CaseRegistry.supportedProtocols.join(', ')}',
    );
    exit(64);
  }

  if (!isAll && caseId == null) {
    stderr.writeln('Error: Must specify either --case <id> or --all.');
    stderr.writeln('Use --list to view available cases for $protocol.');
    exit(64);
  }

  final cases = CaseRegistry.getCasesForProtocol(protocol);

  if (caseId != null) {
    final targetCase = CaseRegistry.getCase(protocol, caseId);
    if (targetCase == null) {
      stderr.writeln('Error: Unknown case "$caseId" for protocol "$protocol".');
      stderr.writeln('Use --list to view available cases.');
      exit(1);
    }

    if (!targetCase.isSupported) {
      stderr.writeln(
        'Error: Case "$caseId" is NOT SUPPORTED for protocol "$protocol".',
      );
      if (targetCase.statusReason != null) {
        stderr.writeln('Reason: ${targetCase.statusReason}');
      }
      exit(1);
    }

    _generateCaseArtifacts(
      definition: targetCase,
      outputDir: outputDir,
      versionLabel: versionLabel,
    );
    stdout.writeln(
      'Successfully generated artifacts for [$protocol] case ${targetCase.id} in $outputDir',
    );
  } else if (isAll) {
    final protocolOutDir =
        outputDir.endsWith(protocol) ? outputDir : '$outputDir/$protocol';
    final manifestEntries = <Map<String, dynamic>>[];

    int generatedCount = 0;
    int skippedCount = 0;

    for (final def in cases) {
      if (!def.isSupported) {
        skippedCount++;
        manifestEntries.add({
          'case_id': def.id,
          'description': def.description,
          'status': 'N/S-SDK',
          'reason': def.statusReason,
          'generated': false,
        });
        continue;
      }

      final result = _generateCaseArtifacts(
        definition: def,
        outputDir: protocolOutDir,
        versionLabel: versionLabel,
      );
      generatedCount++;

      manifestEntries.add({
        'case_id': def.id,
        'description': def.description,
        'status': 'SUPPORTED',
        'generated': true,
        'sha256': result.sha256,
        'byte_count': result.byteCount,
        'bin_file': '${def.id}.bin',
        'hex_file': '${def.id}.hex',
        'json_file': '${def.id}.json',
      });
    }

    // Write manifest.json
    final manifestPath = '$protocolOutDir/manifest.json';
    final manifestContent = {
      'schema_version': 1,
      'protocol': protocol,
      'sdk_version': versionLabel,
      'total_cases': cases.length,
      'generated_count': generatedCount,
      'unsupported_count': skippedCount,
      'cases': manifestEntries,
    };
    File(manifestPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifestContent)}\n',
    );

    stdout.writeln(
      'Successfully generated $generatedCount cases for [$protocol] in $protocolOutDir (skipped $skippedCount unsupported).',
    );
    stdout.writeln('Manifest written to $manifestPath');
  }
}

class _GenResult {
  final String sha256;
  final int byteCount;
  const _GenResult(this.sha256, this.byteCount);
}

_GenResult _generateCaseArtifacts({
  required HardwareCaseDefinition definition,
  required String outputDir,
  required String versionLabel,
}) {
  final dir = Directory(outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final bytes = definition.generator();
  final sha256 = calculateSha256(bytes);
  final hexDump = formatHexDump(bytes);

  final binFilename = '${definition.id}.bin';
  final hexFilename = '${definition.id}.hex';
  final jsonFilename = '${definition.id}.json';

  final jsonManifest = generateEvidenceSeedJson(
    protocol: definition.protocol,
    caseId: definition.id,
    description: definition.description,
    builderName: definition.builderName,
    binFilename: binFilename,
    hexFilename: hexFilename,
    sha256: sha256,
    byteCount: bytes.length,
    expectedPayload: definition.expectedPayload,
    sdkVersion: versionLabel,
  );

  File('$outputDir/$binFilename').writeAsBytesSync(bytes);
  File('$outputDir/$hexFilename').writeAsStringSync(hexDump);
  File('$outputDir/$jsonFilename').writeAsStringSync(jsonManifest);

  return _GenResult(sha256, bytes.length);
}

void _handleList(String? protocol) {
  final protocolsToList =
      (protocol != null) ? [protocol] : CaseRegistry.supportedProtocols;

  for (final proto in protocolsToList) {
    stdout.writeln(
      '================================================================',
    );
    stdout.writeln('Protocol: $proto');
    stdout.writeln(
      '================================================================',
    );
    stdout.writeln(
      '${'CASE ID'.padRight(14)} ${'DESCRIPTION'.padRight(42)} ${'STATUS'}',
    );
    stdout.writeln(
      '----------------------------------------------------------------',
    );

    final cases = CaseRegistry.getCasesForProtocol(proto);
    for (final c in cases) {
      final statusStr = c.isSupported
          ? 'SUPPORTED'
          : (c.status == SupportStatus.notSupportedSdk
              ? 'N/S-SDK'
              : 'N/S-DEVICE');
      stdout.writeln(
        '${c.id.padRight(14)} ${c.description.padRight(42)} $statusStr',
      );
    }
    stdout.writeln();
  }
}

void _printUsage() {
  stdout.writeln('''
Portakal Hardware Validation Case Generator

USAGE:
  dart run tool/hardware_cases.dart --protocol <proto> --case <id> --output <dir>
  dart run tool/hardware_cases.dart --protocol <proto> --all --output <dir>
  dart run tool/hardware_cases.dart --list [--protocol <proto>]

OPTIONS:
  -p, --protocol <name>       Target protocol identifier (tsc, escpos, zpl, epl, cpcl, dpl, ipl, sbpl, star)
  -c, --case <id>             Specific test case ID (e.g. H01, H02-CP437, H07, H09)
  -a, --all                   Generate all supported cases for specified protocol
  -l, --list                  List registered test cases and support status
  -o, --output <dir>          Output directory (default: ./out)
  -v, --version-label <ver>   SDK version label for manifests (default: 0.3.0)
  -h, --help                  Show this help message

SAFETY CONTROLS:
  - No network sockets or serial ports are opened (transport is isolated).
  - IPL hardware cases are strictly constrained to reserved format slots F90–F99.
  - Cash drawer pulses are excluded from default automated test runs.
''');
}
