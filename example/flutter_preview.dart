import 'package:flutter/material.dart';
import 'package:portakal_flutter/portakal_flutter.dart';

void main() {
  runApp(const PreviewApp());
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceLabel = label(LabelConfig(width: 80, height: 100))
        // Header
        .text('MY COMPANY INC.', TextOptions(x: 20, y: 30, size: 2, bold: true))
        .text('123 Business Road', TextOptions(x: 20, y: 70, size: 1))
        .text('City, Country', TextOptions(x: 20, y: 100, size: 1))
        // Invoice Title & Info
        .text('INVOICE', TextOptions(x: 400, y: 30, size: 3, bold: true))
        .text('No: INV-001', TextOptions(x: 400, y: 90, size: 1))
        .text('Date: 2026-06-17', TextOptions(x: 400, y: 120, size: 1))
        // Separator
        .line(LineOptions(x1: 20, y1: 160, x2: 620, y2: 160, thickness: 2))
        // Table Header
        .text('Item', TextOptions(x: 20, y: 180, size: 1, bold: true))
        .text('Qty', TextOptions(x: 350, y: 180, size: 1, bold: true))
        .text('Price', TextOptions(x: 420, y: 180, size: 1, bold: true))
        .text('Total', TextOptions(x: 520, y: 180, size: 1, bold: true))
        .line(LineOptions(x1: 20, y1: 210, x2: 620, y2: 210, thickness: 1))
        // Items
        .text('Product A', TextOptions(x: 20, y: 240, size: 1))
        .text('2', TextOptions(x: 350, y: 240, size: 1))
        .text('\$15.00', TextOptions(x: 420, y: 240, size: 1))
        .text('\$30.00', TextOptions(x: 520, y: 240, size: 1))
        .text('Product B', TextOptions(x: 20, y: 280, size: 1))
        .text('1', TextOptions(x: 350, y: 280, size: 1))
        .text('\$25.00', TextOptions(x: 420, y: 280, size: 1))
        .text('\$25.00', TextOptions(x: 520, y: 280, size: 1))
        .text('Service C', TextOptions(x: 20, y: 320, size: 1))
        .text('1', TextOptions(x: 350, y: 320, size: 1))
        .text('\$45.00', TextOptions(x: 420, y: 320, size: 1))
        .text('\$45.00', TextOptions(x: 520, y: 320, size: 1))
        // Separator
        .line(LineOptions(x1: 20, y1: 370, x2: 620, y2: 370, thickness: 1))
        // Totals
        .text('Subtotal:', TextOptions(x: 420, y: 400, size: 1))
        .text('\$100.00', TextOptions(x: 520, y: 400, size: 1))
        .text('Tax (10%):', TextOptions(x: 420, y: 440, size: 1))
        .text('\$10.00', TextOptions(x: 520, y: 440, size: 1))
        .text('Total:', TextOptions(x: 420, y: 490, size: 2, bold: true))
        .text('\$110.00', TextOptions(x: 520, y: 490, size: 2, bold: true))
        // Footer box
        .box(BoxOptions(x: 20, y: 580, width: 600, height: 100, thickness: 2))
        .text(
          'សូមអរគុណសម្រាប់ការទូទាត់!',
          TextOptions(x: 100, y: 610, size: 2, bold: true),
        )
        .text(
          'សូមទូទាត់ក្នុងរយៈពេល 30 ថ្ងៃ',
          TextOptions(x: 180, y: 650, size: 1),
        )
        .barcode(
          '123456789',
          BarcodeOptions(x: 20, y: 600, type: '128', height: 60, readable: 1),
        )
        .qrcode(
          'https://example.com',
          QRCodeOptions(x: 400, y: 600, cellWidth: 6),
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Invoice Preview')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LabelPreview(label: invoiceLabel),
          ),
        ),
      ),
    );
  }
}
