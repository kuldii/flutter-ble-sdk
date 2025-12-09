import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/src/models/ble_characteristic.dart';
import 'package:kgiton_ble_sdk/src/models/ble_connection_state.dart';
import 'package:kgiton_ble_sdk/src/models/ble_device.dart';
import 'package:kgiton_ble_sdk/src/models/ble_service.dart';

void main() {
  group('BleDevice', () {
    test('should create device with all properties', () {
      final device = BleDevice(id: 'test-id', name: 'Test Device', rssi: -50);

      expect(device.id, 'test-id');
      expect(device.name, 'Test Device');
      expect(device.rssi, -50);
    });

    test('should create device from map', () {
      final map = {'id': 'test-id', 'name': 'Test Device', 'rssi': -50};
      final device = BleDevice.fromMap(map);

      expect(device.id, 'test-id');
      expect(device.name, 'Test Device');
      expect(device.rssi, -50);
    });

    test('should use default values when map has missing fields', () {
      final map = {'id': 'test-id'};
      final device = BleDevice.fromMap(map);

      expect(device.id, 'test-id');
      expect(device.name, 'Unknown');
      expect(device.rssi, 0);
    });

    test('should convert device to map', () {
      final device = BleDevice(id: 'test-id', name: 'Test Device', rssi: -50);
      final map = device.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Device');
      expect(map['rssi'], -50);
    });

    test('should compare devices by id', () {
      final device1 = BleDevice(id: 'test-id', name: 'Device 1', rssi: -50);
      final device2 = BleDevice(id: 'test-id', name: 'Device 2', rssi: -60);
      final device3 = BleDevice(id: 'other-id', name: 'Device 3', rssi: -50);

      expect(device1, equals(device2)); // Same id
      expect(device1, isNot(equals(device3))); // Different id
      expect(device1 == device1, true); // Identity
    });

    test('should have consistent hashCode', () {
      final device1 = BleDevice(id: 'test-id', name: 'Device 1', rssi: -50);
      final device2 = BleDevice(id: 'test-id', name: 'Device 2', rssi: -60);

      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('should have correct string representation', () {
      final device = BleDevice(id: 'test-id', name: 'Test Device', rssi: -50);
      final str = device.toString();

      expect(str, contains('test-id'));
      expect(str, contains('Test Device'));
      expect(str, contains('-50'));
    });
  });

  group('BleService', () {
    test('should create service with characteristics', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');
      final service = BleService(uuid: '180F', characteristics: [char]);

      expect(service.uuid, '180F');
      expect(service.characteristics.length, 1);
      expect(service.characteristics.first.uuid, '2A19');
    });

    test('should create service from map', () {
      final map = {
        'uuid': '180F',
        'characteristics': [
          {'uuid': '2A19', 'serviceUuid': '180F', 'deviceId': 'device-id'},
        ],
      };
      final service = BleService.fromMap(map);

      expect(service.uuid, '180F');
      expect(service.characteristics.length, 1);
    });

    test('should handle empty characteristics list', () {
      final map = {'uuid': '180F'};
      final service = BleService.fromMap(map);

      expect(service.uuid, '180F');
      expect(service.characteristics.length, 0);
    });

    test('should convert service to map', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');
      final service = BleService(uuid: '180F', characteristics: [char]);
      final map = service.toMap();

      expect(map['uuid'], '180F');
      expect((map['characteristics'] as List).length, 1);
    });

    test('should have correct string representation', () {
      final service = BleService(uuid: '180F', characteristics: []);
      final str = service.toString();

      expect(str, contains('180F'));
      expect(str, contains('0'));
    });
  });

  group('BleCharacteristic', () {
    test('should create characteristic with all properties', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id', canRead: true, canWrite: true, canNotify: true);

      expect(char.uuid, '2A19');
      expect(char.serviceUuid, '180F');
      expect(char.deviceId, 'device-id');
      expect(char.canRead, true);
      expect(char.canWrite, true);
      expect(char.canNotify, true);
    });

    test('should use default false for permissions', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');

      expect(char.canRead, false);
      expect(char.canWrite, false);
      expect(char.canNotify, false);
    });

    test('should create characteristic from map', () {
      final map = {'uuid': '2A19', 'serviceUuid': '180F', 'deviceId': 'device-id', 'canRead': true, 'canWrite': true, 'canNotify': false};
      final char = BleCharacteristic.fromMap(map);

      expect(char.uuid, '2A19');
      expect(char.canRead, true);
      expect(char.canWrite, true);
      expect(char.canNotify, false);
    });

    test('should use defaults for missing map fields', () {
      final map = {'uuid': '2A19'};
      final char = BleCharacteristic.fromMap(map);

      expect(char.serviceUuid, '');
      expect(char.deviceId, '');
      expect(char.canRead, false);
    });

    test('should convert characteristic to map', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id', canRead: true, canWrite: false, canNotify: true);
      final map = char.toMap();

      expect(map['uuid'], '2A19');
      expect(map['canRead'], true);
      expect(map['canWrite'], false);
      expect(map['canNotify'], true);
    });

    test('should generate unique id', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');

      expect(char.id, 'device-id|180F|2A19');
    });

    test('should compare characteristics by id', () {
      final char1 = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');
      final char2 = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');
      final char3 = BleCharacteristic(uuid: '2A20', serviceUuid: '180F', deviceId: 'device-id');

      expect(char1, equals(char2));
      expect(char1, isNot(equals(char3)));
      expect(char1 == char1, true);
    });

    test('should have consistent hashCode', () {
      final char1 = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');
      final char2 = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id');

      expect(char1.hashCode, equals(char2.hashCode));
    });

    test('should have correct string representation', () {
      final char = BleCharacteristic(uuid: '2A19', serviceUuid: '180F', deviceId: 'device-id', canRead: true, canWrite: false, canNotify: true);
      final str = char.toString();

      expect(str, contains('2A19'));
      expect(str, contains('true'));
      expect(str, contains('false'));
    });
  });

  group('BleConnectionState', () {
    test('should have all connection states', () {
      expect(BleConnectionState.values.length, 4);
      expect(BleConnectionState.values, contains(BleConnectionState.disconnected));
      expect(BleConnectionState.values, contains(BleConnectionState.connecting));
      expect(BleConnectionState.values, contains(BleConnectionState.connected));
      expect(BleConnectionState.values, contains(BleConnectionState.disconnecting));
    });

    test('isConnected should return true only for connected state', () {
      expect(BleConnectionState.connected.isConnected, true);
      expect(BleConnectionState.connecting.isConnected, false);
      expect(BleConnectionState.disconnected.isConnected, false);
      expect(BleConnectionState.disconnecting.isConnected, false);
    });

    test('isDisconnected should return true only for disconnected state', () {
      expect(BleConnectionState.disconnected.isDisconnected, true);
      expect(BleConnectionState.connecting.isDisconnected, false);
      expect(BleConnectionState.connected.isDisconnected, false);
      expect(BleConnectionState.disconnecting.isDisconnected, false);
    });
  });
}
