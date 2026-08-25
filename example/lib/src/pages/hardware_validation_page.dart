import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../hardware/escpos_hardware_cases.dart';
import '../hardware/sha256.dart';
import '../hardware/tsc_hardware_cases.dart';
import '../transport/hardware_printer_transport.dart';

/// Test execution and diagnostic status for each validation case.
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
  notSupportedDevice('N/S-DEVICE', Colors.indigo);

  final String label;
  final Color color;
  const CaseResultStatus(this.label, this.color);
}

/// Generic container for a validation case from any protocol.
class GenericCaseDefinition {
  final String id;
  final String title;
  final String description;
  final String? expectedPayload;
  final bool isDiagnostic;
  final bool requiresCutter;
  final String goldenSha256;
  final Uint8List Function() generator;

  const GenericCaseDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.expectedPayload,
    this.isDiagnostic = false,
    this.requiresCutter = false,
    required this.goldenSha256,
    required this.generator,
  });

  factory GenericCaseDefinition.fromEscPos(EscPosValidationCase c) {
    return GenericCaseDefinition(
      id: c.id,
      title: c.title,
      description: c.description,
      expectedPayload: c.expectedPayload,
      isDiagnostic: c.isDiagnostic,
      requiresCutter: c.requiresCutter,
      goldenSha256: c.goldenSha256,
      generator: c.generator,
    );
  }

  factory GenericCaseDefinition.fromTsc(TscValidationCase c) {
    return GenericCaseDefinition(
      id: c.id,
      title: c.title,
      description: c.description,
      expectedPayload: c.expectedPayload,
      isDiagnostic: c.isDiagnostic,
      requiresCutter: false,
      goldenSha256: c.goldenSha256,
      generator: c.generator,
    );
  }
}

/// Recorded validation run details for a single test case.
class CaseExecutionRecord {
  final GenericCaseDefinition testCase;
  final Uint8List? generatedBytes;
  final String? generatedSha256;
  final bool? isGoldenMatch;
  CaseResultStatus status;
  WriteDiagnosticInfo? diagnosticInfo;
  String? scannedPayload;
  String? notes;
  DateTime? executedAt;

  CaseExecutionRecord({
    required this.testCase,
    this.generatedBytes,
    this.generatedSha256,
    this.isGoldenMatch,
    this.status = CaseResultStatus.notTested,
    this.diagnosticInfo,
    this.scannedPayload,
    this.notes,
    this.executedAt,
  });
}

enum HardwareProtocol {
  escpos('ESC/POS'),
  tsc('TSC / TSPL2');

  final String label;
  const HardwareProtocol(this.label);
}

/// Interactive Hardware Validation Screen supporting ESC/POS and TSC Protocols.
class HardwareValidationPage extends StatefulWidget {
  final HardwarePrinterTransport transport;
  final String targetDeviceName;

  const HardwareValidationPage({
    super.key,
    required this.transport,
    this.targetDeviceName = 'Printer0001-328F',
  });

  @override
  State<HardwareValidationPage> createState() => _HardwareValidationPageState();
}

class _HardwareValidationPageState extends State<HardwareValidationPage> {
  HardwareProtocol _activeProtocol = HardwareProtocol.escpos;

  final List<DiscoveredPrinter> _discoveredPrinters = [];
  DiscoveredPrinter? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';

  final Map<String, CaseExecutionRecord> _escposRecords = {};
  final Map<String, CaseExecutionRecord> _tscRecords = {};
  CaseExecutionRecord? _lastActiveRecord;

  final TextEditingController _scanInputController = TextEditingController();

  Map<String, CaseExecutionRecord> get _currentRecords =>
      _activeProtocol == HardwareProtocol.escpos ? _escposRecords : _tscRecords;

  List<GenericCaseDefinition> get _currentDiagnosticCases {
    if (_activeProtocol == HardwareProtocol.escpos) {
      return EscPosHardwareSuite.diagnosticCases
          .map(GenericCaseDefinition.fromEscPos)
          .toList();
    } else {
      return TscHardwareSuite.diagnosticCases
          .map(GenericCaseDefinition.fromTsc)
          .toList();
    }
  }

