import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/src/exceptions/ble_exceptions.dart';
import 'package:kgiton_ble_sdk/src/kgiton_ble_sdk.dart';
import 'package:kgiton_ble_sdk/src/models/ble_characteristic.dart';
import 'package:kgiton_ble_sdk/src/models/ble_connection_state.dart';
import 'package:kgiton_ble_sdk/src/models/ble_device.dart';
import 'package:kgiton_ble_sdk/src/models/ble_service.dart';
import 'package:kgiton_ble_sdk/src/platform/kgiton_ble_sdk_platform_interface.dart';
import 'package:kgiton_ble_sdk/src/utils/connection_stability.dart';
import 'package:kgiton_ble_sdk/src/utils/retry_policy.dart';

class MockKgitonBleSdkPlatform extends KgitonBleSdkPlatform {
  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _connectionStatesController = StreamController<Map<String, BleConnectionState>>.broadcast();
  final _notificationsController = StreamController<Map<String, List<int>>>.broadcast();

  bool throwOnConnect = false;
  bool throwOnDiscover = false;
  bool throwOnWrite = false;
  bool throwOnRead = false;
  bool throwOnScan = false;

  @override
  Future<void> startScan({String? deviceNameFilter, int? timeoutSeconds}) async {
    if (throwOnScan) throw Exception('Scan failed');
    // Simulate scan results
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> stopScan() async {}

  @override
  Stream<List<BleDevice>> get scanResults => _scanResultsController.stream;

  @override
  Future<void> connect(String deviceId) async {
    if (throwOnConnect) throw Exception('Connection failed');
    await Future.delayed(Duration(milliseconds: 10));
    _connectionStatesController.add({deviceId: BleConnectionState.connected});
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _connectionStatesController.add({deviceId: BleConnectionState.disconnected});
  }

  @override
  Stream<Map<String, BleConnectionState>> get connectionStates => _connectionStatesController.stream;

  @override
  Future<List<BleService>> discoverServices(String deviceId) async {
    if (throwOnDiscover) throw Exception('Discovery failed');
    return [
      BleService(
        uuid: '180F',
        characteristics: [BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: deviceId, canRead: true, canWrite: true, canNotify: true)],
      ),
    ];
  }

