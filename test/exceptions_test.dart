import 'package:flutter_test/flutter_test.dart';
import 'package:kgiton_ble_sdk/src/exceptions/ble_exceptions.dart';

void main() {
  group('BleException', () {
    test('should create exception with message', () {
      final exception = BleException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('should create exception with original error', () {
      final originalError = Exception('Original error');
      final exception = BleException('Test error', originalError: originalError);

      expect(exception.message, 'Test error');
      expect(exception.originalError, originalError);
    });

    test('should create exception with stack trace', () {
      final stackTrace = StackTrace.current;
      final exception = BleException('Test error', stackTrace: stackTrace);

      expect(exception.stackTrace, stackTrace);
    });

    test('should have correct string representation', () {
      final exception = BleException('Test error');
      expect(exception.toString(), 'BleException: Test error');
    });

    test('should include original error in string representation', () {
      final originalError = Exception('Original error');
      final exception = BleException('Test error', originalError: originalError);
      final str = exception.toString();

      expect(str, contains('Test error'));
      expect(str, contains('Original error'));
    });
  });

  group('BleScanException', () {
    test('should create scan exception', () {
      final exception = BleScanException('Scan failed');

      expect(exception.message, 'Scan failed');
      expect(exception, isA<BleException>());
    });

    test('should have correct string representation', () {
      final exception = BleScanException('Scan failed');
      expect(exception.toString(), 'BleScanException: Scan failed');
    });

    test('should include original error in string', () {
      final originalError = Exception('Bluetooth off');
      final exception = BleScanException('Scan failed', originalError: originalError);
      final str = exception.toString();

      expect(str, contains('Scan failed'));
      expect(str, contains('Bluetooth off'));
    });
  });

  group('BleConnectionException', () {
    test('should create connection exception', () {
      final exception = BleConnectionException('Connection failed');

      expect(exception.message, 'Connection failed');
      expect(exception.deviceId, isNull);
      expect(exception, isA<BleException>());
    });

    test('should create connection exception with device id', () {
      final exception = BleConnectionException('Connection failed', deviceId: 'device-123');

      expect(exception.deviceId, 'device-123');
    });

    test('should have correct string representation', () {
      final exception = BleConnectionException('Connection failed');
      expect(exception.toString(), 'BleConnectionException: Connection failed');
    });

    test('should include device id in string', () {
      final exception = BleConnectionException('Connection failed', deviceId: 'device-123');
      final str = exception.toString();

      expect(str, contains('Connection failed'));
      expect(str, contains('device-123'));
    });

    test('should include original error and device id in string', () {
      final originalError = Exception('Timeout');
      final exception = BleConnectionException('Connection failed', deviceId: 'device-123', originalError: originalError);
      final str = exception.toString();

      expect(str, contains('Connection failed'));
      expect(str, contains('device-123'));
      expect(str, contains('Timeout'));
    });
  });

  group('BleServiceDiscoveryException', () {
    test('should create service discovery exception', () {
      final exception = BleServiceDiscoveryException('Discovery failed', 'device-123');

      expect(exception.message, 'Discovery failed');
      expect(exception.deviceId, 'device-123');
      expect(exception, isA<BleException>());
    });

    test('should have correct string representation', () {
      final exception = BleServiceDiscoveryException('Discovery failed', 'device-123');
      final str = exception.toString();

      expect(str, contains('Discovery failed'));
      expect(str, contains('device-123'));
    });

    test('should include original error in string', () {
      final originalError = Exception('Timeout');
      final exception = BleServiceDiscoveryException('Discovery failed', 'device-123', originalError: originalError);
      final str = exception.toString();

      expect(str, contains('Discovery failed'));
      expect(str, contains('device-123'));
      expect(str, contains('Timeout'));
    });
  });

  group('BleCharacteristicException', () {
    test('should create characteristic exception', () {
      final exception = BleCharacteristicException('Read failed', 'read');

      expect(exception.message, 'Read failed');
      expect(exception.operation, 'read');
      expect(exception.characteristicId, isNull);
      expect(exception, isA<BleException>());
    });

    test('should create characteristic exception with id', () {
      final exception = BleCharacteristicException('Read failed', 'read', characteristicId: 'char-123');

      expect(exception.characteristicId, 'char-123');
    });

    test('should have correct string representation', () {
      final exception = BleCharacteristicException('Read failed', 'read');
      final str = exception.toString();

      expect(str, contains('Read failed'));
      expect(str, contains('read'));
    });

    test('should include characteristic id in string', () {
      final exception = BleCharacteristicException('Read failed', 'read', characteristicId: 'char-123');
      final str = exception.toString();

      expect(str, contains('char-123'));
    });

    test('should include all details in string', () {
      final originalError = Exception('Timeout');
      final exception = BleCharacteristicException('Read failed', 'read', characteristicId: 'char-123', originalError: originalError);
      final str = exception.toString();

      expect(str, contains('Read failed'));
      expect(str, contains('read'));
      expect(str, contains('char-123'));
      expect(str, contains('Timeout'));
    });
  });

  group('BleTimeoutException', () {
    test('should create timeout exception', () {
      final exception = BleTimeoutException('connect', Duration(seconds: 10));

      expect(exception.operation, 'connect');
      expect(exception.timeout, Duration(seconds: 10));
      expect(exception.message, 'Operation timed out after 10s');
      expect(exception, isA<BleException>());
    });

    test('should have correct string representation', () {
      final exception = BleTimeoutException('connect', Duration(seconds: 5));
      final str = exception.toString();

      expect(str, contains('connect'));
      expect(str, contains('5s'));
    });

    test('should create timeout with original error', () {
      final originalError = Exception('Connection lost');
      final exception = BleTimeoutException('write', Duration(seconds: 3), originalError: originalError);

      expect(exception.originalError, originalError);
    });
  });

  group('BleNotAvailableException', () {
    test('should create not available exception', () {
      final exception = BleNotAvailableException('Bluetooth disabled');

      expect(exception.message, 'Bluetooth disabled');
      expect(exception, isA<BleException>());
    });

    test('should have correct string representation', () {
      final exception = BleNotAvailableException('Bluetooth disabled');
      expect(exception.toString(), 'BleNotAvailableException: Bluetooth disabled');
    });

    test('should create exception with original error', () {
      final originalError = Exception('Platform error');
      final exception = BleNotAvailableException('Bluetooth disabled', originalError: originalError);

      expect(exception.originalError, originalError);
    });
  });
}
