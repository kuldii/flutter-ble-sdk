import 'dart:async';
import 'package:flutter/services.dart';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../models/ble_connection_state.dart';
import 'kgiton_ble_sdk_platform_interface.dart';

class MethodChannelKgitonBleSdk extends KgitonBleSdkPlatform {
  final _channel = const MethodChannel('kgiton_ble_sdk');
  final _eventChannel = const EventChannel('kgiton_ble_sdk/events');

  final _scanResultsController = StreamController<List<BleDevice>>.broadcast();
  final _connectionStatesController = StreamController<Map<String, BleConnectionState>>.broadcast();
  final _notificationsController = StreamController<Map<String, List<int>>>.broadcast();

  StreamSubscription? _eventSubscription;

  MethodChannelKgitonBleSdk() {
    _setupEventChannel();
  }

  void _setupEventChannel() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final map = Map<String, dynamic>.from(event as Map);
      final type = map['type'] as String;

      switch (type) {
        case 'scanResult':
          final devices = (map['devices'] as List)
              .map((d) => BleDevice.fromMap(Map<String, dynamic>.from(d)))
              .toList();
          _scanResultsController.add(devices);
          break;

        case 'connectionState':
          final deviceId = map['deviceId'] as String;
          final stateStr = map['state'] as String;
          final state = _parseConnectionState(stateStr);
          _connectionStatesController.add({deviceId: state});
          break;

        case 'notification':
          final charId = map['characteristicId'] as String;
          final data = List<int>.from(map['data'] as List);
          _notificationsController.add({charId: data});
          break;
      }
    });
  }

  BleConnectionState _parseConnectionState(String state) {
    switch (state.toLowerCase()) {
      case 'connected':
        return BleConnectionState.connected;
      case 'connecting':
        return BleConnectionState.connecting;
      case 'disconnecting':
        return BleConnectionState.disconnecting;
      default:
        return BleConnectionState.disconnected;
    }
  }

  @override
  Future<void> startScan({String? deviceNameFilter, int? timeoutSeconds}) async {
    await _channel.invokeMethod('startScan', {
      'deviceNameFilter': deviceNameFilter,
      'timeoutSeconds': timeoutSeconds ?? 15,
    });
  }

  @override
  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  @override
  Stream<List<BleDevice>> get scanResults => _scanResultsController.stream;

  @override
  Future<void> connect(String deviceId) async {
    await _channel.invokeMethod('connect', {'deviceId': deviceId});
  }

  @override
  Future<void> disconnect(String deviceId) async {
    await _channel.invokeMethod('disconnect', {'deviceId': deviceId});
  }

  @override
  Stream<Map<String, BleConnectionState>> get connectionStates => _connectionStatesController.stream;

  @override
  Future<List<BleService>> discoverServices(String deviceId) async {
    final result = await _channel.invokeMethod('discoverServices', {'deviceId': deviceId});
    final servicesList = (result as List).cast<Map<String, dynamic>>();
    return servicesList.map((s) {
      // Add deviceId to each characteristic
      final chars = (s['characteristics'] as List).cast<Map<String, dynamic>>();
      final updatedChars = chars.map((c) {
        return {
          ...c,
          'deviceId': deviceId,
          'serviceUuid': s['uuid'],
        };
      }).toList();
      
      return BleService.fromMap({
        'uuid': s['uuid'],
        'characteristics': updatedChars,
      });
    }).toList();
  }

  @override
  Future<void> setNotify(String deviceId, String serviceUuid, String charUuid, bool enable) async {
    await _channel.invokeMethod('setNotify', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': charUuid,
      'enable': enable,
    });
  }

  @override
  Future<void> write(String deviceId, String serviceUuid, String charUuid, List<int> data) async {
    await _channel.invokeMethod('write', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': charUuid,
      'data': data,
    });
  }

  @override
  Future<List<int>> read(String deviceId, String serviceUuid, String charUuid) async {
    final result = await _channel.invokeMethod('read', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': charUuid,
    });
    return List<int>.from(result as List);
  }

  @override
  Stream<Map<String, List<int>>> get notifications => _notificationsController.stream;

  void dispose() {
    _eventSubscription?.cancel();
    _scanResultsController.close();
    _connectionStatesController.close();
    _notificationsController.close();
  }
}
