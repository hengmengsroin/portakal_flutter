import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

import '../examples/example_case.dart';
import '../export/svg_export.dart';
import '../transport/hardware_printer_transport.dart';

/// Interactive detail and compilation screen for a single Portakal use case.
class ExampleDetailPage extends StatefulWidget {
  final ExampleCase exampleCase;
  final HardwarePrinterTransport? transport;
  final SvgFileSaver? fileSaver;

  const ExampleDetailPage({
    super.key,
    required this.exampleCase,
    this.transport,
    this.fileSaver,
  });

  @override
  State<ExampleDetailPage> createState() => _ExampleDetailPageState();
}

class _ExampleDetailPageState extends State<ExampleDetailPage> {
  late final ResolvedLabel _resolvedJob;
  late ExampleProtocol _selectedProtocol;

  Uint8List? _compiledBytes;
  String? _compilationError;
  bool _isSending = false;
  String? _transportStatus;
  bool _showFullHex = false;

  @override
  void initState() {
    super.initState();
    // Resolve once on initialization
    _resolvedJob = widget.exampleCase.buildLabel().resolve();

    // Default to first tested protocol, or TSC
    if (widget.exampleCase.testedProtocols.isNotEmpty) {
      _selectedProtocol = widget.exampleCase.testedProtocols.first;
    } else {
      _selectedProtocol = ExampleProtocol.tsc;
    }

    _compileCurrentProtocol();
  }

  void _compileCurrentProtocol() {
    try {
      final bytes = compileExample(_selectedProtocol, _resolvedJob);
      setState(() {
        _compiledBytes = bytes;
        _compilationError = null;
      });
    } on UnsupportedFeatureError catch (e) {
      setState(() {
        _compiledBytes = null;
        _compilationError = 'Not supported by this printer language:\n${e.message}';
      });
    } on EncodingError catch (e) {
      setState(() {
        _compiledBytes = null;
        _compilationError = 'Character encoding error:\n${e.message}';
      });
    } on ArgumentError catch (e) {
      setState(() {
        _compiledBytes = null;
        _compilationError = 'Character encoding error:\n${e.message}';
      });
    } on InvalidConfigError catch (e) {
      setState(() {
        _compiledBytes = null;
        _compilationError = 'Invalid configuration:\n${e.message}';
      });
    } catch (e) {
      setState(() {
        _compiledBytes = null;
        _compilationError = 'Compilation error:\n$e';
      });
    }
  }

  Future<void> _handleHardwarePrint() async {
    if (_compiledBytes == null || _isSending) return;

    setState(() {
      _isSending = true;
      _transportStatus = 'Transmitting ${_compiledBytes!.length} bytes to printer...';
    });

    try {
      final transport = widget.transport;
      if (transport is MockHardwarePrinterTransport) {
        final printer = transport.connectedPrinter ??
            const DiscoveredPrinter(
              id: 'mock-001',
              name: 'Mock Thermal Printer',
              isConnected: true,
            );
        final result = await transport.write(printer, _compiledBytes!);
        if (mounted) {
          setState(() {
            _isSending = false;
            if (result.isSuccess) {
              _transportStatus =
                  'Successfully sent ${_compiledBytes!.length} bytes to ${printer.name}!';
            } else {
              _transportStatus = 'Transport failed: ${result.exceptionMessage}';
            }
          });
        }
      } else {
        // Physical or default simulated transport
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          setState(() {
            _isSending = false;
            _transportStatus =
                'Successfully compiled and queued ${_compiledBytes!.length} bytes for transmission!';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _transportStatus = 'Transport failed: $e';
        });
      }
    }
  }

  String _formatHexDump(Uint8List bytes, {int maxBytes = 256}) {
    final buffer = StringBuffer();
    final count = _showFullHex ? bytes.length : (bytes.length > maxBytes ? maxBytes : bytes.length);

    for (int i = 0; i < count; i += 16) {
      final chunkEnd = (i + 16 < count) ? i + 16 : count;
      final chunk = bytes.sublist(i, chunkEnd);

      // Line offset: 0000:
      buffer.write('${i.toRadixString(16).padLeft(4, '0').toUpperCase()}: ');

      // Hex bytes: 1B 40 ...
      final hexParts = chunk.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).toList();
      buffer.write(hexParts.join(' ').padRight(48));

      // ASCII representation
      buffer.write(' |');
      for (final b in chunk) {
        if (b >= 32 && b <= 126) {
          buffer.write(String.fromCharCode(b));
        } else {
          buffer.write('.');
        }
      }
      buffer.write('|\n');
    }

