import 'dart:typed_data';

/// Printer connection state.
enum ConnectionState { disconnected, connecting, connected }

/// Abstract transport interface for printer communication.
abstract class PrinterTransport {
  ConnectionState get state;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> write(Uint8List data);
  Future<Uint8List> read();
}

/// Options for chunked write.
class ChunkOptions {
  final int chunkSize;
  final int? chunkDelay;

  const ChunkOptions({this.chunkSize = 512, this.chunkDelay});
}

/// Options for write with retry.
class RetryOptions {
  final int maxRetries;
  final int initialDelay;

  const RetryOptions({this.maxRetries = 3, this.initialDelay = 500});
}

/// Write data in chunks with optional delay between chunks.
Future<void> chunkedWrite(
  PrinterTransport transport,
  Uint8List data, [
  ChunkOptions? options,
]) async {
  final opts = options ?? const ChunkOptions();
  if (data.isEmpty) return;

  for (int offset = 0; offset < data.length; offset += opts.chunkSize) {
    final end = (offset + opts.chunkSize).clamp(0, data.length);
    final chunk = data.sublist(offset, end);
    await transport.write(chunk);

    if (opts.chunkDelay != null && opts.chunkDelay! > 0 && end < data.length) {
      await Future<void>.delayed(Duration(milliseconds: opts.chunkDelay!));
    }
  }
}

/// Write data with automatic retry and reconnection.
Future<void> writeWithRetry(
  PrinterTransport transport,
  Uint8List data, [
  RetryOptions? options,
]) async {
  final opts = options ?? const RetryOptions();
  int attempt = 0;

  while (true) {
    try {
      if (transport.state != ConnectionState.connected) {
        await transport.connect();
      }
      await transport.write(data);
      return;
    } catch (e) {
      attempt++;
      if (attempt > opts.maxRetries) {
        rethrow;
      }
      // Exponential backoff
      final delay = opts.initialDelay * (1 << (attempt - 1));
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }
}

/// Standard BLE UUIDs for printer services.
class BleUuids {
  static const String service = '49535343-fe7d-4ae5-8fa9-9fafd205e455';
  static const String write = '49535343-8841-43f4-a8d4-ecbe34729bb3';
  static const String notify = '49535343-1e4d-4bd9-bb5c-a3d896a7bf33';
}

/// Convenience access for BLE UUIDs.
const bleUuids = (
  service: BleUuids.service,
  write: BleUuids.write,
  notify: BleUuids.notify,
);

/// USB vendor IDs for major printer manufacturers.
const usbVendorIds = (
  epson: 0x04B8,
  star: 0x0519,
  zebra: 0x0A5F,
  tsc: 0x1203,
  bixolon: 0x1504,
  citizen: 0x1D90,
  honeywell: 0x0C2E,
  sato: 0x0828,
);