  List<GenericCaseDefinition> get _currentProtocolCases {
    if (_activeProtocol == HardwareProtocol.escpos) {
      return EscPosHardwareSuite.protocolCases
          .map(GenericCaseDefinition.fromEscPos)
          .toList();
    } else {
      return TscHardwareSuite.protocolCases
          .map(GenericCaseDefinition.fromTsc)
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize session records for all defined cases
    for (final c in EscPosHardwareSuite.allCases) {
      final gen = GenericCaseDefinition.fromEscPos(c);
      _escposRecords[c.id] = CaseExecutionRecord(testCase: gen);
    }
    for (final c in TscHardwareSuite.allCases) {
      final gen = GenericCaseDefinition.fromTsc(c);
      _tscRecords[c.id] = CaseExecutionRecord(testCase: gen);
    }

    widget.transport.printersStream.listen((printers) {
      if (!mounted) return;
      setState(() {
        _discoveredPrinters
          ..clear()
          ..addAll(printers);

        if (_selectedPrinter == null) {
          for (final p in _discoveredPrinters) {
            if (p.name.contains(widget.targetDeviceName)) {
              _selectedPrinter = p;
              if (p.isConnected) _connectionStatus = 'Connected';
              break;
            }
          }
        } else {
          final updated = _discoveredPrinters.firstWhere(
            (p) => p.id == _selectedPrinter!.id,
            orElse: () => _selectedPrinter!,
          );
          _selectedPrinter = updated;
          if (updated.isConnected) {
            _connectionStatus = 'Connected';
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _scanInputController.dispose();
    widget.transport.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _connectionStatus = 'Scanning';
    });
    try {
      await widget.transport.startScan();
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectionStatus = 'Scan Error: $e');
    }
  }

  Future<void> _stopScan() async {
    await widget.transport.stopScan();
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      if (_selectedPrinter == null || !_selectedPrinter!.isConnected) {
        _connectionStatus = 'Disconnected';
      }
    });
  }

  Future<void> _toggleConnect(DiscoveredPrinter printer) async {
    if (printer.isConnected) {
      setState(() => _connectionStatus = 'Disconnecting');
      await widget.transport.disconnect(printer);
      if (!mounted) return;
      setState(() {
        _selectedPrinter = printer.copyWith(isConnected: false);
        _connectionStatus = 'Disconnected';
      });
    } else {
      setState(() {
        _isConnecting = true;
        _connectionStatus = 'Connecting';
      });
      final ok = await widget.transport.connect(printer);
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        if (ok) {
          _selectedPrinter = printer.copyWith(isConnected: true);
          _connectionStatus = 'Connected';
        } else {
          _connectionStatus = 'Connection Failed';
        }
      });
    }
  }

  Future<void> _executeCase(GenericCaseDefinition c) async {
    if (_selectedPrinter == null || !_selectedPrinter!.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to a printer first.')),
      );
      return;
    }

    if (c.requiresCutter) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cutter Warning'),
          content: const Text(
            'This test will activate the printer cutter.\n\n'
            'Ensure the paper path is clear. If this device lacks a cutter, '
            'you may mark the result as N/S-DEVICE.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed with Cut'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // 1. Generate exact binary command stream from Portakal
    final bytes = c.generator();
    final sha = calculateSha256(bytes);
    final isMatch = sha.toLowerCase() == c.goldenSha256.toLowerCase();

    setState(() {
      _currentRecords[c.id]?.status = CaseResultStatus.sending;
    });

    // 2. Transmit raw bytes directly over transport and record diagnostics
    final diag = await widget.transport.write(_selectedPrinter!, bytes);

    final record = CaseExecutionRecord(
      testCase: c,
      generatedBytes: bytes,
      generatedSha256: sha,
      isGoldenMatch: isMatch,
      status: diag.isSuccess
          ? CaseResultStatus.sent
          : CaseResultStatus.transportError,
      diagnosticInfo: diag,
      executedAt: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _currentRecords[c.id] = record;
      _lastActiveRecord = record;
      _scanInputController.clear();
    });

