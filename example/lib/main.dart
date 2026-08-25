import 'package:flutter/material.dart';
import 'src/pages/hardware_validation_page.dart';
import 'src/transport/hardware_printer_transport.dart';

void main() {
  runApp(const PortakalHardwareApp());
}

class PortakalHardwareApp extends StatelessWidget {
  final HardwarePrinterTransport? transport;
  final String targetDeviceName;

  const PortakalHardwareApp({
    super.key,
    this.transport,
    this.targetDeviceName = 'Printer0001-328F',
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portakal Hardware Validation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HardwareValidationPage(
        transport: transport ?? FlutterThermalPrinterTransport(),
        targetDeviceName: targetDeviceName,
      ),
    );
  }
}
