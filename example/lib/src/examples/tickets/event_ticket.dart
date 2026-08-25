import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Event admission ticket with branding, session info, and gate entry QR (80mm × 50mm).
LabelBuilder buildEventTicketLabel() {
  return label(const LabelConfig(width: 80, height: 50, copies: 1))
      .box(const BoxOptions(x: 10, y: 10, width: 620, height: 380, thickness: 2))
      // Event Title Header
      .text('PORTAKAL DEV DAY 2026', const TextOptions(x: 25, y: 25, size: 2, bold: true))
      .text('ANNUAL DEVELOPER CONFERENCE', const TextOptions(x: 25, y: 60, size: 1))
      .line(const LineOptions(x1: 25, y1: 85, x2: 605, y2: 85, thickness: 2))
      // Event Time & Location Details
      .text('DATE: 25 AUG 2026', const TextOptions(x: 25, y: 105, size: 2, bold: true))
      .text('TIME: 09:00 AM (DOORS OPEN 08:30)', const TextOptions(x: 25, y: 140, size: 1))
      .text('VENUE: GRAND CONVENTION HALL A', const TextOptions(x: 25, y: 170, size: 1, bold: true))
      .text('SEAT: ROW 4, SEAT 14B (VIP ACCESS)', const TextOptions(x: 25, y: 200, size: 1))
      .line(const LineOptions(x1: 25, y1: 235, x2: 440, y2: 235, thickness: 1))
      // Ticket Serial Number
      .text('TICKET ID:', const TextOptions(x: 25, y: 250, size: 1))
      .text('PD-000812', const TextOptions(x: 25, y: 275, size: 2, bold: true))
      .text('Non-transferable  -  Present at entrance', const TextOptions(x: 25, y: 320, size: 1))
      // Gate Check-in QR Code
      .qrcode(
        'https://devday.portakal.io/ticket/PD-000812',
        const QRCodeOptions(x: 450, y: 105, cellWidth: 4),
      )
      .text('Scan for Gate Entry', const TextOptions(x: 455, y: 265, size: 1, bold: true))
      .line(const LineOptions(x1: 25, y1: 345, x2: 605, y2: 345, thickness: 1))
      .text('ADMIT ONE  -  BADGE MUST BE WORN AT ALL TIMES', const TextOptions(x: 100, y: 355, size: 1));
}

final eventTicketCase = ExampleCase(
  id: 'event_ticket',
  title: 'Conference Admission Ticket',
  description:
      'Admission ticket featuring conference branding, scheduled session details, assigned seating, ticket serial identifier, and admission gate QR code.',
  category: ExampleCategory.ticketsAndBadges,
  recommendedMedia: '80mm × 50mm',
  sourcePath: 'lib/src/examples/tickets/event_ticket.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildEventTicketLabel,
  quickSnippet: '''
final job = buildEventTicketLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
