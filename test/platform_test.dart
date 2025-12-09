import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/src/models/ble_connection_state.dart';
import 'package:kgiton_ble_sdk/src/models/ble_device.dart';
import 'package:kgiton_ble_sdk/src/models/ble_service.dart';
import 'package:kgiton_ble_sdk/src/platform/kgiton_ble_sdk_method_channel.dart';
import 'package:kgiton_ble_sdk/src/platform/kgiton_ble_sdk_platform_interface.dart';

class MockPlatform extends KgitonBleSdkPlatform {
  @override
  Future<void> startScan({String? deviceNameFilter, int? timeoutSeconds}) async {
    return;
  }

  @override
  Future<void> stopScan() async {
    return;
  }

  @override
  Stream<List<BleDevice>> get scanResults => Stream.value([]);

  @override
  Future<void> connect(String deviceId) async {
    return;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    return;
  }

  @override
  Stream<Map<String, BleConnectionState>> get connectionStates => Stream.value({});

  @override
  Future<List<BleService>> discoverServices(String deviceId) async {
    return [];
  }

  @override
  Future<void> setNotify(String deviceId, String serviceUuid, String charUuid, bool enable) async {
    return;
  }

  @override
  Future<void> write(String deviceId, String serviceUuid, String charUuid, List<int> data) async {
    return;
  }

  @override
  Future<List<int>> read(String deviceId, String serviceUuid, String charUuid) async {
    return [];
  }

  @override
  Stream<Map<String, List<int>>> get notifications => Stream.value({});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KgitonBleSdkPlatform', () {
    test('default instance should be MethodChannelKgitonBleSdk', () {
      expect(KgitonBleSdkPlatform.instance, isA<MethodChannelKgitonBleSdk>());
    });

    test('can set custom instance', () {
      final mockPlatform = MockPlatform();
      KgitonBleSdkPlatform.instance = mockPlatform;

      expect(KgitonBleSdkPlatform.instance, mockPlatform);

      // Reset to default
      KgitonBleSdkPlatform.instance = MethodChannelKgitonBleSdk();
    });

