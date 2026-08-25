# Transport & Resilient I/O Guide

Portakal is strictly decoupled from physical I/O stacks. It provides pure Dart transport contracts, chunking utilities, and retry wrappers to ensure reliable transmission over Bluetooth, USB, TCP/Network, and Serial endpoints.

---

## 1. The `PrinterTransport` Contract

```dart
enum ConnectionState { disconnected, connecting, connected }

abstract class PrinterTransport {
  ConnectionState get state;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> write(Uint8List data);
  Future<Uint8List> read();
}
```

---

## 2. Implementing a TCP Network Transport

A simple TCP socket transport using pure `dart:io`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

class TcpPrinterTransport implements PrinterTransport {
  final String host;
  final int port;
  Socket? _socket;
  ConnectionState _state = ConnectionState.disconnected;

  TcpPrinterTransport({required this.host, this.port = 9100});

  @override
  ConnectionState get state => _state;

  @override
  Future<void> connect() async {
    _state = ConnectionState.connecting;
    _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
    _state = ConnectionState.connected;
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _state = ConnectionState.disconnected;
  }

  @override
  Future<void> write(Uint8List data) async {
    if (_socket == null) throw StateError('Transport not connected');
    _socket!.add(data);
    await _socket!.flush();
  }

  @override
  Future<Uint8List> read() async {
    // Read response from printer if supported
    return Uint8List(0);
  }
}
```

---

## 3. Chunked Writes (`chunkedWrite`)

Many Bluetooth Low Energy (BLE) thermal printers drop incoming data if written in bursts larger than their hardware buffer or negotiated MTU size (commonly 512 or 256 bytes).

Portakal provides `chunkedWrite()` to slice large streams with optional delays:

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

Future<void> sendLargePrintJob(PrinterTransport transport, Uint8List printBytes) async {
  await chunkedWrite(
    transport,
    printBytes,
    const ChunkOptions(
      chunkSize: 512,      // Bytes per chunk (default: 512)
      chunkDelay: 20,      // Milliseconds between chunks (optional)
    ),
  );
}
```

---

## 4. Exponential Backoff Retries (`writeWithRetry`)

For wireless or lossy connections, `writeWithRetry()` handles automatic reconnection and retries with exponential backoff:

```dart
import 'dart:typed_data';
import 'package:portakal_core/portakal_core.dart';

Future<void> sendReliableJob(PrinterTransport transport, Uint8List printBytes) async {
  await writeWithRetry(
    transport,
    printBytes,
    const RetryOptions(
      maxRetries: 3,       // Max retry attempts (default: 3)
      initialDelay: 500,   // Initial delay in ms (default: 500ms)
    ),
  );
}
```

---

## 5. Hardware Identifiers & Constants

`portakal_core` includes standard hardware constants for device discovery:

### Standard BLE Service & Characteristic UUIDs
```dart
print(BleUuids.service); // 49535343-fe7d-4ae5-8fa9-9fafd205e455
print(BleUuids.write);   // 49535343-8841-43f4-a8d4-ecbe34729bb3
print(BleUuids.notify);  // 49535343-1e4d-4bd9-bb5c-a3d896a7bf33
```

### Major Thermal Printer USB Vendor IDs (`usbVendorIds`)
```dart
print(usbVendorIds.epson);     // 0x04B8
print(usbVendorIds.zebra);     // 0x0A5F
print(usbVendorIds.tsc);       // 0x1203
print(usbVendorIds.star);      // 0x0519
print(usbVendorIds.bixolon);   // 0x1504
print(usbVendorIds.honeywell); // 0x0C2E
print(usbVendorIds.citizen);   // 0x1D90
print(usbVendorIds.sato);      // 0x0828
```
