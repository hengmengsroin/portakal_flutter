import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';
import 'package:example/src/transport/hardware_printer_transport.dart';

void main() {
  testWidgets('PortakalHardwareApp smoke launch test', (
    WidgetTester tester,
  ) async {
    final mockTransport = MockHardwarePrinterTransport();
    await tester.pumpWidget(PortakalHardwareApp(transport: mockTransport));
    expect(
      find.text('Hardware Validation & Transport Diagnostics — ESC/POS'),
      findsOneWidget,
    );
    expect(find.text('Printer Discovery'), findsOneWidget);
  });
}
