import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Corporate security visitor badge label (80mm × 50mm).
LabelBuilder buildVisitorBadgeLabel() {
  return label(const LabelConfig(width: 80, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2))
      // Reverse Visitor Title Banner
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 50, thickness: 2))
      .text('VISITOR PASS', const TextOptions(x: 210, y: 20, size: 3, bold: true))
      .reverse(const ReverseOptions(x: 10, y: 10, width: 620, height: 50))
      // Visitor Name
      .text('SOK DARA', const TextOptions(x: 30, y: 80, size: 3, bold: true))
      .line(const LineOptions(x1: 30, y1: 135, x2: 440, y2: 135, thickness: 1))
      // Company & Host Organization
      .text('Company: ABC Technology Ltd.', const TextOptions(x: 30, y: 155, size: 2))
      .text('Host: Engineering Core Team', const TextOptions(x: 30, y: 200, size: 2))
      .text('Escort Required: LEVEL 2 ACCESS', const TextOptions(x: 30, y: 245, size: 1, bold: true))
      // Date Validity & Security QR
      .line(const LineOptions(x1: 30, y1: 280, x2: 600, y2: 280, thickness: 1))
      .text('VALID ONLY: 25 AUG 2026', const TextOptions(x: 30, y: 300, size: 2, bold: true))
      .text('Must be surrendered upon building departure', const TextOptions(x: 30, y: 345, size: 1))
      .qrcode(
        'https://security.portakal.internal/visitor/SOK-DARA-20260825',
        const QRCodeOptions(x: 470, y: 80, cellWidth: 4),
      )
      .text('Security ID', const TextOptions(x: 495, y: 240, size: 1, bold: true));
}

final visitorBadgeCase = ExampleCase(
  id: 'visitor_badge',
  title: 'Visitor Attendance Badge',
  description:
      'Corporate visitor identification badge featuring high-contrast reverse header, visitor and host names, date validity, and security checkpoint verification QR code.',
  category: ExampleCategory.ticketsAndBadges,
  recommendedMedia: '80mm × 50mm',
  sourcePath: 'lib/src/examples/tickets/visitor_badge.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
  },
  buildLabel: buildVisitorBadgeLabel,
  quickSnippet: '''
final job = buildVisitorBadgeLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
