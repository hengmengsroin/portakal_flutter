import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Customer queue ticketing slip for service counters (60mm media).
LabelBuilder buildQueueTicketLabel() {
  return sequentialLabel(const LabelConfig(width: 60, height: 60, copies: 1))
      // Department Header
      .text('CUSTOMER SERVICE QUEUE', const TextOptions(size: 1, bold: true))
      .text('Portakal Citizen Service Center', const TextOptions(size: 1))
      .divider()
      // Large Queue Ticket Number
      .text('YOUR NUMBER', const TextOptions(size: 1))
      .text('A-042', const TextOptions(size: 4, bold: true))
      .divider()
      // Queue Status Information
      .text('Service: General Inquiries & Account Setup', const TextOptions(size: 1))
      .row('Ahead of you:', '5 customers', bold: true)
      .row('Estimated wait:', '~12 mins')
      .divider()
      // Timestamp & Instructions
      .text('Printed: 25 Aug 2026 10:42 AM', const TextOptions(size: 1))
      .text('Please watch display screens for counter call', const TextOptions(size: 1))
      .text('Tickets expire after 3 missed calls', const TextOptions(size: 1));
}

final queueTicketCase = ExampleCase(
  id: 'queue_ticket',
  title: 'Service Queue Number Ticket',
  description:
      'Continuous thermal queue slip authored with sequential flow, oversized queue number, estimated wait rows, and timestamp.',
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
