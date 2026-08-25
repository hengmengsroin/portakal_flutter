import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import '../hardware/sha256.dart';

/// Connection type abstraction for discovered printers.
enum DiscoveredConnectionType { ble, usb, network, unknown }

/// Abstract model for a discovered physical or emulated printer.
class DiscoveredPrinter {
  final String id;
  final String name;
  final DiscoveredConnectionType connectionType;
  final bool isConnected;
  final Object? rawDevice;

  const DiscoveredPrinter({
    required this.id,
    required this.name,
    this.connectionType = DiscoveredConnectionType.ble,
    this.isConnected = false,
    this.rawDevice,
  });

  DiscoveredPrinter copyWith({
    String? id,
    String? name,
    DiscoveredConnectionType? connectionType,
    bool? isConnected,
    Object? rawDevice,
  }) {
    return DiscoveredPrinter(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      isConnected: isConnected ?? this.isConnected,
      rawDevice: rawDevice ?? this.rawDevice,
    );
  }
}

/// Detailed diagnostic metrics recorded for each transmission attempt.
class WriteDiagnosticInfo {
  final int byteCount;
  final String hexPreview;
  final String sha256;
  final DateTime startTime;
  final Duration duration;
  final bool isSuccess;
  final String? exceptionType;
  final String? exceptionMessage;

  const WriteDiagnosticInfo({
    required this.byteCount,
    required this.hexPreview,
    required this.sha256,
    required this.startTime,
    required this.duration,
    required this.isSuccess,
    this.exceptionType,
    this.exceptionMessage,
  });

  static String formatHex(Uint8List bytes, {int maxBytes = 32}) {
    final count = bytes.length < maxBytes ? bytes.length : maxBytes;
    final hexParts = <String>[];
    for (var i = 0; i < count; i++) {
      hexParts.add(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return hexParts.join(' ');
  }
}

/// Abstract transport interface decoupling UI from plugin implementation.
abstract interface class HardwarePrinterTransport {
  Stream<List<DiscoveredPrinter>> get printersStream;

  Future<void> startScan({bool ble = true, bool usb = true});

  Future<void> stopScan();

  Future<bool> connect(DiscoveredPrinter printer);

  Future<void> disconnect(DiscoveredPrinter printer);

  /// Transmits [bytes] to [printer], returning detailed timing and diagnostic info.
  Future<WriteDiagnosticInfo> write(DiscoveredPrinter printer, Uint8List bytes);

  void dispose();
}

/// Production implementation leveraging `flutter_thermal_printer` and direct BLE characteristic write.
class FlutterThermalPrinterTransport implements HardwarePrinterTransport {
  final StreamController<List<DiscoveredPrinter>> _streamController =
      StreamController<List<DiscoveredPrinter>>.broadcast();

  StreamSubscription<List<Printer>>? _pluginSubscription;
  final List<Printer> _rawPrinters = [];

  FlutterThermalPrinterTransport() {
    _pluginSubscription = FlutterThermalPrinter.instance.devicesStream.listen((
      pluginPrinters,
    ) {
      _rawPrinters
        ..clear()
        ..addAll(pluginPrinters);

      final mapped = pluginPrinters.map(_mapPluginPrinter).toList();
      _streamController.add(mapped);
    });
  }

  @override
  Stream<List<DiscoveredPrinter>> get printersStream =>
      _streamController.stream;

  @override
  Future<void> startScan({bool ble = true, bool usb = true}) async {
    final types = <ConnectionType>[];
    if (ble) types.add(ConnectionType.BLE);
    if (usb) types.add(ConnectionType.USB);

    await FlutterThermalPrinter.instance.getPrinters(
      connectionTypes: types,
      refreshDuration: const Duration(seconds: 2),
    );
  }

  @override
  Future<void> stopScan() async {
    await FlutterThermalPrinter.instance.stopScan();
  }

  @override
  Future<bool> connect(DiscoveredPrinter printer) async {
    final raw = printer.rawDevice;
    if (raw is Printer) {
      return FlutterThermalPrinter.instance.connect(raw);
    }
    return false;
  }

  @override
  Future<void> disconnect(DiscoveredPrinter printer) async {
    final raw = printer.rawDevice;
    if (raw is Printer) {
      await FlutterThermalPrinter.instance.disconnect(raw);
    }
  }

  @override
  Future<WriteDiagnosticInfo> write(
    DiscoveredPrinter printer,
    Uint8List bytes,
  ) async {
    final startTime = DateTime.now();
    final hexPreview = WriteDiagnosticInfo.formatHex(bytes);
    final sha = calculateSha256(bytes);

    if (!printer.isConnected) {
      final err = StateError('Printer "${printer.name}" is not connected.');
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: DateTime.now().difference(startTime),
        isSuccess: false,
        exceptionType: 'StateError',
        exceptionMessage: err.message,
      );
    }

    final raw = printer.rawDevice;
    if (raw is! Printer) {
      final err = ArgumentError(
        'Printer object invalid or missing raw device handle.',
      );
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: DateTime.now().difference(startTime),
        isSuccess: false,
        exceptionType: 'ArgumentError',
        exceptionMessage: err.message,
      );
    }

    try {
      if (raw.connectionType == ConnectionType.BLE && raw.address != null) {
        final services = await raw.discoverServices();

        BleCharacteristic? writeChar;
        BleCharacteristic? writeNoRespChar;

        for (final service in services) {
          for (final characteristic in service.characteristics) {
            if (characteristic.properties.contains(
              CharacteristicProperty.write,
            )) {
              writeChar ??= characteristic;
            }
            if (characteristic.properties.contains(
              CharacteristicProperty.writeWithoutResponse,
            )) {
              writeNoRespChar ??= characteristic;
            }
          }
        }

        final targetChar = writeChar ?? writeNoRespChar;
        if (targetChar == null) {
          throw StateError(
            'BLE GATT error: No writable characteristic found in ${services.length} services for ${raw.address}',
          );
        }

        final withResponse = targetChar.properties.contains(
          CharacteristicProperty.write,
        );
        final requestedMtu = Platform.isMacOS ? 150 : 500;
        final mtu =
            Platform.isWindows ? 50 : await raw.requestMtu(requestedMtu);
        final maxChunkSize = (mtu > 3) ? (mtu - 3) : 20;

        for (var i = 0; i < bytes.length; i += maxChunkSize) {
          final chunk = bytes.sublist(
            i,
            (i + maxChunkSize > bytes.length)
                ? bytes.length
                : (i + maxChunkSize),
          );

          await targetChar.write(chunk, withResponse: withResponse);

          if (bytes.length > maxChunkSize) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      } else {
        // Direct USB / Non-BLE transmission fallback via plugin
        await FlutterThermalPrinter.instance.printData(raw, bytes.toList());
      }

      final duration = DateTime.now().difference(startTime);
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: duration,
        isSuccess: true,
      );
    } catch (e, st) {
      final duration = DateTime.now().difference(startTime);
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: duration,
        isSuccess: false,
        exceptionType: e.runtimeType.toString(),
        exceptionMessage: '$e\n$st',
      );
    }
  }

  @override
  void dispose() {
    _pluginSubscription?.cancel();
    _streamController.close();
  }

  static DiscoveredPrinter _mapPluginPrinter(Printer p) {
    DiscoveredConnectionType type;
    switch (p.connectionType) {
      case ConnectionType.BLE:
        type = DiscoveredConnectionType.ble;
      case ConnectionType.USB:
        type = DiscoveredConnectionType.usb;
      case ConnectionType.NETWORK:
        type = DiscoveredConnectionType.network;
      default:
        type = DiscoveredConnectionType.unknown;
    }

    return DiscoveredPrinter(
      id: p.uniqueId.isNotEmpty
          ? p.uniqueId
          : (p.address ?? p.name ?? 'unknown'),
      name: p.name != null && p.name!.isNotEmpty ? p.name! : 'Unknown Device',
      connectionType: type,
      isConnected: p.isConnected ?? false,
      rawDevice: p,
    );
  }
}

