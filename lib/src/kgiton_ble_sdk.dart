import 'dart:async';
import 'models/ble_device.dart';
import 'models/ble_service.dart';
import 'models/ble_characteristic.dart';
import 'models/ble_connection_state.dart';
import 'platform/kgiton_ble_sdk_platform_interface.dart';
import 'exceptions/ble_exceptions.dart';
import 'utils/retry_policy.dart';
import 'utils/connection_stability.dart';
import 'utils/data_validation.dart';

/// Main KGiTON BLE SDK class
///
/// Provides robust BLE functionality for KGiTON Scale devices with:
/// - Automatic reconnection
/// - Retry logic with exponential backoff
/// - Data validation and sanitization
/// - Connection stability monitoring
/// - Comprehensive error handling
class KgitonBleSdk {
  final _platform = KgitonBleSdkPlatform.instance;

  /// Configuration for connection stability
  final ConnectionConfig connectionConfig;

  /// Retry policy for operations
  final RetryPolicy retryPolicy;

  // Connection state tracking
  final _connectionStates = <String, BleConnectionState>{};
  final _connectionStateController = StreamController<Map<String, BleConnectionState>>.broadcast();

  // Notification streams per characteristic
  final _notificationControllers = <String, StreamController<List<int>>>{};

  // Discovered characteristics cache
  final _characteristicsCache = <String, List<BleCharacteristic>>{};

  // Reconnection managers per device
  final _reconnectionManagers = <String, ReconnectionManager>{};

  // Keep-alive managers per device
  final _keepAliveManagers = <String, KeepAliveManager>{};

  /// Enable debug logging
  final bool enableLogging;

  KgitonBleSdk({this.connectionConfig = ConnectionConfig.production, this.retryPolicy = RetryPolicy.defaultPolicy, this.enableLogging = false}) {
    _setupListeners();
  }

  void _log(String message) {
    if (enableLogging) {
      print('[KGiTON BLE SDK] $message');
    }
  }