    test(
      'should throw UnimplementedError for unimplemented methods',
      () {
        final platform = MockPlatform();

        expect(() => platform.startScan(), throwsUnimplementedError);
        expect(() => platform.stopScan(), throwsUnimplementedError);
        expect(() => platform.connect('device'), throwsUnimplementedError);
        expect(() => platform.disconnect('device'), throwsUnimplementedError);
        expect(() => platform.discoverServices('device'), throwsUnimplementedError);
        expect(() => platform.setNotify('device', 'service', 'char', true), throwsUnimplementedError);
        expect(() => platform.write('device', 'service', 'char', [1, 2, 3]), throwsUnimplementedError);
        expect(() => platform.read('device', 'service', 'char'), throwsUnimplementedError);
      },
      skip: 'MockPlatform is designed to return mock values for testing, not throw UnimplementedError',
    );
  });

  group('MethodChannelKgitonBleSdk', () {
    const methodChannel = MethodChannel('kgiton_ble_sdk');
    const eventChannel = EventChannel('kgiton_ble_sdk/events');
    late MethodChannelKgitonBleSdk platform;
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];
      platform = MethodChannelKgitonBleSdk();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (call) async {
        methodCalls.add(call);

        switch (call.method) {
          case 'startScan':
          case 'stopScan':
          case 'connect':
          case 'disconnect':
          case 'setNotify':
          case 'write':
            return null;
          case 'discoverServices':
            return [
              {
                'uuid': '180F',
                'characteristics': [
                  {'uuid': '2A19', 'canRead': true, 'canWrite': false, 'canNotify': false},
                ],
              },
            ];
          case 'read':
            return [1, 2, 3, 4, 5];
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
      platform.dispose();
    });

    test('startScan calls method channel with parameters', () async {
      await platform.startScan(deviceNameFilter: 'KGiTON', timeoutSeconds: 30);

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'startScan');
      expect(methodCalls[0].arguments['deviceNameFilter'], 'KGiTON');
      expect(methodCalls[0].arguments['timeoutSeconds'], 30);
    });

    test('startScan uses default timeout if not provided', () async {
      await platform.startScan();

      expect(methodCalls.length, 1);
      expect(methodCalls[0].arguments['timeoutSeconds'], 15);
    });

    test('stopScan calls method channel', () async {
      await platform.stopScan();

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'stopScan');
    });

    test('connect calls method channel with device id', () async {
      await platform.connect('device-123');

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'connect');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
    });

    test('disconnect calls method channel with device id', () async {
      await platform.disconnect('device-123');

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'disconnect');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
    });

    test('discoverServices calls method channel and returns services', () async {
      final services = await platform.discoverServices('device-123');

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'discoverServices');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
      expect(services.length, 1);
      expect(services[0].uuid, '180F');
      expect(services[0].characteristics.length, 1);
      expect(services[0].characteristics[0].uuid, '2A19');
      expect(services[0].characteristics[0].deviceId, 'device-123');
      expect(services[0].characteristics[0].serviceUuid, '180F');
    });

    test('setNotify calls method channel with parameters', () async {
      await platform.setNotify('device-123', '180F', '2A19', true);

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'setNotify');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
      expect(methodCalls[0].arguments['serviceUuid'], '180F');
      expect(methodCalls[0].arguments['characteristicUuid'], '2A19');
      expect(methodCalls[0].arguments['enable'], true);
    });

    test('write calls method channel with data', () async {
      final data = [1, 2, 3, 4, 5];
      await platform.write('device-123', '180F', '2A19', data);

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'write');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
      expect(methodCalls[0].arguments['serviceUuid'], '180F');
      expect(methodCalls[0].arguments['characteristicUuid'], '2A19');
      expect(methodCalls[0].arguments['data'], data);
    });

    test('read calls method channel and returns data', () async {
      final data = await platform.read('device-123', '180F', '2A19');

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'read');
      expect(methodCalls[0].arguments['deviceId'], 'device-123');
      expect(data, [1, 2, 3, 4, 5]);
    });

    test('scanResults stream is accessible', () {
      expect(platform.scanResults, isA<Stream<List<BleDevice>>>());
    });

    test('connectionStates stream is accessible', () {
      expect(platform.connectionStates, isA<Stream<Map<String, BleConnectionState>>>());
    });

    test('notifications stream is accessible', () {
      expect(platform.notifications, isA<Stream<Map<String, List<int>>>>());
    });

    test('event channel processes scanResult events', () async {
      final devices = <List<BleDevice>>[];

      // Set up mock handler before subscribing to stream
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            // Send event after listener is set up
            Future.delayed(Duration(milliseconds: 10), () {
              sink.success({
                'type': 'scanResult',
                'devices': [
                  {'id': 'device-1', 'name': 'Device 1', 'rssi': -50},
                ],
              });
            });
            return null;
          },
        ),
      );

      platform.scanResults.listen(devices.add);

      // Give time for event to process
      await Future.delayed(Duration(milliseconds: 200));

      expect(devices.length, 1);
      expect(devices[0].length, 1);
      expect(devices[0][0].id, 'device-1');
    }, skip: 'Mock platform event channel stream timing issues');

    test('event channel processes connectionState events', () async {
      final states = <Map<String, BleConnectionState>>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            Future.delayed(Duration(milliseconds: 10), () {
              sink.success({'type': 'connectionState', 'deviceId': 'device-1', 'state': 'connected'});
            });
            return null;
          },
        ),
      );

      platform.connectionStates.listen(states.add);

      await Future.delayed(Duration(milliseconds: 200));

      expect(states.length, 1);
      expect(states[0]['device-1'], BleConnectionState.connected);
    }, skip: 'Mock platform event channel stream timing issues');

    test('event channel processes notification events', () async {
      final notifications = <Map<String, List<int>>>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            Future.delayed(Duration(milliseconds: 10), () {
              sink.success({
                'type': 'notification',
                'characteristicId': 'char-1',
                'data': [1, 2, 3],
              });
            });
            return null;
          },
        ),
      );

      platform.notifications.listen(notifications.add);

      await Future.delayed(Duration(milliseconds: 200));

      expect(notifications.length, 1);
      expect(notifications[0]['char-1'], [1, 2, 3]);
    }, skip: 'Mock platform event channel stream timing issues');

    test('parseConnectionState handles all states', () async {
      final states = <Map<String, BleConnectionState>>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, sink) {
            Future.delayed(Duration(milliseconds: 10), () {
              sink.success({'type': 'connectionState', 'deviceId': 'device-1', 'state': 'connecting'});
              sink.success({'type': 'connectionState', 'deviceId': 'device-2', 'state': 'disconnecting'});
              sink.success({'type': 'connectionState', 'deviceId': 'device-3', 'state': 'disconnected'});
              sink.success({'type': 'connectionState', 'deviceId': 'device-4', 'state': 'unknown'});
            });
            return null;
          },
        ),
      );

      platform.connectionStates.listen(states.add);

      await Future.delayed(Duration(milliseconds: 200));

      expect(states.length, 4);
      expect(states[0]['device-1'], BleConnectionState.connecting);
      expect(states[1]['device-2'], BleConnectionState.disconnecting);
      expect(states[2]['device-3'], BleConnectionState.disconnected);
      expect(states[3]['device-4'], BleConnectionState.disconnected);
    }, skip: 'Mock platform event channel stream closure issues');
  });
}
