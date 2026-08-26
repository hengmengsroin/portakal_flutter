import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Kitchen Order Ticket (KOT) for restaurant kitchen displays (80mm media).
LabelBuilder buildKitchenTicketLabel() {
  final ticket = sequentialLabel(const LabelConfig(width: 80, height: 75, copies: 1));

  ticket
      // Table & Order Identification Header
      .row('TABLE 12', 'Order #A1024', bold: true, size: 2)
      .row('Dine-In', 'Time: 19:42')
      .divider()
      // Item 1 with modifier
      .text('2 x Beef Lok Lak', const TextOptions(size: 2, bold: true))
      .text('   - NO ONION', const TextOptions(size: 1, bold: true))
      .space(5)
      // Item 2 with modifier
      .text('1 x Fried Rice', const TextOptions(size: 2, bold: true))
      .text('   - EXTRA CRISPY EGG', const TextOptions(size: 1))
      .space(5)
      // Item 3
      .text('1 x Iced Tea (Sweet)', const TextOptions(size: 2, bold: true))
      .divider()
      // Allergy & Special Request Callout Box (using exact coordinates for boxed highlight)
      .box(const BoxOptions(x: 20, y: 345, width: 600, height: 80, thickness: 2))
      .text('SPECIAL INSTRUCTIONS / ALLERGY ALERT:', const TextOptions(x: 35, y: 355, size: 1, bold: true))
      .text('*** CUSTOMER HAS SEVERE PEANUT ALLERGY ***', const TextOptions(x: 35, y: 385, size: 1, bold: true))
      .text('Server: Srey Pich  -  Station: Wok 1', const TextOptions(x: 20, y: 445, size: 1));

  return ticket;
}

final kitchenTicketCase = ExampleCase(
  id: 'kitchen_ticket',
  title: 'Kitchen Order Ticket (KOT)',
  description:
      'Continuous receipt kitchen order ticket authored with sequential layout, table header rows, and preparation modifiers.',
  category: ExampleCategory.restaurant,
  recommendedMedia: '80mm Continuous',
  sourcePath: 'lib/src/examples/restaurant/kitchen_ticket.dart',
  testedProtocols: {
    ExampleProtocol.tsc,
    ExampleProtocol.zpl,
    ExampleProtocol.epl,
    ExampleProtocol.cpcl,
    ExampleProtocol.dpl,
    ExampleProtocol.ipl,
    ExampleProtocol.sbpl,
  },
  buildLabel: buildKitchenTicketLabel,
  quickSnippet: '''
final job = buildKitchenTicketLabel().resolve();
final bytes = tsc.compileResolved(job);
''',
);
