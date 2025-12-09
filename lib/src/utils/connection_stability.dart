import 'dart:async';

/// Configuration for connection stability features
class ConnectionConfig {
  /// Enable automatic reconnection on disconnect
  final bool autoReconnect;

  /// Maximum reconnection attempts
  final int maxReconnectAttempts;

  /// Initial reconnection delay
  final Duration reconnectDelay;

  /// Connection timeout
  final Duration connectionTimeout;

  /// Enable keep-alive mechanism
  final bool enableKeepAlive;

  /// Keep-alive interval (send ping to detect connection loss)
  final Duration keepAliveInterval;

  /// Maximum time without response before considering connection dead
  final Duration maxIdleTime;

  const ConnectionConfig({
    this.autoReconnect = true,
    this.maxReconnectAttempts = 3,
    this.reconnectDelay = const Duration(seconds: 2),
    this.connectionTimeout = const Duration(seconds: 10),
    this.enableKeepAlive = false,
    this.keepAliveInterval = const Duration(seconds: 30),
    this.maxIdleTime = const Duration(seconds: 60),
  });

  /// Default configuration for production
  static const production = ConnectionConfig(
    autoReconnect: true,
    maxReconnectAttempts: 3,
    reconnectDelay: Duration(seconds: 2),
    connectionTimeout: Duration(seconds: 10),
    enableKeepAlive: true,
    keepAliveInterval: Duration(seconds: 30),
    maxIdleTime: Duration(seconds: 60),
  );

  /// Configuration for testing/development
  static const development = ConnectionConfig(
    autoReconnect: false,
    maxReconnectAttempts: 1,
    reconnectDelay: Duration(seconds: 1),
    connectionTimeout: Duration(seconds: 5),
    enableKeepAlive: false,
  );

  /// Aggressive reconnection for critical applications
  static const aggressive = ConnectionConfig(
    autoReconnect: true,
    maxReconnectAttempts: 5,
    reconnectDelay: Duration(milliseconds: 500),
    connectionTimeout: Duration(seconds: 15),
    enableKeepAlive: true,
    keepAliveInterval: Duration(seconds: 15),
    maxIdleTime: Duration(seconds: 30),
  );
}

/// Manages automatic reconnection logic
class ReconnectionManager {
  final String deviceId;
  final Future<void> Function() connectFunction;
  final ConnectionConfig config;
  final void Function(String message)? onLog;

  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  final _reconnectStateController =
      StreamController<ReconnectionState>.broadcast();

  ReconnectionManager({
    required this.deviceId,
    required this.connectFunction,
    required this.config,
    this.onLog,
  });

  /// Stream of reconnection state changes
  Stream<ReconnectionState> get reconnectionState =>
      _reconnectStateController.stream;

  /// Current reconnection attempt number
  int get reconnectAttempts => _reconnectAttempts;

  /// Whether currently attempting to reconnect
  bool get isReconnecting => _isReconnecting;

  /// Handle disconnection and attempt reconnection
  Future<void> handleDisconnection() async {
    if (!config.autoReconnect || _isReconnecting) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts = 0;

    onLog?.call('Disconnected from $deviceId, starting reconnection...');
    _reconnectStateController.add(ReconnectionState.reconnecting);

    await _attemptReconnect();
  }

  Future<void> _attemptReconnect() async {
    while (_reconnectAttempts < config.maxReconnectAttempts &&
        _isReconnecting) {
      _reconnectAttempts++;

      onLog?.call(
        'Reconnection attempt $_reconnectAttempts/${config.maxReconnectAttempts}',
      );

      try {
        await connectFunction().timeout(config.connectionTimeout);

        // Success!
        onLog?.call('Reconnected successfully');
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _reconnectStateController.add(ReconnectionState.connected);
        return;
      } catch (e) {
        onLog?.call('Reconnection attempt $_reconnectAttempts failed: $e');

        if (_reconnectAttempts >= config.maxReconnectAttempts) {
          onLog?.call('Max reconnection attempts reached');
          _isReconnecting = false;
          _reconnectStateController.add(ReconnectionState.failed);
          return;
        }

        // Wait before next attempt
        await Future.delayed(config.reconnectDelay);
      }
    }
  }

  /// Reset reconnection state
  void reset() {
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _reconnectAttempts = 0;
  }

  /// Dispose resources
  void dispose() {
    reset();
    _reconnectStateController.close();
  }
}

/// Keep-alive manager to detect connection issues
class KeepAliveManager {
  final String deviceId;
  final Future<void> Function() pingFunction;
  final ConnectionConfig config;
  final void Function()? onConnectionLost;
  final void Function(String message)? onLog;

  Timer? _keepAliveTimer;
  Timer? _idleTimer;
  DateTime? _lastResponseTime;

  KeepAliveManager({
    required this.deviceId,
    required this.pingFunction,
    required this.config,
    this.onConnectionLost,
    this.onLog,
  });

  /// Start keep-alive monitoring
  void start() {
    if (!config.enableKeepAlive) return;

    stop(); // Stop any existing timers

    _lastResponseTime = DateTime.now();

    // Periodic keep-alive ping
    _keepAliveTimer = Timer.periodic(config.keepAliveInterval, (_) {
      _sendKeepAlive();
    });

    // Monitor for idle timeout
    _idleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkIdleTimeout();
    });

    onLog?.call('Keep-alive started for $deviceId');
  }

  Future<void> _sendKeepAlive() async {
    try {
      onLog?.call('Sending keep-alive ping to $deviceId');
      await pingFunction().timeout(const Duration(seconds: 5));
      recordActivity();
    } catch (e) {
      onLog?.call('Keep-alive ping failed: $e');
    }
  }

  void _checkIdleTimeout() {
    if (_lastResponseTime == null) return;

    final idleDuration = DateTime.now().difference(_lastResponseTime!);

    if (idleDuration > config.maxIdleTime) {
      onLog?.call(
        'Connection idle timeout for $deviceId (${idleDuration.inSeconds}s)',
      );
      onConnectionLost?.call();
    }
  }

  /// Record activity (call when receiving data)
  void recordActivity() {
    _lastResponseTime = DateTime.now();
  }

  /// Stop keep-alive monitoring
  void stop() {
    _keepAliveTimer?.cancel();
    _idleTimer?.cancel();
    _keepAliveTimer = null;
    _idleTimer = null;
    _lastResponseTime = null;
    onLog?.call('Keep-alive stopped for $deviceId');
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}

/// Reconnection state
enum ReconnectionState { connected, reconnecting, failed }
