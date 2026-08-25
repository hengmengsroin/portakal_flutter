import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PreviewBeforePrintScreen(),
  ));
}

/// Demonstrates the canonical Portakal 1.1 Preview-Before-Print workflow:
/// 1. Build label template
/// 2. Resolve ONCE to immutable [ResolvedLabel]
/// 3. Preview with [LabelPreview.resolved]
/// 4. Confirm and compile the SAME resolved job with [tsc.compileResolved]
class PreviewBeforePrintScreen extends StatefulWidget {
  const PreviewBeforePrintScreen({super.key});

  @override
  State<PreviewBeforePrintScreen> createState() =>
      _PreviewBeforePrintScreenState();
}

class _PreviewBeforePrintScreenState extends State<PreviewBeforePrintScreen> {
  late ResolvedLabel _resolvedJob;
  bool _isPrinting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _buildAndResolveJob();
  }

  void _buildAndResolveJob() {
    final builder = label(const LabelConfig(width: 80, height: 100, copies: 1))
        // Header
        .text(
          'MY COMPANY INC.',
          const TextOptions(x: 20, y: 30, size: 2, bold: true),
        )
        .text('123 Business Road', const TextOptions(x: 20, y: 70, size: 1))
        .text('City, Country', const TextOptions(x: 20, y: 100, size: 1))
        // Invoice Title & Info
        .text('INVOICE', const TextOptions(x: 400, y: 30, size: 3, bold: true))
        .text('No: INV-001', const TextOptions(x: 400, y: 90, size: 1))
        .text('Date: 2026-06-17', const TextOptions(x: 400, y: 120, size: 1))
        // Separator
        .line(
          const LineOptions(x1: 20, y1: 160, x2: 620, y2: 160, thickness: 2),
        )
        // Table Header
        .text('Item', const TextOptions(x: 20, y: 180, size: 1, bold: true))
        .text('Qty', const TextOptions(x: 350, y: 180, size: 1, bold: true))
        .text('Price', const TextOptions(x: 420, y: 180, size: 1, bold: true))
        .text('Total', const TextOptions(x: 520, y: 180, size: 1, bold: true))
        .line(
          const LineOptions(x1: 20, y1: 210, x2: 620, y2: 210, thickness: 1),
        )
        // Items
        .text('Product A', const TextOptions(x: 20, y: 240, size: 1))
        .text('2', const TextOptions(x: 350, y: 240, size: 1))
        .text('\$15.00', const TextOptions(x: 420, y: 240, size: 1))
        .text('\$30.00', const TextOptions(x: 520, y: 240, size: 1))
        .text('Product B', const TextOptions(x: 20, y: 280, size: 1))
        .text('1', const TextOptions(x: 350, y: 280, size: 1))
        .text('\$25.00', const TextOptions(x: 420, y: 280, size: 1))
        .text('\$25.00', const TextOptions(x: 520, y: 280, size: 1))
        // Separator
        .line(
          const LineOptions(x1: 20, y1: 370, x2: 620, y2: 370, thickness: 1),
        )
        // Totals
        .text('Subtotal:', const TextOptions(x: 420, y: 400, size: 1))
        .text('\$55.00', const TextOptions(x: 520, y: 400, size: 1))
        .text('Tax (10%):', const TextOptions(x: 420, y: 440, size: 1))
        .text('\$5.50', const TextOptions(x: 520, y: 440, size: 1))
        .text('Total:', const TextOptions(x: 420, y: 490, size: 2, bold: true))
        .text('\$60.50', const TextOptions(x: 520, y: 490, size: 2, bold: true))
        // Footer box
        .box(
          const BoxOptions(
            x: 20,
            y: 580,
            width: 600,
            height: 100,
            thickness: 2,
          ),
        )
        .barcode(
          '123456789',
          const BarcodeOptions(
            x: 40,
            y: 600,
            type: '128',
            height: 60,
            readable: 1,
          ),
        )
        .qrcode(
          'https://example.com/invoice/INV-001',
          const QRCodeOptions(x: 460, y: 600, cellWidth: 5),
        );

    _resolvedJob = builder.resolve();
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    setState(() {
      _isPrinting = true;
      _statusMessage = 'Compiling and sending job to printer...';
    });

    try {
      // Compile the EXACT SAME resolved job instance
      final bytes = tsc.compileResolved(_resolvedJob);

      // Simulate asynchronous transport write
      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage =
              'Success: Printed ${bytes.length} bytes for ${_resolvedJob.copies} copy!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPrinting = false;
          _statusMessage = 'Print failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Before Print'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Print Job Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 380,
                      child: LabelPreview.resolved(job: _resolvedJob),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage!.startsWith('Success')
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage!.startsWith('Success')
                        ? Colors.green.shade300
                        : Colors.orange.shade300,
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage!.startsWith('Success')
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _isPrinting
                      ? null
                      : () {
                          setState(() {
                            _statusMessage = 'Print cancelled.';
                          });
                        },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isPrinting ? null : _handlePrint,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                  ),
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isPrinting ? 'Printing...' : 'Confirm & Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