    if (!diag.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[800],
          content: Text(
            'Transport Error (${diag.exceptionType}): ${diag.exceptionMessage}',
          ),
        ),
      );
    }
  }

  void _updateActiveResult(CaseResultStatus status) {
    if (_lastActiveRecord == null) return;
    setState(() {
      _lastActiveRecord!.status = status;
      _currentRecords[_lastActiveRecord!.testCase.id] = _lastActiveRecord!;
    });
  }

  void _showSessionExportDialog() {
    final sessionMap = {
      'timestamp': DateTime.now().toIso8601String(),
      'protocol': _activeProtocol.name.toUpperCase(),
      'device': {
        'display_name': _selectedPrinter?.name ?? 'Unknown',
        'connection_type':
            _selectedPrinter?.connectionType.name.toUpperCase() ?? 'UNKNOWN',
        'status': _connectionStatus,
      },
      'results': _currentRecords.values.map((r) {
        return {
          'case_id': r.testCase.id,
          'title': r.testCase.title,
          'is_diagnostic': r.testCase.isDiagnostic,
          'byte_count': r.generatedBytes?.length ?? 0,
          'sha256': r.generatedSha256,
          'golden_match': r.isGoldenMatch,
          'status': r.status.label,
          'diagnostics': r.diagnosticInfo != null
              ? {
                  'is_success': r.diagnosticInfo!.isSuccess,
                  'duration_ms': r.diagnosticInfo!.duration.inMilliseconds,
                  'hex_preview': r.diagnosticInfo!.hexPreview,
                  'exception_type': r.diagnosticInfo!.exceptionType,
                  'exception_message': r.diagnosticInfo!.exceptionMessage,
                }
              : null,
          'scanned_payload': r.scannedPayload,
          'notes': r.notes,
        };
      }).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(sessionMap);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export ${_activeProtocol.label} Session JSON'),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
            child: const Text('Copy JSON'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _selectedPrinter?.isConnected ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hardware Validation — ${_activeProtocol.label}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export Session JSON',
            onPressed: _showSessionExportDialog,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Discovery, Protocol Selector & Device Status
          SizedBox(
            width: 330,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protocol Selection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<HardwareProtocol>(
                      segments: const [
                        ButtonSegment(
                          value: HardwareProtocol.escpos,
                          label: Text('ESC/POS'),
                        ),
                        ButtonSegment(
                          value: HardwareProtocol.tsc,
                          label: Text('TSC / TSPL2'),
                        ),
                      ],
                      selected: {_activeProtocol},
                      onSelectionChanged: (val) {
                        setState(() {
                          _activeProtocol = val.first;
                          _lastActiveRecord = null;
                        });
                      },
                    ),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Printer Discovery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isScanning)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isScanning ? _stopScan : _startScan,
                          icon: Icon(_isScanning ? Icons.stop : Icons.search),
                          label: Text(_isScanning ? 'Stop' : 'Scan Bluetooth'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Flexible(
                          child: Text(
                            _connectionStatus,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isConnected
                                  ? Colors.green
                                  : _isConnecting
                                  ? Colors.orange
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Detected Printers:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _discoveredPrinters.isEmpty
                          ? Center(
                              child: Text(
                                _isScanning
                                    ? 'Scanning for BLE/USB devices...'
                                    : 'No printers detected. Click Scan.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _discoveredPrinters.length,
                              itemBuilder: (context, idx) {
                                final p = _discoveredPrinters[idx];
                                final isTarget = p.name.contains(
                                  widget.targetDeviceName,
                                );
                                final isSelected = _selectedPrinter?.id == p.id;

                                return Card(
                                  color: isSelected
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : (isTarget
                                            ? Colors.amber.withValues(
                                                alpha: 0.15,
                                              )
                                            : null),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      p.name,
                                      style: TextStyle(
                                        fontWeight: isTarget
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${p.connectionType.name.toUpperCase()} • ${p.isConnected ? "Connected" : "Disconnected"}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: _isConnecting
                                          ? null
                                          : () => _toggleConnect(p),
                                      child: Text(
                                        p.isConnected
                                            ? 'Disconnect'
                                            : 'Connect',
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() => _selectedPrinter = p);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Pane: Diagnostics & Cases
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Transmission Banner with Full Diagnostics
                  if (_lastActiveRecord != null)
                    _buildActiveVerificationPanel(),

                  const SizedBox(height: 12),
                  Text(
                    'Step 1: ${_activeProtocol.label} Diagnostic Probes',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Establish that raw bytes physically reach and print on the device.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Diagnostic Cases Grid
                  _buildCaseGrid(_currentDiagnosticCases, isConnected),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    'Step 2: ${_activeProtocol.label} Validation Suite',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Execute full protocol feature cases against the connected hardware.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Protocol Cases Grid
                  _buildCaseGrid(_currentProtocolCases, isConnected),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseGrid(List<GenericCaseDefinition> cases, bool isConnected) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cases.map((c) {
        final record = _currentRecords[c.id];
        final status = record?.status ?? CaseResultStatus.notTested;

        return SizedBox(
          width: 270,
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Chip(
                        label: Text(
                          status.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: status.color,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.description,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isConnected ? () => _executeCase(c) : null,
                      icon: const Icon(Icons.print, size: 16),
                      label: Text('Print ${c.id}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveVerificationPanel() {
    final record = _lastActiveRecord!;
    final c = record.testCase;
    final isGolden = record.isGoldenMatch ?? false;
    final diag = record.diagnosticInfo;

    return Card(
      color: record.status == CaseResultStatus.transportError
          ? Colors.red.withValues(alpha: 0.05)
          : Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: record.status == CaseResultStatus.transportError
              ? Colors.red
              : Colors.blue,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Active Verification: ${c.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isGolden ? 'Golden: MATCH' : 'Golden: DIFFERENT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: isGolden ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Diagnostic Transmission Details Table
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transmission Diagnostics:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Protocol: ${_activeProtocol.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• Target Device: ${_selectedPrinter?.name ?? "None"} (${_selectedPrinter?.connectionType.name.toUpperCase() ?? "UNKNOWN"})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '• Byte Count: ${record.generatedBytes?.length ?? 0} bytes',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Text(
                    '• First 32 Bytes (Hex): ${diag?.hexPreview ?? WriteDiagnosticInfo.formatHex(record.generatedBytes ?? Uint8List(0))}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '• SHA-256: ${record.generatedSha256 ?? "N/A"}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  if (diag != null) ...[
                    Text(
                      '• Write Start: ${diag.startTime.toIso8601String().substring(11, 23)} • Duration: ${diag.duration.inMilliseconds}ms',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Row(
                      children: [
                        const Text(
                          '• Write Result: ',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          diag.isSuccess
                              ? 'SUCCESS'
                              : 'EXCEPTION / TRANSPORT ERROR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: diag.isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (!diag.isSuccess && diag.exceptionType != null)
                      Text(
                        '• Exception [${diag.exceptionType}]: ${diag.exceptionMessage}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Barcode & QR comparison field
            if (c.expectedPayload != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Payload: "${c.expectedPayload}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _scanInputController,
                            decoration: const InputDecoration(
                              labelText: 'Scanned Payload (Paste or scan here)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              setState(() {
                                record.scannedPayload = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_scanInputController.text.isNotEmpty)
                          Chip(
                            label: Text(
                              _scanInputController.text == c.expectedPayload
                                  ? 'MATCH'
                                  : 'MISMATCH',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor:
                                _scanInputController.text == c.expectedPayload
                                ? Colors.green
                                : Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Text(
              'Operator Physical Verification Decision:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  onPressed: () => _updateActiveResult(CaseResultStatus.pass),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('PASS — Printed Correctly'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _updateActiveResult(CaseResultStatus.printed),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('PRINTED (Output Seen)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.teal),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _updateActiveResult(CaseResultStatus.partial),
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('PARTIAL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _updateActiveResult(CaseResultStatus.fail),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('FAIL (Corrupted/Wrong)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
                if (c.requiresCutter)
                  OutlinedButton.icon(
                    onPressed: () => _updateActiveResult(
                      CaseResultStatus.notSupportedDevice,
                    ),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('N/S-DEVICE (No Cutter)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