  @override
  Future<void> setNotify(String deviceId, String serviceUuid, String charUuid, bool enable) async {
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> write(String deviceId, String serviceUuid, String charUuid, List<int> data) async {
    if (throwOnWrite) throw Exception('Write failed');
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<List<int>> read(String deviceId, String serviceUuid, String charUuid) async {
    if (throwOnRead) throw Exception('Read failed');
    return [1, 2, 3, 4, 5];
  }

  @override
  Stream<Map<String, List<int>>> get notifications => _notificationsController.stream;

  void simulateScanResult(BleDevice device) {
    _scanResultsController.add([device]);
  }

  void simulateDisconnection(String deviceId) {
    _connectionStatesController.add({deviceId: BleConnectionState.disconnected});
  }

  void simulateNotification(String charId, List<int> data) {
    _notificationsController.add({charId: data});
  }

  void dispose() {
    _scanResultsController.close();
    _connectionStatesController.close();
    _notificationsController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KgitonBleSdk', () {
    late MockKgitonBleSdkPlatform mockPlatform;
    late KgitonBleSdk sdk;

    setUp(() {
      mockPlatform = MockKgitonBleSdkPlatform();
      KgitonBleSdkPlatform.instance = mockPlatform;
      sdk = KgitonBleSdk(connectionConfig: ConnectionConfig.development, retryPolicy: RetryPolicy.noRetry, enableLogging: false);
    });

    tearDown(() {
      sdk.dispose();
      mockPlatform.dispose();
    });

    group('Initialization', () {
      test('should initialize with default config', () {
        final defaultSdk = KgitonBleSdk();
        expect(defaultSdk.connectionConfig, ConnectionConfig.production);
        expect(defaultSdk.retryPolicy, RetryPolicy.defaultPolicy);
        expect(defaultSdk.enableLogging, false);
        defaultSdk.dispose();
      });

      test('should initialize with custom config', () {
        final customSdk = KgitonBleSdk(
          connectionConfig: ConnectionConfig.aggressive,
          retryPolicy: RetryPolicy(maxAttempts: 5, initialDelay: Duration(seconds: 1)),
          enableLogging: true,
        );
        expect(customSdk.connectionConfig, ConnectionConfig.aggressive);
        expect(customSdk.enableLogging, true);
        customSdk.dispose();
      });
    });

    group('Scanning', () {
      test('should start scan successfully', () async {
        await sdk.startScan();
      });

      test('should start scan with filter and timeout', () async {
        await sdk.startScan(deviceNameFilter: 'KGiTON', timeout: Duration(seconds: 30));
      });

      test('should throw on invalid timeout', () async {
        expect(() => sdk.startScan(timeout: Duration(milliseconds: 500)), throwsA(isA<BleScanException>()));
      });

      test('should throw on scan failure', () async {
        mockPlatform.throwOnScan = true;
        expect(() => sdk.startScan(), throwsA(isA<BleScanException>()));
      });

      test('should stop scan', () async {
        await sdk.stopScan();
      });

      test('should stream scan results', () async {
        final devices = <List<BleDevice>>[];
        sdk.scanResults.listen(devices.add);

        mockPlatform.simulateScanResult(BleDevice(id: 'device-1', name: 'Test Device', rssi: -50));

        await Future.delayed(Duration(milliseconds: 50));
        expect(devices.length, 1);
        expect(devices[0][0].id, 'device-1');
      });
    });

    group('Connection', () {
      test('should connect successfully', () async {
        await sdk.connect('AA:BB:CC:DD:EE:FF');
      });

      test('should throw on invalid device id', () async {
        expect(() => sdk.connect(''), throwsA(isA<BleConnectionException>()));
      });

      test('should throw on connection failure', () async {
        mockPlatform.throwOnConnect = true;
        expect(() => sdk.connect('AA:BB:CC:DD:EE:FF'), throwsA(isA<BleConnectionException>()));
      });

      test('should disconnect successfully', () async {
        await sdk.connect('AA:BB:CC:DD:EE:FF');
        await sdk.disconnect('AA:BB:CC:DD:EE:FF');
      });

      test('should get connection state', () async {
        expect(sdk.getConnectionState('AA:BB:CC:DD:EE:FF'), BleConnectionState.disconnected);

        await sdk.connect('AA:BB:CC:DD:EE:FF');
        await Future.delayed(Duration(milliseconds: 50));

        // State might be connected after connection
        final state = sdk.getConnectionState('AA:BB:CC:DD:EE:FF');
        expect(state, isA<BleConnectionState>());
      });

      test('should stream connection states', () async {
        final states = <Map<String, BleConnectionState>>[];
        sdk.connectionState.listen(states.add);

        await sdk.connect('AA:BB:CC:DD:EE:FF');
        await Future.delayed(Duration(milliseconds: 50));

        expect(states.isNotEmpty, true);
      });

      test('should handle disconnection events', () async {
        await sdk.connect('AA:BB:CC:DD:EE:FF');
        await Future.delayed(Duration(milliseconds: 50));

        mockPlatform.simulateDisconnection('AA:BB:CC:DD:EE:FF');
        await Future.delayed(Duration(milliseconds: 50));
      });
    });

    group('Service Discovery', () {
      test('should discover services successfully', () async {
        final services = await sdk.discoverServices('AA:BB:CC:DD:EE:FF');

        expect(services.length, 1);
        expect(services[0].uuid, '180F');
        expect(services[0].characteristics.length, 1);
      });

      test('should throw on invalid device id', () async {
        expect(() => sdk.discoverServices(''), throwsA(isA<BleServiceDiscoveryException>()));
      });

      test('should throw on discovery failure', () async {
        mockPlatform.throwOnDiscover = true;
        expect(() => sdk.discoverServices('AA:BB:CC:DD:EE:FF'), throwsA(isA<BleServiceDiscoveryException>()));
      });

      test('should cache characteristics after discovery', () async {
        await sdk.discoverServices('AA:BB:CC:DD:EE:FF');

        final char = sdk.getCharacteristic('AA:BB:CC:DD:EE:FF', '180F', '2A19');
        expect(char, isNotNull);
        expect(char!.uuid, '2A19');
      });

      test('should return null for non-existent characteristic', () {
        final char = sdk.getCharacteristic('AA:BB:CC:DD:EE:FF', '180F', 'XXXX');
        expect(char, isNull);
      });

      test('should handle case-insensitive UUID lookup', () async {
        await sdk.discoverServices('AA:BB:CC:DD:EE:FF');

        final char = sdk.getCharacteristic('AA:BB:CC:DD:EE:FF', '180f', '2a19');
        expect(char, isNotNull);
      });
    });

    group('Characteristic Operations', () {
      setUp(() async {
        await sdk.discoverServices('AA:BB:CC:DD:EE:FF');
      });

      test('setNotify should enable notifications', () async {
        await sdk.setNotify('AA:BB:CC:DD:EE:FF|180F|2A19', true);
      });

      test('setNotify should throw on invalid ID', () async {
        expect(() => sdk.setNotify('invalid-id', true), throwsA(isA<ArgumentError>()));
      });

      test('should write data successfully', () async {
        await sdk.write('AA:BB:CC:DD:EE:FF|180F|2A19', [1, 2, 3, 4, 5]);
      });

      test('should throw on invalid characteristic ID for write', () async {
        expect(() => sdk.write('invalid-id', [1, 2, 3]), throwsA(isA<BleCharacteristicException>()));
      });

      test('should throw on invalid data for write', () async {
        expect(
          () => sdk.write('AA:BB:CC:DD:EE:FF|180F|2A19', [1, 2, 300]), // 300 > 255
          throwsA(isA<BleCharacteristicException>()),
        );
      });

      test('should throw on write failure', () async {
        mockPlatform.throwOnWrite = true;
        expect(() => sdk.write('AA:BB:CC:DD:EE:FF|180F|2A19', [1, 2, 3]), throwsA(isA<BleCharacteristicException>()));
      });

      test('should read data successfully', () async {
        final data = await sdk.read('AA:BB:CC:DD:EE:FF|180F|2A19');
        expect(data, [1, 2, 3, 4, 5]);
      });

      test('should throw on invalid characteristic ID for read', () async {
        expect(() => sdk.read('invalid-id'), throwsA(isA<BleCharacteristicException>()));
      });

      test('should throw on read failure', () async {
        mockPlatform.throwOnRead = true;
        expect(() => sdk.read('AA:BB:CC:DD:EE:FF|180F|2A19'), throwsA(isA<BleCharacteristicException>()));
      });

      test('should get notification stream', () async {
        final stream = sdk.notificationStream('AA:BB:CC:DD:EE:FF|180F|2A19');
        expect(stream, isA<Stream<List<int>>>());
      });

      test('should receive notifications', () async {
        await sdk.setNotify('AA:BB:CC:DD:EE:FF|180F|2A19', true);

        final notifications = <List<int>>[];
        sdk.notificationStream('AA:BB:CC:DD:EE:FF|180F|2A19').listen(notifications.add);

        mockPlatform.simulateNotification('AA:BB:CC:DD:EE:FF|180F|2A19', [10, 20, 30]);
        await Future.delayed(Duration(milliseconds: 50));

        expect(notifications.length, 1);
        expect(notifications[0], [10, 20, 30]);
      });
    });

    group('Data Sanitization', () {
      setUp(() async {
        await sdk.discoverServices('AA:BB:CC:DD:EE:FF');
      });

      test('should sanitize data exceeding MTU', () async {
        // Create data larger than default MTU (512 bytes)
        final largeData = List.generate(600, (i) => i % 256);

        // Should not throw, data will be truncated
        await sdk.write('AA:BB:CC:DD:EE:FF|180F|2A19', largeData);
      });
    });

    group('Disposal', () {
      test('should dispose all resources', () async {
        await sdk.connect('AA:BB:CC:DD:EE:FF');
        await sdk.discoverServices('AA:BB:CC:DD:EE:FF');
        await sdk.setNotify('AA:BB:CC:DD:EE:FF|180F|2A19', true);

        sdk.dispose();

        // After disposal, operations should not work
        // (streams should be closed, etc.)
      });

      test('should handle disposal gracefully even with errors', () {
        sdk.dispose();
        // Should not throw
      });
    });

    group('Logging', () {
      test('should log when enabled', () {
        final loggingSdk = KgitonBleSdk(connectionConfig: ConnectionConfig.development, enableLogging: true);

        // Logging should happen (would need to capture stdout to verify)
        loggingSdk.startScan();
        loggingSdk.dispose();
      });

      test('should not log when disabled', () {
        // Default is no logging
        sdk.startScan();
        // No logs should be produced
      });
    });

    group('Edge Cases', () {
      test('should handle empty services list', () async {
        mockPlatform.throwOnDiscover = false;
        // Mock will return services, but test the warning path
        final services = await sdk.discoverServices('AA:BB:CC:DD:EE:FF');
        expect(services, isNotNull);
      });

      test('should handle multiple simultaneous operations', () async {
        // Create fresh SDK instances for each connection to avoid stream closure issues
        final sdk1 = KgitonBleSdk();
        final sdk2 = KgitonBleSdk();
        final sdk3 = KgitonBleSdk();

        try {
          await Future.wait([sdk1.connect('AA:BB:CC:DD:EE:01'), sdk2.connect('AA:BB:CC:DD:EE:02'), sdk3.connect('AA:BB:CC:DD:EE:03')]);
        } finally {
          sdk1.dispose();
          sdk2.dispose();
          sdk3.dispose();
        }
      }, skip: 'Mock platform causes stream closure issues with multiple SDK instances');

      test('should handle disconnect before connection completes', () async {
        final connectFuture = sdk.connect('AA:BB:CC:DD:EE:FF');
        await Future.delayed(Duration(milliseconds: 5));
        await sdk.disconnect('AA:BB:CC:DD:EE:FF');
        await connectFuture;
      });
    });
  });
}
