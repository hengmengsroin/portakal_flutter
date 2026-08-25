import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../hardware/case_model.dart';
import '../hardware/protocol_registry.dart';
import '../hardware/sha256.dart';
import '../transport/hardware_printer_transport.dart';

/// Recorded validation execution state for a single case.
class CaseExecutionRecord {
  final HardwareValidationCase testCase;
  final Uint8List? generatedBytes;
  final String? generatedSha256;
  final bool? isGoldenMatch;
  CaseResultStatus status;
  String? level2;
  String? level3;
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
    this.level2,
    this.level3,
    this.diagnosticInfo,
    this.scannedPayload,
    this.notes,
    this.executedAt,
  });
}

/// Universal Hardware Validation Test Bench supporting all 9 Portakal Protocols.
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
  ValidationProtocol _activeProtocol = ValidationProtocol.escpos;

  final List<DiscoveredPrinter> _discoveredPrinters = [];
  DiscoveredPrinter? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';

  // Map of (Protocol -> (CaseID -> Record))
  final Map<ValidationProtocol, Map<String, CaseExecutionRecord>> _records = {};
  CaseExecutionRecord? _lastActiveRecord;
  bool _overrideUnsupportedProbe = false;

  final TextEditingController _scanInputController = TextEditingController();

  ProtocolValidationSuite get _currentSuite =>
      ProtocolRegistry.getSuite(_activeProtocol);

  Map<String, CaseExecutionRecord> get _currentRecords =>
      _records[_activeProtocol]!;

  bool get _isProbeFailed {
    final probeId = _currentSuite.capabilityProbeCaseId;
    final probeRecord = _currentRecords[probeId];
    return probeRecord?.status == CaseResultStatus.notSupportedDevice ||
        probeRecord?.status == CaseResultStatus.fail;
  }

  @override
  void initState() {
    super.initState();

    // Initialize session records for all 9 protocols
    for (final suite in ProtocolRegistry.allSuites) {
      final map = <String, CaseExecutionRecord>{};
      for (final c in suite.cases) {
        map[c.id] = CaseExecutionRecord(
          testCase: c,
          status: c.isSupportedInSdk
              ? CaseResultStatus.notTested
              : CaseResultStatus.notSupportedSdk,
          level2: c.isSupportedInSdk ? 'N/T' : 'N/S-SDK',
          level3: c.isSupportedInSdk ? 'N/T' : 'N/S-SDK',
        );
      }
      _records[suite.protocol] = map;
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

  Future<void> _executeCase(HardwareValidationCase c) async {
    if (!c.isSupportedInSdk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            c.unsupportedSdkReason ?? 'Feature not supported in current SDK.',
          ),
        ),
      );
      return;
    }

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
    final isMatch = c.expectedSha256 != null
        ? (sha.toLowerCase() == c.expectedSha256!.toLowerCase())
        : null;

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
      level2: diag.isSuccess ? 'SENT' : 'FAIL',
      level3: 'N/T',
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
    final c = _lastActiveRecord!.testCase;

    String l2 = 'PASS';
    String l3 = 'PASS';

    switch (status) {
      case CaseResultStatus.pass:
        l2 = 'PASS';
        if (c.requiresScanner) {
          final isMatch = _scanInputController.text == c.expectedPayload;
          l3 = isMatch
              ? 'PASS'
              : (_scanInputController.text.isEmpty ? 'N/T' : 'FAIL');
        } else {
          l3 = 'PASS';
        }
        break;
      case CaseResultStatus.printed:
        l2 = 'PASS';
        l3 = 'N/T';
        break;
      case CaseResultStatus.partial:
        l2 = 'PASS';
        l3 = 'PARTIAL';
        break;
      case CaseResultStatus.fail:
        l2 = 'FAIL';
        l3 = 'FAIL';
        break;
      case CaseResultStatus.notSupportedDevice:
        l2 = 'N/S-DEVICE';
        l3 = 'N/S-DEVICE';
        break;
      default:
        l2 = 'N/T';
        l3 = 'N/T';
    }

    setState(() {
      _lastActiveRecord!.status = status;
      _lastActiveRecord!.level2 = l2;
      _lastActiveRecord!.level3 = l3;
      _currentRecords[_lastActiveRecord!.testCase.id] = _lastActiveRecord!;
    });
  }

  void _showSessionExportDialog() {
    final sessionMap = {
      'schema_version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'portakal_version': '0.3.0',
      'protocol': _activeProtocol.id,
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
          'is_supported_in_sdk': r.testCase.isSupportedInSdk,
          'unsupported_sdk_reason': r.testCase.unsupportedSdkReason,
          'byte_count': r.generatedBytes?.length ?? 0,
          'actual_sha256': r.generatedSha256,
          'expected_sha256': r.testCase.expectedSha256,
          'golden_match': r.isGoldenMatch,
          'transport_success': r.diagnosticInfo?.isSuccess ?? false,
          'duration_ms': r.diagnosticInfo?.duration.inMilliseconds,
          'hex_preview': r.diagnosticInfo?.hexPreview,
          'operator_status': r.status.label,
          'level2': r.level2,
          'level3': r.level3,
          'scanned_payload': r.scannedPayload,
          'notes': r.notes,
        };
      }).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(sessionMap);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export ${_currentSuite.displayName} Session JSON'),
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
    final diagnosticCases =
        _currentSuite.cases.where((c) => c.isDiagnostic).toList();
    final protocolCases =
        _currentSuite.cases.where((c) => !c.isDiagnostic).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Portakal Hardware Test Bench — ${_currentSuite.displayName}',
        ),
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
          // Left Pane: Protocol Switcher, Discovery & Session Status
          SizedBox(
            width: 340,
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Protocol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown for all 9 protocols
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ValidationProtocol>(
                          isExpanded: true,
                          value: _activeProtocol,
                          items: ValidationProtocol.values.map((proto) {
                            return DropdownMenuItem(
                              value: proto,
                              child: Text(
                                proto.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _activeProtocol = val;
                                _lastActiveRecord = null;
                                _overrideUnsupportedProbe = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentSuite.description,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Printer Transport',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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

          // Right Pane: Active Diagnostics & Case Execution Grids
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Protocol Warning / Notes Banner
                  if (_currentSuite.warning != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentSuite.warning!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Active Transmission Banner with Full Diagnostics
                  if (_lastActiveRecord != null)
                    _buildActiveVerificationPanel(),

                  const SizedBox(height: 12),
                  Text(
                    'Step 1: ${_currentSuite.displayName} Capability Probes',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Establish whether raw bytes physically reach and print in this protocol.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // Diagnostic Cases Grid
                  _buildCaseGrid(
                    diagnosticCases,
                    isConnected,
                    allowExecution: true,
                  ),

                  // Stop-on-Unsupported Warning & Override
                  if (_isProbeFailed && !_overrideUnsupportedProbe) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Protocol Capability Notice',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'This connected printer does not appear to support this protocol command language. '
                            'Advanced cases are gated to prevent undefined device states.',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _overrideUnsupportedProbe = true;
                              });
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red[800],
                            ),
                            icon: const Icon(Icons.lock_open, size: 16),
                            label: const Text(
                              'Continue Anyway (Advanced Override)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    'Step 2: ${_currentSuite.displayName} Validation Suite',
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
                  _buildCaseGrid(
                    protocolCases,
                    isConnected,
                    allowExecution:
                        !_isProbeFailed || _overrideUnsupportedProbe,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseGrid(
    List<HardwareValidationCase> cases,
    bool isConnected, {
    required bool allowExecution,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cases.map((c) {
        final record = _currentRecords[c.id];
        final status = record?.status ??
            (c.isSupportedInSdk
                ? CaseResultStatus.notTested
                : CaseResultStatus.notSupportedSdk);

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
                    c.isSupportedInSdk
                        ? c.description
                        : (c.unsupportedSdkReason ?? 'Not supported in SDK'),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          c.isSupportedInSdk ? Colors.grey : Colors.deepOrange,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          (isConnected && allowExecution && c.isSupportedInSdk)
                              ? () => _executeCase(c)
                              : null,
                      icon: const Icon(Icons.print, size: 16),
                      label: Text(
                        c.isSupportedInSdk ? 'Print ${c.id}' : 'N/S-SDK',
                      ),
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
    final isMatch = record.isGoldenMatch;
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
                    isMatch == null
                        ? 'Golden: N/A'
                        : (isMatch ? 'Golden: MATCH' : 'Golden: DIFFERENT'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  backgroundColor: isMatch == null
                      ? Colors.grey[700]
                      : (isMatch ? Colors.green : Colors.orange),
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
                    '• Protocol: ${_currentSuite.displayName}',
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
                    '• Actual SHA-256: ${record.generatedSha256 ?? "N/A"}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                  if (c.expectedSha256 != null)
                    Text(
                      '• Expected Golden SHA: ${c.expectedSha256}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.indigo,
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
                      _updateActiveResult(CaseResultStatus.notSupportedDevice),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('N/S-DEVICE (No Command Support)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                  ),
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
                  label: const Text('FAIL (Error / Corrupted)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
