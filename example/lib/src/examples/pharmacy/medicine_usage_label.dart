import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Patient Prescription Dosage and Administration Label (70mm × 50mm).
LabelBuilder buildMedicineUsageLabel() {
  return label(const LabelConfig(width: 70, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 540, height: 380, thickness: 2))
      // Pharmacy & Patient Header
      .text('CENTRAL PHARMACY DISPENSARY', const TextOptions(x: 25, y: 25, size: 1, bold: true))
      .text('Patient: Sok Dara', const TextOptions(x: 25, y: 55, size: 2, bold: true))
      .text('Rx #: RX-20260825-991', const TextOptions(x: 350, y: 55, size: 1))
      .line(const LineOptions(x1: 25, y1: 95, x2: 525, y2: 95, thickness: 1))
      // Medication Name & Strength
      .text('Amoxicillin 500mg', const TextOptions(x: 25, y: 110, size: 2, bold: true))
      // Dosage & Frequency Instructions
      .text('Directions for Use:', const TextOptions(x: 25, y: 155, size: 1, bold: true))
      .text('Take 1 capsule by mouth', const TextOptions(x: 25, y: 180, size: 1))
      .text('3 times daily - After food', const TextOptions(x: 25, y: 205, size: 1, bold: true))
      .text('Duration: 5 days (Finish all)', const TextOptions(x: 25, y: 235, size: 1))
      // Footer & QR Code
      .line(const LineOptions(x1: 25, y1: 275, x2: 525, y2: 275, thickness: 1))
      .text('Prescriber: Dr. S. Rath', const TextOptions(x: 25, y: 295, size: 1))
      .text('Dispensed: 25 Aug 2026', const TextOptions(x: 25, y: 325, size: 1))
      .text('Caution: Complete the entire course', const TextOptions(x: 25, y: 355, size: 1))
      .qrcode(
        'https://rx.pharma.local/verify/RX-20260825-991',
        const QRCodeOptions(x: 400, y: 275, cellWidth: 3),
      );
}

final medicineUsageCase = ExampleCase(
  id: 'medicine_usage_label',
  title: 'Prescription Dosage & Usage Label',
  description:
      'Patient prescription label detailing patient name, Amoxicillin medication instructions, dosage frequency, treatment duration, dispensing date, and verification QR code.',
  category: ExampleCategory.pharmacy,
  recommendedMedia: '70mm × 50mm',
  sourcePath: 'lib/src/examples/pharmacy/medicine_usage_label.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildMedicineUsageLabel,
  quickSnippet: '''
final job = buildMedicineUsageLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
