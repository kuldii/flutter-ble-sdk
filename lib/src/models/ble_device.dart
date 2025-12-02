/// BLE Device model
class BleDevice {
  final String id;
  final String name;
  final int rssi;

  const BleDevice({required this.id, required this.name, required this.rssi});

  factory BleDevice.fromMap(Map<String, dynamic> map) {
    return BleDevice(id: map['id'] as String, name: map['name'] as String? ?? 'Unknown', rssi: map['rssi'] as int? ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'rssi': rssi};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BleDevice(id: $id, name: $name, rssi: $rssi)';
}
