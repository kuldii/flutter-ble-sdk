import 'dart:async';
import 'models/ble_device.dart';
import 'models/ble_service.dart';
import 'models/ble_characteristic.dart';
import 'models/ble_connection_state.dart';
import 'platform/kgiton_ble_sdk_platform_interface.dart';

/// Main KGiTON BLE SDK class
///
/// Provides minimal BLE functionality for KGiTON Scale devices
class KgitonBleSdk {
  final _platform = KgitonBleSdkPlatform.instance;

  // Connection state tracking
  final _connectionStates = <String, BleConnectionState>{};
  final _connectionStateController = StreamController<Map<String, BleConnectionState>>.broadcast();

  // Notification streams per characteristic
  final _notificationControllers = <String, StreamController<List<int>>>{};

  // Discovered characteristics cache
  final _characteristicsCache = <String, List<BleCharacteristic>>{};

  KgitonBleSdk() {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to platform connection states
    _platform.connectionStates.listen((states) {
      _connectionStates.addAll(states);
      _connectionStateController.add(Map.from(_connectionStates));
    });

    // Listen to platform notifications and route to specific streams
    _platform.notifications.listen((notification) {
      final charId = notification.keys.first;
      final data = notification.values.first;

      if (_notificationControllers.containsKey(charId)) {
        _notificationControllers[charId]!.add(data);
      }
    });
  }

  // ============================================
  // SCANNING
  // ============================================

  /// Start scanning for BLE devices
  ///
  /// [deviceNameFilter] - Only return devices with names containing this string
  /// [timeout] - Maximum scan duration (default 15 seconds)
  Future<void> startScan({String? deviceNameFilter, Duration? timeout}) async {
    await _platform.startScan(deviceNameFilter: deviceNameFilter, timeoutSeconds: timeout?.inSeconds ?? 15);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await _platform.stopScan();
  }

  /// Stream of scan results
  Stream<List<BleDevice>> get scanResults => _platform.scanResults;

  // ============================================
  // CONNECTION
  // ============================================

  /// Connect to a BLE device
  Future<void> connect(String deviceId) async {
    await _platform.connect(deviceId);
  }

  /// Disconnect from a BLE device
  Future<void> disconnect(String deviceId) async {
    await _platform.disconnect(deviceId);
  }

  /// Get connection state for a specific device
  BleConnectionState getConnectionState(String deviceId) {
    return _connectionStates[deviceId] ?? BleConnectionState.disconnected;
  }

  /// Stream of connection state changes
  Stream<Map<String, BleConnectionState>> get connectionState => _connectionStateController.stream;

  // ============================================
  // SERVICES & CHARACTERISTICS
  // ============================================

  /// Discover services and characteristics for a connected device
  Future<List<BleService>> discoverServices(String deviceId) async {
    final services = await _platform.discoverServices(deviceId);

    // Cache characteristics for easy lookup
    final chars = <BleCharacteristic>[];
    for (final service in services) {
      chars.addAll(service.characteristics);
    }
    _characteristicsCache[deviceId] = chars;

    return services;
  }

  /// Get a characteristic by UUID
  BleCharacteristic? getCharacteristic(String deviceId, String serviceUuid, String charUuid) {
    final chars = _characteristicsCache[deviceId];
    if (chars == null) return null;

    try {
      return chars.firstWhere((c) => c.uuid.toLowerCase() == charUuid.toLowerCase() && c.serviceUuid.toLowerCase() == serviceUuid.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // CHARACTERISTICS OPERATIONS
  // ============================================

  /// Enable or disable notifications for a characteristic
  Future<void> setNotify(String characteristicId, bool enable) async {
    final parts = characteristicId.split(':');
    if (parts.length != 3) {
      throw ArgumentError('Invalid characteristic ID format. Expected: deviceId:serviceUuid:charUuid');
    }

    final deviceId = parts[0];
    final serviceUuid = parts[1];
    final charUuid = parts[2];

    await _platform.setNotify(deviceId, serviceUuid, charUuid, enable);

    // Create stream controller if enabling notifications
    if (enable && !_notificationControllers.containsKey(characteristicId)) {
      _notificationControllers[characteristicId] = StreamController<List<int>>.broadcast();
    }
  }

  /// Write data to a characteristic
  Future<void> write(String characteristicId, List<int> data) async {
    final parts = characteristicId.split(':');
    if (parts.length != 3) {
      throw ArgumentError('Invalid characteristic ID format. Expected: deviceId:serviceUuid:charUuid');
    }

    final deviceId = parts[0];
    final serviceUuid = parts[1];
    final charUuid = parts[2];

    await _platform.write(deviceId, serviceUuid, charUuid, data);
  }

  /// Read data from a characteristic
  Future<List<int>> read(String characteristicId) async {
    final parts = characteristicId.split(':');
    if (parts.length != 3) {
      throw ArgumentError('Invalid characteristic ID format. Expected: deviceId:serviceUuid:charUuid');
    }

    final deviceId = parts[0];
    final serviceUuid = parts[1];
    final charUuid = parts[2];

    return await _platform.read(deviceId, serviceUuid, charUuid);
  }

  /// Get notification stream for a characteristic
  Stream<List<int>> notificationStream(String characteristicId) {
    if (!_notificationControllers.containsKey(characteristicId)) {
      _notificationControllers[characteristicId] = StreamController<List<int>>.broadcast();
    }
    return _notificationControllers[characteristicId]!.stream;
  }

  // ============================================
  // CLEANUP
  // ============================================

  /// Dispose all resources
  void dispose() {
    _connectionStateController.close();
    for (final controller in _notificationControllers.values) {
      controller.close();
    }
    _notificationControllers.clear();
    _characteristicsCache.clear();
    _connectionStates.clear();
  }
}
