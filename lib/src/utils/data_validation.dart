/// Data validation utilities for BLE operations
class BleDataValidator {
  /// Validate device ID format
  static bool isValidDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.isEmpty) return false;

    // Must be non-empty and contain valid characters
    // Typically BLE device IDs are MAC addresses or UUIDs
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    return macRegex.hasMatch(deviceId) || uuidRegex.hasMatch(deviceId) || deviceId.length >= 12; // Allow other formats
  }

  /// Validate UUID format
  static bool isValidUuid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;

    // Support both 16-bit (4 chars) and 128-bit UUIDs
    final shortUuidRegex = RegExp(r'^[0-9a-fA-F]{4}$');
    final fullUuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    return shortUuidRegex.hasMatch(uuid) || fullUuidRegex.hasMatch(uuid);
  }

  /// Validate characteristic ID format (deviceId:serviceUuid:charUuid)
  static bool isValidCharacteristicId(String? charId) {
    if (charId == null || charId.isEmpty) return false;

    final parts = charId.split(':');
    if (parts.length != 3) return false;

    return isValidDeviceId(parts[0]) && isValidUuid(parts[1]) && isValidUuid(parts[2]);
  }

  /// Validate byte array data
  static bool isValidData(List<int>? data) {
    if (data == null || data.isEmpty) return false;

    // Check all values are valid bytes (0-255)
    return data.every((byte) => byte >= 0 && byte <= 255);
  }

  /// Sanitize device name (remove invalid characters)
  static String sanitizeDeviceName(String name) {
    // Remove null characters and control characters
    return name.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  }

  /// Validate scan timeout
  static bool isValidTimeout(Duration? timeout) {
    if (timeout == null) return false;

    // Timeout should be between 1 second and 5 minutes
    return timeout.inSeconds >= 1 && timeout.inSeconds <= 300;
  }
}

/// Simple checksum calculator for data integrity
class ChecksumCalculator {
  /// Calculate simple XOR checksum
  static int calculateXor(List<int> data) {
    int checksum = 0;
    for (final byte in data) {
      checksum ^= byte;
    }
    return checksum;
  }

  /// Calculate sum checksum with modulo
  static int calculateSum(List<int> data, {int modulo = 256}) {
    int sum = 0;
    for (final byte in data) {
      sum += byte;
    }
    return sum % modulo;
  }

  /// Validate data with XOR checksum (assumes last byte is checksum)
  static bool validateXor(List<int> data) {
    if (data.length < 2) return false;

    final payload = data.sublist(0, data.length - 1);
    final receivedChecksum = data.last;
    final calculatedChecksum = calculateXor(payload);

    return receivedChecksum == calculatedChecksum;
  }

  /// Validate data with sum checksum (assumes last byte is checksum)
  static bool validateSum(List<int> data, {int modulo = 256}) {
    if (data.length < 2) return false;

    final payload = data.sublist(0, data.length - 1);
    final receivedChecksum = data.last;
    final calculatedChecksum = calculateSum(payload, modulo: modulo);

    return receivedChecksum == calculatedChecksum;
  }

  /// Add XOR checksum to data
  static List<int> addXorChecksum(List<int> data) {
    final checksum = calculateXor(data);
    return [...data, checksum];
  }

  /// Add sum checksum to data
  static List<int> addSumChecksum(List<int> data, {int modulo = 256}) {
    final checksum = calculateSum(data, modulo: modulo);
    return [...data, checksum];
  }
}

/// Data sanitizer for BLE operations
class BleDataSanitizer {
  /// Ensure data doesn't exceed maximum MTU size
  static List<int> ensureMtuLimit(List<int> data, {int maxMtu = 512}) {
    if (data.length <= maxMtu) return data;
    return data.sublist(0, maxMtu);
  }

  /// Remove null terminators from string data
  static List<int> removeNullTerminators(List<int> data) {
    return data.where((byte) => byte != 0).toList();
  }

  /// Pad data to specific length
  static List<int> padToLength(List<int> data, int length, {int paddingByte = 0}) {
    if (data.length >= length) return data;

    return [...data, ...List.filled(length - data.length, paddingByte)];
  }

  /// Convert string to safe byte array
  static List<int> stringToSafeBytes(String str, {int? maxLength}) {
    var bytes = str.codeUnits;

    if (maxLength != null && bytes.length > maxLength) {
      bytes = bytes.sublist(0, maxLength);
    }

    return bytes;
  }

  /// Convert byte array to string with error handling
  static String safeBytesToString(List<int> bytes) {
    try {
      // Remove null bytes and invalid UTF-8 sequences
      final validBytes = bytes.where((b) => b != 0 && (b >= 32 && b <= 126 || b >= 128)).toList();
      return String.fromCharCodes(validBytes).trim();
    } catch (e) {
      // Fallback: return hex representation
      return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    }
  }
}
