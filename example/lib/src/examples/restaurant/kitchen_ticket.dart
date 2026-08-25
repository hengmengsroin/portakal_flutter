import 'package:portakal_flutter/portakal_flutter.dart';
import '../example_case.dart';

/// Flagship Kitchen Order Ticket (KOT) for restaurant kitchen displays (80mm media).
LabelBuilder buildKitchenTicketLabel() {
  return label(const LabelConfig(width: 80, height: 75, copies: 1))
      // Table & Order Identification Header
      .text('TABLE 12', const TextOptions(x: 20, y: 20, size: 3, bold: true))
      .text('Order #A1024', const TextOptions(x: 360, y: 25, size: 2, bold: true))
      .text('Time: 19:42 (Dine-In)', const TextOptions(x: 360, y: 65, size: 1))
      // Separator Line
      .line(const LineOptions(x1: 20, y1: 95, x2: 620, y2: 95, thickness: 2))
      // Item 1 with modifier
      .text('2 x Beef Lok Lak', const TextOptions(x: 20, y: 115, size: 2, bold: true))
      .text('   - NO ONION', const TextOptions(x: 30, y: 155, size: 1, bold: true))
      // Item 2 with modifier
      .text('1 x Fried Rice', const TextOptions(x: 20, y: 195, size: 2, bold: true))
      .text('   - EXTRA CRISPY EGG', const TextOptions(x: 30, y: 235, size: 1))
      // Item 3
      .text('1 x Iced Tea (Sweet)', const TextOptions(x: 20, y: 275, size: 2, bold: true))
      // Separator Line
      .line(const LineOptions(x1: 20, y1: 325, x2: 620, y2: 325, thickness: 2))
      // Allergy & Special Request Callout Box
      .box(const BoxOptions(x: 20, y: 345, width: 600, height: 80, thickness: 2))
      .text('SPECIAL INSTRUCTIONS / ALLERGY ALERT:', const TextOptions(x: 35, y: 355, size: 1, bold: true))
      .text('*** CUSTOMER HAS SEVERE PEANUT ALLERGY ***', const TextOptions(x: 35, y: 385, size: 1, bold: true))
      .text('Server: Srey Pich  -  Station: Wok 1', const TextOptions(x: 20, y: 445, size: 1));
}

final kitchenTicketCase = ExampleCase(
  id: 'kitchen_ticket',
  title: 'Kitchen Order Ticket (KOT)',
  description:
      'Continuous receipt kitchen order ticket with oversized table identifier, order timestamp, preparation modifiers, allergy alerts, and no monetary prices.',
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