/// Mock transport for testing and headless verification.
class MockHardwarePrinterTransport implements HardwarePrinterTransport {
  final StreamController<List<DiscoveredPrinter>> _streamController =
      StreamController<List<DiscoveredPrinter>>.broadcast();

  final List<DiscoveredPrinter> _printers = [];
  final List<Uint8List> transmittedBytes = [];
  bool simulateTransportFailure = false;
  String? failureErrorMessage;
  DiscoveredPrinter? connectedPrinter;

  MockHardwarePrinterTransport({List<DiscoveredPrinter>? initialPrinters}) {
    if (initialPrinters != null) {
      _printers.addAll(initialPrinters);
    }
  }

  @override
  Stream<List<DiscoveredPrinter>> get printersStream async* {
    yield List.unmodifiable(_printers);
    yield* _streamController.stream;
  }

  void emitPrinters(List<DiscoveredPrinter> printers) {
    _printers
      ..clear()
      ..addAll(printers);
    _streamController.add(List.unmodifiable(_printers));
  }

  @override
  Future<void> startScan({bool ble = true, bool usb = true}) async {
    _streamController.add(List.unmodifiable(_printers));
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> connect(DiscoveredPrinter printer) async {
    connectedPrinter = printer.copyWith(isConnected: true);
    final idx = _printers.indexWhere((p) => p.id == printer.id);
    if (idx >= 0) {
      _printers[idx] = connectedPrinter!;
    }
    _streamController.add(List.unmodifiable(_printers));
    return true;
  }

  @override
  Future<void> disconnect(DiscoveredPrinter printer) async {
    if (connectedPrinter?.id == printer.id) {
      connectedPrinter = null;
    }
    final idx = _printers.indexWhere((p) => p.id == printer.id);
    if (idx >= 0) {
      _printers[idx] = _printers[idx].copyWith(isConnected: false);
    }
    _streamController.add(List.unmodifiable(_printers));
  }

  @override
  Future<WriteDiagnosticInfo> write(
    DiscoveredPrinter printer,
    Uint8List bytes,
  ) async {
    final startTime = DateTime.now();
    final hexPreview = WriteDiagnosticInfo.formatHex(bytes);
    final sha = calculateSha256(bytes);

    if (!printer.isConnected) {
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: const Duration(milliseconds: 1),
        isSuccess: false,
        exceptionType: 'StateError',
        exceptionMessage: 'Printer is not connected.',
      );
    }

    if (simulateTransportFailure) {
      return WriteDiagnosticInfo(
        byteCount: bytes.length,
        hexPreview: hexPreview,
        sha256: sha,
        startTime: startTime,
        duration: const Duration(milliseconds: 5),
        isSuccess: false,
        exceptionType: 'SocketException',
        exceptionMessage: failureErrorMessage ??
            'Simulated BLE write timeout / characteristic not found',
      );
    }

    transmittedBytes.add(bytes);
    return WriteDiagnosticInfo(
      byteCount: bytes.length,
      hexPreview: hexPreview,
      sha256: sha,
      startTime: startTime,
      duration: const Duration(milliseconds: 2),
      isSuccess: true,
    );
  }

  @override
  void dispose() {
    _streamController.close();
  }
}
