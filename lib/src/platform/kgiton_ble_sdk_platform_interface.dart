import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../models/ble_connection_state.dart';
import 'kgiton_ble_sdk_method_channel.dart';

abstract class KgitonBleSdkPlatform extends PlatformInterface {
  KgitonBleSdkPlatform() : super(token: _token);

  static final Object _token = Object();
  static KgitonBleSdkPlatform _instance = MethodChannelKgitonBleSdk();

  static KgitonBleSdkPlatform get instance => _instance;

  static set instance(KgitonBleSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Scan
  Future<void> startScan({String? deviceNameFilter, int? timeoutSeconds}) {
    throw UnimplementedError('startScan() has not been implemented.');
  }

  Future<void> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Stream<List<BleDevice>> get scanResults {
    throw UnimplementedError('scanResults has not been implemented.');
  }

  // Connection
  Future<void> connect(String deviceId) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<void> disconnect(String deviceId) {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Stream<Map<String, BleConnectionState>> get connectionStates {
    throw UnimplementedError('connectionStates has not been implemented.');
  }

  // Services
  Future<List<BleService>> discoverServices(String deviceId) {
    throw UnimplementedError('discoverServices() has not been implemented.');
  }

  // Characteristics
  Future<void> setNotify(String deviceId, String serviceUuid, String charUuid, bool enable) {
    throw UnimplementedError('setNotify() has not been implemented.');
  }

  Future<void> write(String deviceId, String serviceUuid, String charUuid, List<int> data) {
    throw UnimplementedError('write() has not been implemented.');
  }

  Future<List<int>> read(String deviceId, String serviceUuid, String charUuid) {
    throw UnimplementedError('read() has not been implemented.');
  }

  Stream<Map<String, List<int>>> get notifications {
    throw UnimplementedError('notifications has not been implemented.');
  }
}