  void _setupListeners() {
    // Listen to platform connection states
    _platform.connectionStates.listen((states) {
      _connectionStates.addAll(states);
      _connectionStateController.add(Map.from(_connectionStates));

      // Handle disconnections with auto-reconnect
      for (final entry in states.entries) {
        final deviceId = entry.key;
        final state = entry.value;

        if (state.isDisconnected && _reconnectionManagers.containsKey(deviceId)) {
          _log('Device $deviceId disconnected, triggering reconnection');
          _reconnectionManagers[deviceId]!.handleDisconnection();
        }
      }
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
  ///
  /// Throws [BleScanException] if scan fails
  Future<void> startScan({String? deviceNameFilter, Duration? timeout}) async {
    final scanTimeout = timeout ?? const Duration(seconds: 15);

    // Validate timeout
    if (!BleDataValidator.isValidTimeout(scanTimeout)) {
      throw BleScanException('Invalid scan timeout: must be between 1s and 300s');
    }

    _log('Starting scan (filter: ${deviceNameFilter ?? 'none'}, timeout: ${scanTimeout.inSeconds}s)');

    try {
      await RetryExecutor.execute(
        operation: () => _platform.startScan(deviceNameFilter: deviceNameFilter, timeoutSeconds: scanTimeout.inSeconds),
        policy: RetryPolicy.noRetry, // Don't retry scan operations
        operationName: 'startScan',
      );
    } catch (e, stackTrace) {
      _log('Scan failed: $e');
      throw BleScanException('Failed to start scan', originalError: e, stackTrace: stackTrace);
    }
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

  /// Connect to a BLE device with automatic reconnection support
  ///
  /// Throws [BleConnectionException] if connection fails
  Future<void> connect(String deviceId) async {
    // Validate device ID
    if (!BleDataValidator.isValidDeviceId(deviceId)) {
      throw BleConnectionException('Invalid device ID format', deviceId: deviceId);
    }

    _log('Connecting to $deviceId...');

    try {
      await RetryExecutor.executeWithTimeout(
        operation: () => _platform.connect(deviceId),
        timeout: connectionConfig.connectionTimeout,
        policy: retryPolicy,
        operationName: 'connect',
      );

      // Setup reconnection manager
      if (connectionConfig.autoReconnect && !_reconnectionManagers.containsKey(deviceId)) {
        _reconnectionManagers[deviceId] = ReconnectionManager(
          deviceId: deviceId,
          connectFunction: () => _platform.connect(deviceId),
          config: connectionConfig,
          onLog: _log,
        );
      }

      // Setup keep-alive if enabled
      if (connectionConfig.enableKeepAlive && !_keepAliveManagers.containsKey(deviceId)) {
        _keepAliveManagers[deviceId] = KeepAliveManager(
          deviceId: deviceId,
          pingFunction: () async {
            // Implement ping by reading a dummy characteristic or checking connection state
          },
          config: connectionConfig,
          onConnectionLost: () {
            _log('Keep-alive detected connection loss for $deviceId');
            disconnect(deviceId);
          },
          onLog: _log,
        );
        _keepAliveManagers[deviceId]!.start();
      }

      _log('Connected to $deviceId successfully');
    } catch (e, stackTrace) {
      _log('Connection failed to $deviceId: $e');
      throw BleConnectionException('Failed to connect', deviceId: deviceId, originalError: e, stackTrace: stackTrace);
    }
  }

  /// Disconnect from a BLE device
  Future<void> disconnect(String deviceId) async {
    _log('Disconnecting from $deviceId');

    // Stop reconnection manager
    _reconnectionManagers[deviceId]?.dispose();
    _reconnectionManagers.remove(deviceId);

    // Stop keep-alive manager
    _keepAliveManagers[deviceId]?.dispose();
    _keepAliveManagers.remove(deviceId);

    try {
      await _platform.disconnect(deviceId);
      _log('Disconnected from $deviceId successfully');
    } catch (e) {
      _log('Disconnect error for $deviceId: $e');
      // Don't throw, just log
    }
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
  ///
  /// Throws [BleServiceDiscoveryException] if discovery fails
  Future<List<BleService>> discoverServices(String deviceId) async {
    if (!BleDataValidator.isValidDeviceId(deviceId)) {
      throw BleServiceDiscoveryException('Invalid device ID format', deviceId);
    }

    _log('Discovering services for $deviceId');

    try {
      final services = await RetryExecutor.executeWithTimeout(
        operation: () => _platform.discoverServices(deviceId),
        timeout: const Duration(seconds: 15),
        policy: retryPolicy,
        operationName: 'discoverServices',
      );

      if (services.isEmpty) {
        _log('Warning: No services discovered for $deviceId');
      }

      // Cache characteristics for easy lookup
      final chars = <BleCharacteristic>[];
      for (final service in services) {
        chars.addAll(service.characteristics);
      }
      _characteristicsCache[deviceId] = chars;

      _log('Discovered ${services.length} services, ${chars.length} characteristics for $deviceId');
      return services;
    } catch (e, stackTrace) {
      _log('Service discovery failed for $deviceId: $e');
      throw BleServiceDiscoveryException('Failed to discover services', deviceId, originalError: e, stackTrace: stackTrace);
    }
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
    final parts = characteristicId.split('|');
    if (parts.length != 3) {
      throw ArgumentError('Invalid characteristic ID format. Expected: deviceId|serviceUuid|charUuid');
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

  /// Write data to a characteristic with validation and retry
  ///
  /// Throws [BleCharacteristicException] if write fails
  Future<void> write(String characteristicId, List<int> data) async {
    // Validate characteristic ID
    if (!BleDataValidator.isValidCharacteristicId(characteristicId)) {
      throw BleCharacteristicException('Invalid characteristic ID format', 'write', characteristicId: characteristicId);
    }

    // Validate data
    if (!BleDataValidator.isValidData(data)) {
      throw BleCharacteristicException('Invalid data: contains values outside 0-255 range', 'write', characteristicId: characteristicId);
    }

    final parts = characteristicId.split('|');
    final deviceId = parts[0];
    final serviceUuid = parts[1];
    final charUuid = parts[2];

    // Sanitize data (ensure MTU limit)
    final sanitizedData = BleDataSanitizer.ensureMtuLimit(data);

    _log('Writing ${sanitizedData.length} bytes to $characteristicId');

    try {
      await RetryExecutor.executeWithTimeout(
        operation: () => _platform.write(deviceId, serviceUuid, charUuid, sanitizedData),
        timeout: const Duration(seconds: 5),
        policy: retryPolicy,
        operationName: 'write',
      );

      // Record activity for keep-alive
      _keepAliveManagers[deviceId]?.recordActivity();

      _log('Write successful to $characteristicId');
    } catch (e, stackTrace) {
      _log('Write failed to $characteristicId: $e');
      throw BleCharacteristicException('Failed to write data', 'write', characteristicId: characteristicId, originalError: e, stackTrace: stackTrace);
    }
  }

  /// Read data from a characteristic with validation and retry
  ///
  /// Throws [BleCharacteristicException] if read fails
  Future<List<int>> read(String characteristicId) async {
    // Validate characteristic ID
    if (!BleDataValidator.isValidCharacteristicId(characteristicId)) {
      throw BleCharacteristicException('Invalid characteristic ID format', 'read', characteristicId: characteristicId);
    }

    final parts = characteristicId.split('|');
    final deviceId = parts[0];
    final serviceUuid = parts[1];
    final charUuid = parts[2];

    _log('Reading from $characteristicId');

    try {
      final data = await RetryExecutor.executeWithTimeout(
        operation: () => _platform.read(deviceId, serviceUuid, charUuid),
        timeout: const Duration(seconds: 5),
        policy: retryPolicy,
        operationName: 'read',
      );

      // Record activity for keep-alive
      _keepAliveManagers[deviceId]?.recordActivity();

      _log('Read ${data.length} bytes from $characteristicId');
      return data;
    } catch (e, stackTrace) {
      _log('Read failed from $characteristicId: $e');
      throw BleCharacteristicException('Failed to read data', 'read', characteristicId: characteristicId, originalError: e, stackTrace: stackTrace);
    }
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
    _log('Disposing KGiTON BLE SDK');

    // Stop any ongoing scan
    try {
      stopScan();
    } catch (e) {
      _log('Error stopping scan during dispose: $e');
    }

    // Dispose all reconnection managers
    for (final manager in _reconnectionManagers.values) {
      manager.dispose();
    }
    _reconnectionManagers.clear();

    // Dispose all keep-alive managers
    for (final manager in _keepAliveManagers.values) {
      manager.dispose();
    }
    _keepAliveManagers.clear();

    // Close stream controllers
    _connectionStateController.close();
    for (final controller in _notificationControllers.values) {
      controller.close();
    }
    _notificationControllers.clear();

    // Clear caches
    _characteristicsCache.clear();
    _connectionStates.clear();
  }
}
