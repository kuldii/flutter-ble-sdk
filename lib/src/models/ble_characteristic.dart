/// BLE Characteristic model
class BleCharacteristic {
  final String uuid;
  final String serviceUuid;
  final String deviceId;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;

  const BleCharacteristic({
    required this.uuid,
    required this.serviceUuid,
    required this.deviceId,
    this.canRead = false,
    this.canWrite = false,
    this.canNotify = false,
  });

  factory BleCharacteristic.fromMap(Map<String, dynamic> map) {
    return BleCharacteristic(
      uuid: map['uuid'] as String,
      serviceUuid: map['serviceUuid'] as String? ?? '',
      deviceId: map['deviceId'] as String? ?? '',
      canRead: map['canRead'] as bool? ?? false,
      canWrite: map['canWrite'] as bool? ?? false,
      canNotify: map['canNotify'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'serviceUuid': serviceUuid,
      'deviceId': deviceId,
      'canRead': canRead,
      'canWrite': canWrite,
      'canNotify': canNotify,
    };
  }

  /// Unique identifier for this characteristic
  /// Format: deviceId|serviceUuid|charUuid (using | to avoid conflict with MAC address :)
  String get id => '$deviceId|$serviceUuid|$uuid';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleCharacteristic && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BleCharacteristic(uuid: $uuid, read: $canRead, write: $canWrite, notify: $canNotify)';
}
