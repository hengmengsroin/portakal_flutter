import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:portakal_flutter/src/transport.dart';

/// Mock transport for testing.
class MockTransport implements PrinterTransport {
  @override
  ConnectionState state;

  final List<Uint8List> written = [];
  int connectCalls = 0;
  int _failsRemaining;

  MockTransport({int failCount = 0})
    : state = ConnectionState.connected,
      _failsRemaining = failCount;

  @override
  Future<void> connect() async {
    connectCalls++;
    state = ConnectionState.connected;
  }

  @override
  Future<void> disconnect() async {
    state = ConnectionState.disconnected;
  }

  @override
  Future<void> write(Uint8List data) async {
    if (_failsRemaining > 0) {
      _failsRemaining--;
      throw Exception('Write failed');
    }
    written.add(Uint8List.fromList(data));
  }

  @override
  Future<Uint8List> read() async {
    return Uint8List(0);
  }
}

void main() {
  group('chunkedWrite', () {
    test('writes small data in one chunk', () async {
      final transport = MockTransport();
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      await chunkedWrite(
        transport,
        data,
        ChunkOptions(chunkSize: 512, chunkDelay: 0),
      );
      expect(transport.written, hasLength(1));
      expect(transport.written[0], equals(data));
    });

    test('splits large data into chunks', () async {
      final transport = MockTransport();
      final data = Uint8List(100);
      await chunkedWrite(
        transport,
        data,
        ChunkOptions(chunkSize: 30, chunkDelay: 0),
      );
      expect(transport.written, hasLength(4)); // 30+30+30+10
      expect(transport.written[0].length, equals(30));
      expect(transport.written[3].length, equals(10));
    });

    test('preserves all data across chunks', () async {
      final transport = MockTransport();
      final data = Uint8List(50);
      for (int i = 0; i < 50; i++) {
        data[i] = i;
      }

      await chunkedWrite(
        transport,
        data,
        ChunkOptions(chunkSize: 20, chunkDelay: 0),
      );

      final reassembled = <int>[];
      for (final chunk in transport.written) {
        reassembled.addAll(chunk);
      }
      expect(reassembled, equals(data.toList()));
    });

    test('handles empty data', () async {
      final transport = MockTransport();
      await chunkedWrite(transport, Uint8List(0), ChunkOptions(chunkSize: 20));
      expect(transport.written, hasLength(0));
    });
  });

  group('writeWithRetry', () {
    test('writes successfully on first attempt', () async {
      final transport = MockTransport();
      final data = Uint8List.fromList([1, 2, 3]);
      await writeWithRetry(
        transport,
        data,
        RetryOptions(maxRetries: 3, initialDelay: 1),
      );
      expect(transport.written, hasLength(1));
    });

    test('retries on failure and succeeds', () async {
      final transport = MockTransport(failCount: 2);
      final data = Uint8List.fromList([1, 2, 3]);
      await writeWithRetry(
        transport,
        data,
        RetryOptions(maxRetries: 3, initialDelay: 1),
      );
      expect(transport.written, hasLength(1));
    });

    test('throws after max retries exceeded', () async {
      final transport = MockTransport(failCount: 10);
      final data = Uint8List.fromList([1]);
      expect(
        () => writeWithRetry(
          transport,
          data,
          RetryOptions(maxRetries: 2, initialDelay: 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('reconnects if disconnected', () async {
      final transport = MockTransport();
      transport.state = ConnectionState.disconnected;
      final data = Uint8List.fromList([1]);
      await writeWithRetry(
        transport,
        data,
        RetryOptions(maxRetries: 1, initialDelay: 1),
      );
      expect(transport.connectCalls, equals(1));
    });
  });

  group('constants', () {
    test('BLE_UUIDS has standard service UUID', () {
      expect(bleUuids.service, equals('49535343-fe7d-4ae5-8fa9-9fafd205e455'));
    });

    test('USB_VENDOR_IDS has major manufacturers', () {
      expect(usbVendorIds.epson, equals(0x04B8));
      expect(usbVendorIds.star, equals(0x0519));
      expect(usbVendorIds.zebra, equals(0x0A5F));
      expect(usbVendorIds.tsc, equals(0x1203));
      expect(usbVendorIds.bixolon, equals(0x1504));
      expect(usbVendorIds.citizen, equals(0x1D90));
    });
  });
}
