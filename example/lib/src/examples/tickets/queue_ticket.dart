import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Customer queue ticketing slip for service counters (60mm media).
LabelBuilder buildQueueTicketLabel() {
  return label(const LabelConfig(width: 60, height: 60, copies: 1))
      // Department Header
      .text('CUSTOMER SERVICE QUEUE', const TextOptions(x: 70, y: 15, size: 1, bold: true))
      .text('Portakal Citizen Service Center', const TextOptions(x: 80, y: 40, size: 1))
      .line(const LineOptions(x1: 15, y1: 65, x2: 465, y2: 65, thickness: 1))
      // Large Queue Ticket Number
      .text('YOUR NUMBER', const TextOptions(x: 160, y: 80, size: 1))
      .text('A-042', const TextOptions(x: 120, y: 110, size: 4, bold: true))
      .line(const LineOptions(x1: 15, y1: 200, x2: 465, y2: 200, thickness: 1))
      // Queue Status Information
      .text('Service: General Inquiries & Account Setup', const TextOptions(x: 40, y: 220, size: 1))
      .text('Ahead of you: 5 customers', const TextOptions(x: 120, y: 255, size: 1, bold: true))
      .text('Estimated wait time: ~12 mins', const TextOptions(x: 110, y: 285, size: 1))
      .line(const LineOptions(x1: 15, y1: 320, x2: 465, y2: 320, thickness: 1))
      // Timestamp & Instructions
      .text('Printed: 25 Aug 2026 10:42 AM', const TextOptions(x: 105, y: 340, size: 1))
      .text('Please watch display screens for counter call', const TextOptions(x: 55, y: 370, size: 1))
      .text('Tickets expire after 3 missed calls', const TextOptions(x: 95, y: 400, size: 1));
}

final queueTicketCase = ExampleCase(
  id: 'queue_ticket',
  title: 'Service Queue Number Ticket',
  description:
      'Continuous thermal queue slip with oversized queue number callout, estimated wait time, customer position, and timestamp.',
  category: ExampleCategory.ticketsAndBadges,
  recommendedMedia: '60mm Continuous',
  sourcePath: 'lib/src/examples/tickets/queue_ticket.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildQueueTicketLabel,
  quickSnippet: '''
final job = buildQueueTicketLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
