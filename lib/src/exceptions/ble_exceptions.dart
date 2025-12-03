/// Base exception for all BLE SDK errors
class BleException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  BleException(this.message, {this.originalError, this.stackTrace});

  @override
  String toString() => 'BleException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Thrown when scan operations fail
class BleScanException extends BleException {
  BleScanException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'BleScanException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Thrown when connection operations fail
class BleConnectionException extends BleException {
  final String? deviceId;

  BleConnectionException(super.message, {this.deviceId, super.originalError, super.stackTrace});

  @override
  String toString() => 'BleConnectionException: $message${deviceId != null ? ' (Device: $deviceId)' : ''}${originalError != null ? ' ($originalError)' : ''}';
}

/// Thrown when service discovery fails
class BleServiceDiscoveryException extends BleException {
  final String deviceId;

  BleServiceDiscoveryException(super.message, this.deviceId, {super.originalError, super.stackTrace});

  @override
  String toString() => 'BleServiceDiscoveryException: $message (Device: $deviceId)${originalError != null ? ' ($originalError)' : ''}';
}

/// Thrown when characteristic operations fail
class BleCharacteristicException extends BleException {
  final String? characteristicId;
  final String operation;

  BleCharacteristicException(super.message, this.operation, {this.characteristicId, super.originalError, super.stackTrace});

  @override
  String toString() => 'BleCharacteristicException: $message (Operation: $operation)${characteristicId != null ? ' (Char: $characteristicId)' : ''}${originalError != null ? ' ($originalError)' : ''}';
}

/// Thrown when operation times out
class BleTimeoutException extends BleException {
  final Duration timeout;
  final String operation;

  BleTimeoutException(this.operation, this.timeout, {super.originalError, super.stackTrace}) : super('Operation timed out after ${timeout.inSeconds}s');

  @override
  String toString() => 'BleTimeoutException: $operation timed out after ${timeout.inSeconds}s';
}

/// Thrown when Bluetooth is not available or not enabled
class BleNotAvailableException extends BleException {
  BleNotAvailableException(super.message, {super.originalError, super.stackTrace});

  @override
  String toString() => 'BleNotAvailableException: $message';
}

/// Thrown when permission is denied
class BlePermissionException extends BleException {
  final List<String> missingPermissions;

  BlePermissionException(super.message, this.missingPermissions, {super.originalError, super.stackTrace});

  @override
  String toString() => 'BlePermissionException: $message (Missing: ${missingPermissions.join(', ')})';
}
