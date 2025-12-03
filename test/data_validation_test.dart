import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/kgiton_ble_sdk.dart';

void main() {
  group('BleDataValidator', () {
    group('Device ID Validation', () {
      test('should accept valid MAC address', () {
        expect(BleDataValidator.isValidDeviceId('AA:BB:CC:DD:EE:FF'), true);
        expect(BleDataValidator.isValidDeviceId('00:11:22:33:44:55'), true);
        expect(BleDataValidator.isValidDeviceId('aa-bb-cc-dd-ee-ff'), true);
      });

      test('should accept valid UUID', () {
        expect(BleDataValidator.isValidDeviceId('12345678-1234-1234-1234-123456789abc'), true);
      });

      test('should accept long device IDs', () {
        expect(BleDataValidator.isValidDeviceId('A1B2C3D4E5F6'), true);
      });

      test('should reject invalid device IDs', () {
        expect(BleDataValidator.isValidDeviceId(null), false);
        expect(BleDataValidator.isValidDeviceId(''), false);
        expect(BleDataValidator.isValidDeviceId('short'), false);
      });
    });

    group('UUID Validation', () {
      test('should accept short UUIDs', () {
        expect(BleDataValidator.isValidUuid('180F'), true);
        expect(BleDataValidator.isValidUuid('2A19'), true);
      });

      test('should accept full UUIDs', () {
        expect(BleDataValidator.isValidUuid('12345678-1234-1234-1234-123456789abc'), true);
      });

      test('should reject invalid UUIDs', () {
        expect(BleDataValidator.isValidUuid(null), false);
        expect(BleDataValidator.isValidUuid(''), false);
        expect(BleDataValidator.isValidUuid('ZZZZ'), false);
        expect(BleDataValidator.isValidUuid('123'), false);
      });
    });

    group('Characteristic ID Validation', () {
      test('should accept valid characteristic IDs', () {
        // Format: deviceId:serviceUuid:charUuid (3 parts)
        // Using UUID format for device ID to avoid : delimiter conflict
        expect(BleDataValidator.isValidCharacteristicId('12345678-1234-1234-1234-123456789abc:180F:2A19'), true);
      });

      test('should reject invalid characteristic IDs', () {
        expect(BleDataValidator.isValidCharacteristicId(null), false);
        expect(BleDataValidator.isValidCharacteristicId(''), false);
        expect(BleDataValidator.isValidCharacteristicId('invalid'), false);
        expect(BleDataValidator.isValidCharacteristicId('a:b'), false);
      });
    });

    group('Data Validation', () {
      test('should accept valid byte arrays', () {
        expect(BleDataValidator.isValidData([0, 1, 2, 255]), true);
        expect(BleDataValidator.isValidData([128]), true);
      });

      test('should reject invalid data', () {
        expect(BleDataValidator.isValidData(null), false);
        expect(BleDataValidator.isValidData([]), false);
        expect(BleDataValidator.isValidData([-1, 0, 1]), false);
        expect(BleDataValidator.isValidData([0, 256, 1]), false);
      });
    });

    group('Timeout Validation', () {
      test('should accept valid timeouts', () {
        expect(BleDataValidator.isValidTimeout(Duration(seconds: 1)), true);
        expect(BleDataValidator.isValidTimeout(Duration(seconds: 60)), true);
        expect(BleDataValidator.isValidTimeout(Duration(seconds: 300)), true);
      });

      test('should reject invalid timeouts', () {
        expect(BleDataValidator.isValidTimeout(null), false);
        expect(BleDataValidator.isValidTimeout(Duration(milliseconds: 500)), false);
        expect(BleDataValidator.isValidTimeout(Duration(seconds: 301)), false);
      });
    });

    test('should sanitize device names', () {
      expect(BleDataValidator.sanitizeDeviceName('KGiTON Scale'), 'KGiTON Scale');
      expect(BleDataValidator.sanitizeDeviceName('KGiTON\x00Scale'), 'KGiTONScale');
      expect(BleDataValidator.sanitizeDeviceName('  KGiTON  '), 'KGiTON');
    });
  });

  group('ChecksumCalculator', () {
    test('should calculate XOR checksum correctly', () {
      expect(ChecksumCalculator.calculateXor([1, 2, 3, 4]), 4);
      expect(ChecksumCalculator.calculateXor([255, 255]), 0);
      expect(ChecksumCalculator.calculateXor([0]), 0);
    });

    test('should calculate sum checksum correctly', () {
      expect(ChecksumCalculator.calculateSum([1, 2, 3, 4]), 10);
      expect(ChecksumCalculator.calculateSum([255, 1]), 0); // 256 % 256
      expect(ChecksumCalculator.calculateSum([100, 100, 100]), 44); // 300 % 256
    });

    test('should validate XOR checksum', () {
      final data = [1, 2, 3, 4];
      final withChecksum = ChecksumCalculator.addXorChecksum(data);
      expect(ChecksumCalculator.validateXor(withChecksum), true);

      final corrupted = [...withChecksum];
      corrupted[0] = 99;
      expect(ChecksumCalculator.validateXor(corrupted), false);
    });

    test('should validate sum checksum', () {
      final data = [10, 20, 30];
      final withChecksum = ChecksumCalculator.addSumChecksum(data);
      expect(ChecksumCalculator.validateSum(withChecksum), true);

      final corrupted = [...withChecksum];
      corrupted[1] = 99;
      expect(ChecksumCalculator.validateSum(corrupted), false);
    });
  });

  group('BleDataSanitizer', () {
    test('should enforce MTU limit', () {
      final largeData = List.filled(600, 1);
      final limited = BleDataSanitizer.ensureMtuLimit(largeData, maxMtu: 512);
      expect(limited.length, 512);
    });

    test('should remove null terminators', () {
      final data = [1, 2, 0, 3, 0, 4];
      final cleaned = BleDataSanitizer.removeNullTerminators(data);
      expect(cleaned, [1, 2, 3, 4]);
    });

    test('should pad data to length', () {
      final data = [1, 2, 3];
      final padded = BleDataSanitizer.padToLength(data, 5);
      expect(padded, [1, 2, 3, 0, 0]);

      final paddedCustom = BleDataSanitizer.padToLength(data, 5, paddingByte: 255);
      expect(paddedCustom, [1, 2, 3, 255, 255]);
    });

    test('should convert string to safe bytes', () {
      final bytes = BleDataSanitizer.stringToSafeBytes('Hello');
      expect(bytes, [72, 101, 108, 108, 111]);

      final limited = BleDataSanitizer.stringToSafeBytes('Hello World', maxLength: 5);
      expect(limited.length, 5);
    });

    test('should safely convert bytes to string', () {
      expect(BleDataSanitizer.safeBytesToString([72, 101, 108, 108, 111]), 'Hello');
      expect(BleDataSanitizer.safeBytesToString([72, 101, 0, 108, 108, 111]), 'Hello');
    });
  });
}
