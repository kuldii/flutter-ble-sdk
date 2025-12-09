import 'ble_characteristic.dart';

/// BLE Service model
class BleService {
  final String uuid;
  final List<BleCharacteristic> characteristics;

  const BleService({required this.uuid, required this.characteristics});

  factory BleService.fromMap(Map<String, dynamic> map) {
    final charsList =
        (map['characteristics'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return BleService(
      uuid: map['uuid'] as String,
      characteristics: charsList
          .map((c) => BleCharacteristic.fromMap(c))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'characteristics': characteristics.map((c) => c.toMap()).toList(),
    };
  }

  @override
  String toString() =>
      'BleService(uuid: $uuid, characteristics: ${characteristics.length})';
}