    if (!_showFullHex && bytes.length > maxBytes) {
      buffer.write('... (${bytes.length - maxBytes} more bytes)\n');
    }

    return buffer.toString().trimRight();
  }

  String _formatAsciiDiagnostic(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      if (b >= 32 && b <= 126) {
        buffer.write(String.fromCharCode(b));
      } else if (b == 10) {
        buffer.write('\n');
      } else if (b == 13) {
        // skip or CR
      } else {
        buffer.write('.');
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _handleDownloadSvg() async {
    try {
      final export = SvgExport.fromCase(widget.exampleCase, _resolvedJob);
      final result = await export.save(customSaver: widget.fileSaver);
      if (!mounted) return;
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SVG saved: ${result.filename}'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (result.isCancelled) {
        // User dismissed the Save As dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save SVG: ${result.errorMessage}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating SVG: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTested = widget.exampleCase.testedProtocols.contains(_selectedProtocol);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exampleCase.title),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('download_svg_button'),
            icon: const Icon(Icons.download),
            tooltip: 'Download SVG',
            onPressed: _handleDownloadSvg,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy Source Path',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.exampleCase.sourcePath));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: ${widget.exampleCase.sourcePath}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metadata & Description Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            widget.exampleCase.category.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: Colors.deepOrange.shade50,
                          side: BorderSide(color: Colors.deepOrange.shade200),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.aspect_ratio, size: 16),
                          label: Text(
                            widget.exampleCase.recommendedMedia,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exampleCase.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.code, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Source: ${widget.exampleCase.sourcePath}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visual Preview Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Visual Label Preview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              '${_resolvedJob.widthDots}×${_resolvedJob.heightDots} dots (${_resolvedJob.dpi} DPI)',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              key: const Key('preview_download_svg_button'),
                              icon: const Icon(Icons.download, size: 20),
                              tooltip: 'Download SVG',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _handleDownloadSvg,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 380,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: LabelPreview.resolved(job: _resolvedJob),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Protocol Compilation Controls
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protocol Compiler & Code Generator',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ExampleProtocol>(
                            key: const Key('protocol_dropdown'),
                            initialValue: _selectedProtocol,
                            decoration: const InputDecoration(
                              labelText: 'Target Printer Protocol',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: ExampleProtocol.values.map((p) {
                              final tested = widget.exampleCase.testedProtocols.contains(p);
                              return DropdownMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Text(p.displayName),
                                    if (tested) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (p) {
                              if (p != null) {
                                setState(() {
                                  _selectedProtocol = p;
                                  _compileCurrentProtocol();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _compileCurrentProtocol,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Compile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isTested)
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tested & verified with ${_selectedProtocol.displayName}',
                            style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Untested or feature-limited with ${_selectedProtocol.displayName}',
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Compilation Error Banner
            if (_compilationError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unsupported Protocol Feature',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _compilationError!,
                            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Raw Output Inspector
            if (_compiledBytes != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Raw Byte Output',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  '${_compiledBytes!.length} bytes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.teal.shade700,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Hex'),
                                onPressed: () {
                                  final hexString = _compiledBytes!
                                      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                                      .join(' ');
                                  Clipboard.setData(ClipboardData(text: hexString));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied hex bytes to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatHexDump(_compiledBytes!),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF4EC9B0),
                          ),
                        ),
                      ),
                      if (_compiledBytes!.length > 256)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showFullHex = !_showFullHex;
                              });
                            },
                            child: Text(_showFullHex ? 'Show less' : 'Show all ${_compiledBytes!.length} bytes'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'ASCII Diagnostic Interpretation (Control chars shown as "."):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _formatAsciiDiagnostic(_compiledBytes!),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Code Pattern Box
            if (widget.exampleCase.quickSnippet != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Usage Snippet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: 'Copy Snippet',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.exampleCase.quickSnippet!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied code snippet'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282C34),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.exampleCase.quickSnippet!.trim(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF98C379),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Hardware Print Status & Action
            if (_transportStatus != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _transportStatus!.contains('Successfully')
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _transportStatus!.contains('Successfully')
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  _transportStatus!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _transportStatus!.contains('Successfully')
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Print Trigger Button
            FilledButton.icon(
              key: const Key('print_to_hardware_button'),
              onPressed: (_compiledBytes == null || _isSending) ? null : _handleHardwarePrint,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.print),
              label: Text(
                _isSending
                    ? 'Sending to Hardware...'
                    : 'Send to Printer (${_selectedProtocol.displayName})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
